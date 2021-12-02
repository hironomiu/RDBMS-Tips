# SQL 実力アップセミナー(Step2 回答)

## Answer

### A6

[MySQL Bulk Data Loading](https://dev.mysql.com/doc/refman/8.0/en/optimizing-innodb-bulk-data-loading.html)
```
insert into items values
 (null,"タンクトップ",1300,now(),now()),
 (null,"ジャンパー",2500,now(),now()),
 (null,"ソックス",600,now(),now());
```

参考(DEFAULT CURRENT_TIMESTAMP の例)

```
CREATE TABLE `items2` (
`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
`name` varchar(100) NOT NULL,
`price` int(10) unsigned NOT NULL,
`created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (`id`)
);

insert into items2(name,price) values
("タンクトップ",1300),
("ジャンパー",2500),
("ソックス",600);
```

問い合わせ結果

```
mysql> select * from items2;
+----+--------------------+-------+---------------------+---------------------+
| id | name               | price | created_at          | updated_at          |
+----+--------------------+-------+---------------------+---------------------+
|  1 | タンクトップ       |  1300 | 2020-05-06 01:31:30 | 2020-05-06 01:31:30 |
|  2 | ジャンパー         |  2500 | 2020-05-06 01:31:30 | 2020-05-06 01:31:30 |
|  3 | ソックス           |   600 | 2020-05-06 01:31:30 | 2020-05-06 01:31:30 |
+----+--------------------+-------+---------------------+---------------------+
3 rows in set (0.00 sec)
```

### A6 解答後補足問題

今回の回答に至った insert 文のメリットを考えてみましょう

通常の insert 文の場合 1 レコード insert するたびに client から mysqld が作成したスレッドに要求がされるためレコード数分 insert 文が発行されるがこの insert では 1 回の insert 文で複数行の挿入が行える。

### A6 解答後補足問題

時刻カラムの設定をDB側(`now()` or `DEFAULT CURRENT_TIMESTAMP`)に任せるメリットを考えてみましょう

アプリケーション側で時刻を設定した場合、複数のアプリケーションサーバで運営していた場合、サーバ間でのがズレが生じる可能性がある。

`now()` or `DEFAULT CURRENT_TIMESTAMP`はSQL文（ステートメント）単位で発効される


### A7

```
select sum(d.price * c.item_quantity) as sum_price from customers a
inner join orders b on a.id = b.customer_id and name = "B商会"
inner join order_details c on b.id = c.order_id
inner join items d on d.id = c.item_id;
```

```
select sum(order_details.item_quantity * items.price) as sum_price from orders
inner join order_details on orders.id = order_details.order_id
inner join items on order_details.item_id = items.id
inner join customers on customers.id = orders.customer_id  where customers.name = "B商会";
```

### A8

#### 駆動票 items

exists

```
select a.id,a.name from items a where exists (select * from order_details b where a.id = b.item_id);
```

inner join(group by)

```
select a.id,a.name from items a inner join order_details b on a.id = b.item_id group by a.id ,a.name;
```

inner join(distinct)

```
select distinct a.id,a.name from items a inner join order_details b on a.id = b.item_id;
```

in

```
select a.id,a.name from items a where a.id in ( select b.item_id from order_details b );
```

#### 駆動表 order_details

exists

```
select distinct(item_id),(select name from items where items.id = item_id) as name from order_details
where exists(select * from items where item_id = items.id);
```

inner join(distinct)

```
select distinct(item_id),items.name from order_details inner join items on item_id = items.id;
```

inner join(group by)

```
select a.item_id,b.name from order_details a inner join items b on a.item_id = b.id group by a.item_id,b.name;
```

in

```
select distinct(item_id),(select name from items
where items.id = item_id) as name from order_details
where item_id in (select id from items);
```

### A9

#### 駆動票 items

not exists

```
select a.id ,a.name from items a where not exists (select * from order_details b where a.id = b.item_id);
```

left join

```
select a.id ,a.name from items a left outer join order_details b on a.id = b.item_id where b.order_id is null;
```

not in

```
select a.id ,a.name from items a where a.id not in (select b.item_id from order_details b);
```

#### 駆動票 order_details

例 outer join にて order_details からは満たせない

```
mysql> select a.item_id ,(select name from items where id = a.item_id) from order_details a right outer join items b on a.item_id = b.id;
+---------+-----------------------------------------------+
| item_id | (select name from items where id = a.item_id) |
+---------+-----------------------------------------------+
|       1 | シャツ                                        |
|       1 | シャツ                                        |
|       2 | パンツ                                        |
|       2 | パンツ                                        |
|       3 | マフラー                                      |
|       3 | マフラー                                      |
|       4 | ブルゾン                                      |
|    NULL | NULL                                          |
|    NULL | NULL                                          |
|    NULL | NULL                                          |
+---------+-----------------------------------------------+
10 rows in set (0.00 sec)

mysql> select a.item_id ,(select name from items where id = a.item_id) from order_details a left outer join items b on a.item_id = b.id;
+---------+-----------------------------------------------+
| item_id | (select name from items where id = a.item_id) |
+---------+-----------------------------------------------+
|       1 | シャツ                                        |
|       1 | シャツ                                        |
|       2 | パンツ                                        |
|       2 | パンツ                                        |
|       3 | マフラー                                      |
|       3 | マフラー                                      |
|       4 | ブルゾン                                      |
+---------+-----------------------------------------------+
7 rows in set (0.00 sec)
```

例 outer join にて order_details からは満たせる(上との違いを確認してみましょう)

```
mysql> select b.id ,(select name from items where id = b.id) from order_details a right outer join items b on a.item_id = b.id where a.order_id is null;
+----+------------------------------------------+
| id | (select name from items where id = b.id) |
+----+------------------------------------------+
|  5 | タンクトップ                             |
|  6 | ジャンパー                               |
|  7 | ソックス                                 |
+----+------------------------------------------+
3 rows in set (0.00 sec)
```

### A10

[MySQL CASEステートメント](https://dev.mysql.com/doc/refman/8.0/en/case.html)

```
select count(*) as "all_order",
 sum(case when item_id = 1 then 1 else 0 end) as "1",
 sum(case when item_id = 2 then 1 else 0 end) as "2",
 sum(case when item_id = 3 then 1 else 0 end) as "3",
 sum(case when item_id = 4 then 1 else 0 end) as "4",
 sum(case when item_id = 5 then 1 else 0 end) as "5",
 sum(case when item_id = 6 then 1 else 0 end) as "6",
 sum(case when item_id = 6 then 1 else 0 end) as "7"
 from order_details;
```

### A11

```
select b.id , count(a.item_id) count
from order_details a right outer join items b on a.item_id = b.id  group by b.id;
```

`count(item_id) count`にしている理由を考えてみましょう

### A12

```
select "all_order" ,count(*) as count from order_details
union
select b.id , count(a.item_id) count
from order_details a right outer join items b on a.item_id = b.id  group by b.id;
```

### A13

[MySQL GROUP_CONCAT](https://dev.mysql.com/doc/refman/8.0/en/aggregate-functions.html#function_group-concat)
```
select b.id , group_concat(a.order_id) order_id from order_details a right outer join items b on a.item_id = b.id  group by b.id;
```

### A13 解答後補足問題

`group_concat(a.order_id) as order`の`order`が予約語なため

```
mysql> select b.id ,group_concat(a.order_id) as order from order_details a right outer join items b on a.item_id = b.id group by b.id;
```

元の回答のように`order_id`など予約語以外にするとエラーとならない

```
mysql> select b.id ,group_concat(a.order_id) as order_id from order_details a right outer join items b on a.item_id = b.id group by b.id;
+----+----------+
| id | order_id |
+----+----------+
|  1 | 1,2      |
|  2 | 1,3      |
|  3 | 2,4      |
|  4 | 2        |
|  5 | NULL     |
|  6 | NULL     |
|  7 | NULL     |
+----+----------+
7 rows in set (0.01 sec)
```
