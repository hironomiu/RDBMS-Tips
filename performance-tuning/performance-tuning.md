# RDBMSパフォーマンスチューニング入門 Part1

## 広義のパフォーマンスチューニングとは
- 確保したリソース(CPU、メモリ、Disk、NWなど)でシステムを安定稼働させる、期待する時間で処理を行うための改善活動

- 改善活動を行うためにどのように稼働、処理を確認するか？
  - 監視により各種メトリクス、ミドルウェアの実行状況、サービスレベルでの死活監視など
    - 今回はミドルウェアの実行状況の文脈からSQLの実行状況をモニタリングする「スローログ」に触れます

## (今回のお題の)RDBMSパフォーマンスチューニングとは
大きくわけると2つのチューニングがあります

- SQLチューニング  
  - SQL文を意図した実行計画(アクセスパス)になるようSQL文の修正や誘導(ヒント句 インデックスの指定、駆動表の指定、探索アルゴリズムの指定など)、`または`インデックスを貼り走査のパフォーマンスチューニング(性能改善、性能最適)をはかるアプローチ
    - `または`と記載したがこれは`or`の関係ではなくどちらも用いることが多く`and`の関係
    - **今回はここを中心に入門します**

- システムチューニング  
  - RDBMSのパラメータ(メモリ(共有、セッション固有など)、ファイルパス、何かしらの上限値(セッション数、プロセス数、スレッド数など)、アルゴリズム(LRUなど)、その他)、下位レイヤのパラメータ(カーネルパラメータ(ファイルディスクリプタ、I/Oスケジューラ、その他)、など)、ハードウェアの追加(CPU、メモリなど)や上位機種に変更などでパフォーマンスチューニング(性能改善、性能最適)をはかるアプローチ

- なぜ改善だけではなく最適と言う言葉を使ったか
  - SQL文をチューニングしたとしても実際には様々な処理が同時実行されているなかで動作するため適切(最適)なリソースを用いて動作することが結果として重要になる。
    - Bad チューニングしたSQL文のせいで他のSQL文が遅くなる

## 頭の片隅においておく観点
今回のパフォーマンスチューニングにて頭の片隅に置いておく観点

- レスポンスタイム  
  - 入力が与えてから、反応を送り返すまでにかかるの時間のこと
    - OLTP(オンライン処理)、ユニークなデータを取り出す処理向き
      - INDEXを用いた探索
    - 今回の話はここを意識する話が中心です

- スループット  
  - 単位時間あたりに処理できる量のこと
    - バッチ処理向きな観点

- I/Oバウンド  
  - 高ワークロード時に「DiskI/O」が性能の頭打ちになるケース
    - RDBMSはI/Oバウンドに陥りやすい
       - 今回の話はここを意識する話となります

- CPUバウンド  
  - 高ワークロード時に「CPU」が性能の頭打ちになるケース
    - Webサーバ、アプリケーションサーバなどはCPUバウンドに陥りやすい

- キャッシュヒット率
  - データをメモリからアクセスするコストを1、ストレージからアクセスするコストを100と想定し、メモリにデータが存在しない場合ストレージにアクセスし得るものとする
    - ヒット率100%の場合のコストは？ -> 100
    - ヒット率99%の場合のコストは？ -> 99 + 100 -> 199
    - 必要なデータがメモリにあるのが好ましいイメージを持つ
      - ここで指すメモリとは？
        - RDBMSのバッファキャッシュ機能を指す。MySQLでは`innodb_buffer_pool_size`など。メタな言葉で`共有メモリ`と呼ぶこともある

- 計算量
  - 線形探索 最良`0(1)`、最悪`O(N)`、平均`O(N/2)`
    - テーブルのフルスキャンは`O(N)`に近い
      - 計算量は1件のデータを突き止めるがフルスキャンはN件のデータからM件突き止めるので厳密には違う
        - N=Mの検索結果を返すこともある
  - 二分木 `O(log2N)`
    - 今回学ぶB+treeのベース

## MySQLアーキテクチャ
主に認証、認証後のクライアントからのSQLの要求、サーバ側の受け付け、レスポンスまでの基本的な動作について

![arc](./images/arc.png)

今回主にチューニングで行う箇所は④ ~ ⑧での箇所で実行されるSQLについてです。

- オプティマイザ
  - ④ ~ ⑧ではオプティマイザと呼ばれる存在がSQL文を解析後、最適なデータ走査方法の策定 = 実行計画の策定を行います。この実行計画を元にデータ走査が行われ⑧で結果(SELECTなら結果セットと実行結果、その他は実行結果)が返されます。
    - 今回の`最適`はレスポンスタイムが早くなることを前提に進めます


## 実演  
これからする一連の流れを一旦実演

- スローログの設定確認
```
vi /etc/my.cnf
```

- スローログの出力内容を`tail`で確認
```
tail -f /var/log/mysql/slow.log
```

- テーブル構成
```
show create table users;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `mail` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `sex` int(11) NOT NULL,
  `birthday` datetime NOT NULL,
  `profile1` text,
  `profile2` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1000008 DEFAULT CHARSET=utf8 |

1 row in set (0.01 sec)
```

- レコード数の確認
```
select count(*) from users;
```

- 今回チューニングするSQLの実行
```
select name from users where mail = "o3xE22lXIlWJCdd@example.com";
```

- スローログの出力内容を確認
  - 2件出力されていること

- explainの実行
```
explain select name from users where mail = "o3xE22lXIlWJCdd@example.com"\G
```

以降のチューニングはスローログ、Explainの章を学び再度実演にて解決します

## スローログ
RDBMS(MySQL)の性能改善に向けたロギング戦略、日々ロギングし性能改善の材料とする。スローログが起点となるケースもあるが、他のメトリクスで閾値を超えた時を起点として、その時刻前後にスローログにロギングされたSQLを確認することなどが多い

- スローログの設定方法  
  - 出力可否、出力先(ファイルパス)、閾値(秒)の設定

```
/etc/my.cnf

[mysqld]
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=0.1
```

- 出力例  
ターミナル1

```
$ tail -f /var/log/mysql/slow.log
```

- 出力例  
ターミナル2

```
mysql> show create table users;
mysql> select count(*) from users;
mysql> select name from users where mail = "o3xE22lXIlWJCdd@example.com";
```

- 出力例  
  - ターミナル1の出力結果より`# Query_time: 26.215280 `、`Rows_sent: 1  Rows_examined: 1000006`から実行時間約26秒、返したレコード1件、読み込んだレコード1000006件
    - `読み込んだレコード1000006件`を返したレコードに近づければ`# Query_time: 26.215280 `が縮小できると考える
```
# Time: 2020-07-03T02:25:07.797968Z
# User@Host: admin[admin] @ localhost []  Id:   260
# Query_time: 26.215280  Lock_time: 0.000258 Rows_sent: 1  Rows_examined: 1000006
SET timestamp=1593743081;
select name from users where mail = "o3xE22lXIlWJCdd@example.com";
```

## Explain
ExplainはSQL文の実行計画計画に関する情報を出力します。この出力結果から、ここでは基本的な実行計画の改善戦略について学んでいきます

- Explaine出力例
```
mysql> explain select name from users where mail = "o3xE22lXIlWJCdd@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 717622
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.03 sec)
```

- この出力結果からは、usersテーブルから`table: users`、候補となるINDEX`possible_keys: NULL`が存在せず、実際に適用されたINDEXもなく`key: NULL`、717622件のレコードを走査`rows: 717622`したことがわかります
  - 注意 `rows: 717622`は統計値で実際には1000006レコード
  - スローログの章同様に返すレコードに`rows: 717622`を近づけることを考える

## B+tree INDEX アーキテクチャ
RDBMSではテーブル探索の機能としてB+tree(B*tree)INDEXは(ほぼ)必ず実装されています。INDEXはRDBMSでのテーブル探索を行う上で、とても重要な機能です。

- どのように重要か？
  - 探索の際に`O(N)` -> `O(logFN*log2F)`に計算量を落とす
    - 大量のデータから少量のデータを探索する場合に有効
    - スローログ、Explainで解決したい課題`返すレコード`と`読み込むレコード`を近づけることができる

B+treeINDEX図

![B+tree](./images/btree.png)

B+treeINDEXの構造は簡単にあらわすと、このような図になります。二分木と違い、ブロックデバイスを前提に、格納効率の最大化を行い、探索時の計算量は`O(logFN*log2F)`となります。

- (注意)MySQLのPKはClusteredINDEXのためleafにRow(行)も格納される

- Unique、Non Uniqueの違いNext Look Up)
  - この図で示したB+treeINDEXではUnique探索、Non Unique探索のどちらも実現できます
    - Uniqueでは対象にヒットしたら次をlook upしません
    - Non Uniqueでは対象にヒットしたあとも次をlook upします。look up時に値が違う場合、そこでlook upを終了します

図中ではINDEXから探索しデータにアクセス(ルックアップ)されるるまでに5ページ(ブロック)のアクセスで実現されています。

例として、テーブルレコードが100万件、テーブル容量が1Gbyteのテーブルがあるとします。  
全レコードから特定の1件のレコードを要求した場合、計算量はO(n)になります。  
この場合100万件中の1(もしくはn)件のデータを突き止めるために1Gbyteの容量全てを走査して導き出します。  
これはいわゆるFull Scanの状態です。これをb+treeINDEXでこのテーブルを探索した場合、root,branch,leafを探索しleafから紐づくデータのアクセスで完了します。図中では5ページ(ブロック)のアクセスで導き出せています。この場合、root,branch,leaf,データ部のページサイズを8Kbyteとした場合、40Kbyteのアクセスで探索が完了します。

この例で、100万レコードから1件(もしくはn件)のデータが導きだされるケースでFull ScanとINDEX探索では`1Gbyte対40byte`のデータ容量の走査の差が性能差となって現れます。

- SQLでどのカラムをINDEXとして貼るべきか？
  - 今回のスローログで見つかったSQLならば`Where句`で指定されたカラムに設定するのが良い

## SQLパフォーマンスチューニング実演
ここからはFullScanのSQL(select文)をexplainで確認し確認する勘所、確認後の対策としてB+treeINDEXを貼り、explainの内容の違い、検索時間の違いを見ていきます

- 確認 テーブルサイズ
  - ディクショナリを用いた算出方法もあるが今回はFS上のファイルサイズで確認する

```
# ll /var/lib/mysql/1day/users.ibd
-rw-r----- 1 mysql mysql 4261412864  7月  3 16:34 /var/lib/mysql/1day/users.ibd
```

- 確認 テーブル構成
```
mysql> show create table users;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `mail` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `sex` int(11) NOT NULL,
  `birthday` datetime NOT NULL,
  `profile1` text,
  `profile2` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1000008 DEFAULT CHARSET=utf8 |

1 row in set (0.01 sec)
```

- 問題のSQLを実行
  - `1 row in set (23.51 sec)`に注目
```
mysql> select name from users where mail = "o3xE22lXIlWJCdd@example.com";
+-----------------+
| name            |
+-----------------+
| o3xE22lXIlWJCdd |
+-----------------+
1 row in set (23.51 sec)
```

- explain`rows`に注目しましょう(`rows: 717622`)

```
mysql> explain select name from users where mail = "o3xE22lXIlWJCdd@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 717622
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.03 sec)
```

- INDEXの作成
  - 今回の話とはずれるがINDEXの作成時間は覚えておくことは大事
    - `Query OK, 0 rows affected (31.76 sec)`
```
mysql> alter table users add index mail(`mail`);
Query OK, 0 rows affected (31.76 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

- 注意　今回mailにINDEXを貼ったがUnique、Non Uniqueについては検討していない
  - Unique INDEXの場合は以下

```
mysql> alter table users add unique index mail(`mail`);
Query OK, 0 rows affected (31.78 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

- explain`rows`に注目しましょう(`rows: 1`)
```
mysql> explain select name from users where mail = "o3xE22lXIlWJCdd@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ref
possible_keys: mail
          key: mail
      key_len: 302
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.01 sec)
```

- Extraの違いに注目
  - 古いVersionだと`Using index,Using where`だったこともあり
    - カバリングインデックスなどと呼ばれる
    - これを応用すると今回のINDEXは`mail`のみで良いか？
      - ケースバイケースで`mail,name`が良い場合もある
```
mysql> explain select mail from users where mail = "o3xE22lXIlWJCdd@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ref
possible_keys: mail
          key: mail
      key_len: 302
          ref: const
         rows: 1
     filtered: 100.00
        Extra: Using index
1 row in set, 1 warning (0.00 sec)
```

- 問題のSQLを実行し実行時間から改善したことを確認
  - 1 row in set (0.00 sec)
```
mysql> select name from users where mail = "o3xE22lXIlWJCdd@example.com";
+-----------------+
| name            |
+-----------------+
| o3xE22lXIlWJCdd |
+-----------------+
1 row in set (0.00 sec)
```

- I/Oが717622から1に減少(実際には1000006から1)
  - ページの走査も全ページからINDEX(root,branch,leafの3~4ページ) + レコードのページの4~5ページになった
    - 4261412864byte=4Gbyteから8kbyte * 4~5=32k~40kbyte
```
mysql> select count(*) from users;
+----------+
| count(*) |
+----------+
|  1000006 |
+----------+
1 row in set (26.05 sec)
```

## 余談
今回のSQLチューニングはINDEXを用いることで、以下を達成しレスポンスタイムを上げることができました

- 計算量を減らす
- 実際に走査するレコードを減らす
- 走査する容量を減らす

冒頭で`最適`と言う言葉に触れましたが`走査する容量を減らす`と言うのは共有メモリを最適な利用に近づけることに寄与していることに注目できるとSQLチューニングとシステムチューニングを相互に俯瞰できRDBMSチューニングの精度が上がっていきます。

# RDBMSパフォーマンスチューニング入門 Part2

## Selet文
- Nested Loop Joinの理解

## INDEX テクニック&Tips

- 複数カラムのINDEX作成時の列挙順

- INDEX Sort

- カバリングインデックス

- unionによる複数INDEX

## Insert時のボトルネック
PKの衝突

## レプリケーション
![replication](./images/replication.png)

## パーティショニング
![parition](./images/partition.png)

## シャーディング
![sharding](./images/sharding.png)

