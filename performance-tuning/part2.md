# RDBMS パフォーマンスチューニング入門 Part2

## 準備

実演を手元で動かしたい場合は[part0](./part0.md)を行うこと

## 今回利用するテーブル

```
mysql> show create table users;

CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `birthday` datetime NOT NULL,
  `profile1` text,
  `profile2` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000008 DEFAULT CHARSET=utf8mb3

```

件数

```
mysql> select count(*) from users;
+----------+
| count(*) |
+----------+
|  1000006 |
+----------+
1 row in set (12.39 sec)

```

## SQL テクニック&Tips

### Nested Loop Join の理解

### Multi Column Index

Multi Column Index(複数カラムで構成する INDEX)のカラムの列挙順について

例１

```
select * from users where birthday = "1988-04-23 00:00:00" and name = "o3xE22lXIlWJCdd";
```

実際に検索

```
mysql> select * from users where birthday = "1988-04-23 00:00:00" and name = "o3xE22lXIlWJCdd";

...

1 row in set (18.53 sec)
```

explain で実行計画の確認

```
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
         rows: 703878
     filtered: 1.00
        Extra: Using where
1 row in set, 1 warning (0.02 sec)

```

データ分布

```
mysql> select birthday , count(*) from users group by birthday;
+---------------------+----------+
| birthday            | count(*) |
+---------------------+----------+
| 1993-11-26 00:00:00 |       37 |
| 1968-08-14 00:00:00 |       43 |
| 1986-08-26 00:00:00 |       53 |
| 1957-06-07 00:00:00 |       43 |

.....

| 1944-09-30 00:00:00 |       24 |
| 1952-05-07 00:00:00 |       38 |
+---------------------+----------+
23726 rows in set (14.44 sec)

```

```
mysql> select count(*) from users where birthday = "1988-04-23 00:00:00";
+----------+
| count(*) |
+----------+
|       51 |
+----------+
1 row in set (11.68 sec)
```

```
mysql> select count(*) from users where name = "o3xE22lXIlWJCdd";
+----------+
| count(*) |
+----------+
|        1 |
+----------+
1 row in set (12.53 sec)
```

INDEX は絞り込みが効くカラムから指定し（今回だと name からが良さそう）作成

```
alter table users add index name_birthday(name,birthday);
```

実行計画の確認

```
mysql> explain select * from users where birthday = "1988-04-23 00:00:00" and name = "o3xE22lXIlWJCdd"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ref
possible_keys: name_birthday
          key: name_birthday
      key_len: 157
          ref: const,const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.01 sec)
```

実際に検索

```
mysql> select * from users where birthday = "1988-04-23 00:00:00" and name = "o3xE22lXIlWJCdd";

...

1 row in set (0.00 sec)
```

### カバリングインデックス

`Multi Column Index`の派生。INDEX で SELECT 句、条件句などをカバーしレコードまで探索をしないことでパフォーマンス向上を狙う

例

この場合だと name,email の 2 カラムだけで探索を完了できる

```

mysql> select name from users where email = "POCqOOm8flPwKGm@example.com";
+-----------------+
| name |
+-----------------+
| POCqOOm8flPwKGm |
+-----------------+
1 row in set (11.60 sec)

```

カバリングインデックスではない対応

```
mysql> alter table users add index email(email);
```

explain と検索結果(時間に注目)

```
mysql> explain select name from users where email = "POCqOOm8flPwKGm@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ref
possible_keys: email
          key: email
      key_len: 302
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.01 sec)

mysql> select name from users where email = "POCqOOm8flPwKGm@example.com";
+-----------------+
| name            |
+-----------------+
| POCqOOm8flPwKGm |
+-----------------+
1 row in set (0.01 sec)
```

検証のため作った INDEX を削除

```
mysql> alter table users drop index email;
```

カバリングインデックス

```
mysql> alter table users add index email_name(email,name);
```

explain と検索結果(時間に注目)

```
mysql> explain select name from users where email = "POCqOOm8flPwKGm@example.com"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: users
   partitions: NULL
         type: ref
possible_keys: email_name
          key: email_name
      key_len: 302
          ref: const
         rows: 1
     filtered: 100.00
        Extra: Using index
1 row in set, 1 warning (0.00 sec)

mysql> select name from users where email = "POCqOOm8flPwKGm@example.com";
+-----------------+
| name            |
+-----------------+
| POCqOOm8flPwKGm |
+-----------------+
1 row in set (0.00 sec)
```

### INDEX Sort

B+tree インデックスはソートされ格納されている特徴を利用したチューニング手法

---

```
mysql> select count(*) from users where birthday >=  "1988-04-23 00:00:00" and birthday < "2000-01-01 00:00:00";
+----------+
| count(*) |
+----------+
|   177194 |
+----------+
1 row in set (12.00 sec)
```

- union による複数 INDEX

- ヒント句

## Insert 時のボトルネック

- PK の衝突

## レプリケーション

![replication](./images/replication.png)

## パーティショニング

![parition](./images/partition.png)

## シャーディング

![sharding](./images/sharding.png)

```

```
