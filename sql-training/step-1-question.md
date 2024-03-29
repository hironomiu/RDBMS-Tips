# SQL 実力アップセミナー

このセミナーは「リレーショナルデータベースの必須技術「正規化」を学ぼう」で学んだテーブル定義を用いて SQL の実践的な書き方を学びます。「リレーショナルデータベースの必須技術「正規化」を学ぼう」を視聴している方がテーブル定義の背景などを理解して臨めますのでベストですが視聴していなくても問題なく SQL 文の勉強ができるセミナーになっています。

## 学習対象

SQL 初心者から中級者

### 初心者の定義

単一テーブルに対して SELECT 文が書ける、条件句で絞り込みができる。UPDATE、INSERT、DELETE 文が書ける、条件句で絞り込みができる。

### 中級者の定義

複数テーブルを結合して SELECT 文が書ける。同じ結果となる SQL 文を複数書き分けることができる。

### 上級者の定義

SQL 文をパフォーマンス視点で最適な SQL 文を導き出せる

## 対象データベース

このセミナーでは MySQL をベースに SQL 文について解説しています。

## 進め方

このセミナーはライブコーディング形式で進めます。セミナー中は自身で SQL を書く時間はありませんので事前に回答を元に SQL を書いてみるか、ライブコーディング後に書いてみることをおすすめします。

[Step1 回答](./step-1-answer.md)

[Step2 回答](./step-2-answer.md)

## 事前準備

MySQL が動作し、SQL が発行できる環境(ライブコーディングの視聴のみでも学べる構成にしてありますが実際に自分で SQL を書く方が学びが多いため推奨)

[参考：Docker 用の MySQL 環境レシピ](https://github.com/hironomiu/Docker-DockerCompose-Training/blob/main/recipe-mysql-dockerfile/README.md)

## 概要

<img width="988" alt="今回のサンプル概要" src="https://user-images.githubusercontent.com/1575057/58690623-852b4e00-8379-11e9-886f-0b21886c6c0e.png">

## テーブル定義

概要に基づいて制約など盛り込んだテーブル定義が以下です。以下の CREATE TABLE 文を任意の MySQL DATABASE で実行し作成しましょう。([参考：Docker 用の MySQL 環境レシピ](https://github.com/hironomiu/Docker-DockerCompose-Training/blob/main/recipe-mysql-dockerfile/README.md)の場合なら`test`に作成)

```
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
address VARCHAR(100),
created_at DATETIME NOT NULL,
updated_at DATETIME NOT NULL,
PRIMARY KEY(id)
);

CREATE TABLE items (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
price INT UNSIGNED NOT NULL,
created_at DATETIME NOT NULL,
updated_at DATETIME NOT NULL,
PRIMARY KEY(id)
);

CREATE TABLE orders (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
order_date DATE NOT NULL,
customer_id INT UNSIGNED NOT NULL,
created_at DATETIME NOT NULL,
updated_at DATETIME NOT NULL,
PRIMARY KEY(id),
FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE order_details (
order_id INT UNSIGNED NOT NULL,
item_id INT UNSIGNED NOT NULL,
item_quantity INT UNSIGNED NOT NULL,
created_at DATETIME NOT NULL,
updated_at DATETIME NOT NULL,
PRIMARY KEY(order_id,item_id),
FOREIGN KEY (order_id) REFERENCES orders(id),
FOREIGN KEY (item_id) REFERENCES items(id)
);
```

### Q0 テーブルの削除順序、作成順序
上のDDLのテーブルの削除順序、作成順序はなぜこの順序か考えてみましょう

## サンプルデータ

```
insert into customers(id,name,address,created_at,updated_at) values(1,'A商事','東京都',now(),now()),(2,'B商会','埼玉県',now(),now()),(3,'C商店','神奈川県',now(),now());

insert into items(id,name,price,created_at,updated_at) values(1,'シャツ',1000,now(),now()),(2,'パンツ',950,now(),now()),(3,'マフラー',1200,now(),now()),(4,'ブルゾン',1800,now(),now());

insert into orders(id,order_date,customer_id,created_at,updated_at) values(1 , '2013-10-01',1,now(),now()),(2 , '2013-10-01',2,now(),now()),(3 , '2013-10-02',2,now(),now()),(4 , '2013-10-02',3,now(),now());

insert into order_details(order_id,item_id,item_quantity,created_at,updated_at) values(1 , 1 ,3,now(),now()),(1 , 2 ,2,now(),now()),(2 , 1 ,1,now(),now()),(2 , 3 ,10,now(),now()),(2 , 4 ,5,now(),now()),(3 , 2 ,80,now(),now()),(4 , 3 ,25,now(),now());
```

## Step1 Question

### Q0 テーブル確認をしましょう

抽出結果

```
+----------------+
| Tables_in_test |
+----------------+
| customers      |
| items          |
| order_details  |
| orders         |
+----------------+
4 rows in set (0.00 sec)

+----+---------+--------------+---------------------+---------------------+
| id | name    | address      | created_at          | updated_at          |
+----+---------+--------------+---------------------+---------------------+
|  1 | A商事   | 東京都       | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  2 | B商会   | 埼玉県       | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  3 | C商店   | 神奈川県     | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
+----+---------+--------------+---------------------+---------------------+
3 rows in set (0.00 sec)

+----+--------------+-------+---------------------+---------------------+
| id | name         | price | created_at          | updated_at          |
+----+--------------+-------+---------------------+---------------------+
|  1 | シャツ       |  1000 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  2 | パンツ       |   950 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  3 | マフラー     |  1200 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  4 | ブルゾン     |  1800 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
+----+--------------+-------+---------------------+---------------------+
4 rows in set (0.00 sec)

+----------+---------+---------------+---------------------+---------------------+
| order_id | item_id | item_quantity | created_at          | updated_at          |
+----------+---------+---------------+---------------------+---------------------+
|        1 |       1 |             3 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        1 |       2 |             2 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        2 |       1 |             1 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        2 |       3 |            10 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        2 |       4 |             5 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        3 |       2 |            80 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|        4 |       3 |            25 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
+----------+---------+---------------+---------------------+---------------------+
7 rows in set (0.00 sec)

+----+------------+-------------+---------------------+---------------------+
| id | order_date | customer_id | created_at          | updated_at          |
+----+------------+-------------+---------------------+---------------------+
|  1 | 2013-10-01 |           1 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  2 | 2013-10-01 |           2 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  3 | 2013-10-02 |           2 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
|  4 | 2013-10-02 |           3 | 2020-04-14 08:30:09 | 2020-04-14 08:30:09 |
+----+------------+-------------+---------------------+---------------------+
4 rows in set (0.00 sec)
```

### Q1 商品シャツの売り上げ合計金額を算出しましょう

抽出結果

```
+----------+
| proceeds |
+----------+
|     4000 |
+----------+
1 row in set (0.01 sec)
```

### Q1 解答後補足問題

結合順序を変えてみましょう

### Q2 商品をでランダムに 1 行求めましょう

抽出結果(ランダムに抽出するため同じになるとは限りません)

```
+----+-----------+-------+---------------------+------------+
| id | name      | price | created_at          | updated_at |
+----+-----------+-------+---------------------+------------+
|  2 | パンツ    |   950 | 2017-09-08 16:47:09 | NULL       |
+----+-----------+-------+---------------------+------------+
1 row in set (0.00 sec)
```

### Q2 解答後補足問題１

ランダム抽出の内部の動作について調べましょう。調査を踏まえ注意すべき点などないかなど考えてみましょう

### Q2 解答後補足問題２

SELECT 文での「`＊`(アスタリスク」についてどのようなケースで利用して良いか考えてみましょう

### Q3 商品「シャツ」「パンツ」を受注した受注 id を求めましょう。受注 id は新しい(大きい)順に並べましょう

抽出結果

```
+----------+
| order_id |
+----------+
|        3 |
|        2 |
|        1 |
+----------+
3 rows in set (0.00 sec)
```

### Q3 解答後補足問題 1

Q3 の SQL 文を union 句を用いて同じ結果になる SELECT 文を構築しましょう  
抽出結果

```
+----------+
| order_id |
+----------+
|        3 |
|        2 |
|        1 |
+----------+
3 rows in set (0.00 sec)
```

### Q3 解答後補足問題 2

Q3 の SQL 文を group by 句を用いて同じ結果になる SELECT 文を構築しましょう  
抽出結果

```
+----------+
| order_id |
+----------+
|        3 |
|        2 |
|        1 |
+----------+
3 rows in set (0.00 sec)
```

### Q4 受注全体から受注金額の平均を算出しましょう

抽出結果

```
+-----------------+
| avg_order_price |
+-----------------+
|      33225.0000 |
+-----------------+
1 row in set (0.00 sec)
```

### Q4 解答後補足問題

受注の件数も一緒に取得しましょう

抽出結果

```
+-----------------+-------------+
| avg_order_price | order_count |
+-----------------+-------------+
|      33225.0000 |           4 |
+-----------------+-------------+
1 row in set (0.00 sec)
```

### Q5 受注金額が一番大きい受注の受注 id と受注金額を求めましょう

抽出結果

```
+----+-------------+
| id | order_price |
+----+-------------+
|  3 |       76000 |
+----+-------------+
1 row in set (0.00 sec)
```

### Q5 解答後補足問題

今回の回答が正しいか考えてみましょう
