# SQL実力アップセミナー(Step1 回答)

## Answer
### A0 テーブルの削除順序、作成順序
親テーブルから作成し子テーブルから削除する必要があるため

order_details は orders, itemsに依存している

```
FOREIGN KEY (order_id) REFERENCES orders(id),
FOREIGN KEY (item_id) REFERENCES items(id)
```

orders は customers に依存している

```
FOREIGN KEY (customer_id) REFERENCES customers(id)
```

### A0 テーブル確認をしましょう
```
show tables;

select * from customers;

select * from items;

select * from order_details;

select * from orders;
```

### A1 商品シャツの売り上げ合計金額を算出しましょう
```
select sum(a.price * b.item_quantity) proceeds from items a inner join order_details b on (a.id = b.item_id)  where a.name = 'シャツ';
```

### A1 解答後補足問題
結合順序を変えてみましょう
```
select sum(a.price * b.item_quantity) proceeds from order_details b inner join items a on (a.id = b.item_id and a.name = 'シャツ');
```

### A2 商品をでランダムに1行求めましょう
```
select * from items order by rand() limit 1;
```

### A2 解答後補足問題1
見た目上は１レコードを取得しているが、全レコードに乱数値を設定し全件ソートし１レコードを取得していることに注意しましょう

### A2 解答後補足問題２
前提として「`*`」はレコードを示すワイルドカードと認識しましょう。プログラムコード内にSQLを記述する際にレコード内のカラムデータを取得する場合は「`*`」は使用せず、必要なカラム名を全て記載しましょう。レコードを意識するケース、例えばレーコード件数などを取得する場合「`SELECT COUNT(*)`」などは「`*`」が推奨です

### A3 商品「シャツ」「パンツ」を受注した受注idを求めましょう。受注idは新しい(大きい)順に並べましょう
```
select distinct  b.order_id from items a inner join order_details b on a.id = b.item_id where name in ('シャツ','パンツ') order by b.order_id desc;
```

### A3 解答後補足問題1
Q3のSQL文をunion句を用いて同じ結果になるSELECT文を構築しましょう
```
select order_id from (select b.order_id from items a inner join order_details b on a.id=b.item_id  where name = 'シャツ' union select b.order_id from items a inner join order_details b on a.id=b.item_id  where name = 'パンツ') c order by order_id desc;
```

### A3 解答後補足問題2
Q3のSQL文をgroup by句を用いて同じ結果になるSELECT文を構築しましょう
```
select b.order_id from items a inner join order_details b on a.id = b.item_id where name in ('シャツ','パンツ') group by b.order_id order by b.order_id desc;
```

### A4 受注全体から受注金額の平均を算出しましょう
```
select avg(sum_price) from (select a.order_id,sum(b.price * a.item_quantity) sum_price from order_details a inner join items b on b.id = a.item_id group by order_id) c;
```

### A4 解答後補足問題
受注の件数も一緒に取得しましょう
```
select avg(sum_price),count(order_id) order_couunt from (select a.order_id,sum(b.price * a.item_quantity) sum_price from order_details a inner join items b on b.id = a.item_id group by order_id) c;
```

### A5 受注金額が一番大きい受注の受注idと受注金額を求めましょう
```
select a.order_id,sum(b.price * a.item_quantity) order_price from order_details a inner join items b on a.item_id = b.id group by a.order_id order by order_price desc limit 1;
```

### A5 解答後補足問題
今回の回答が正しいか考えてみましょう

追加データ
```
insert into orders(id,order_date,customer_id,created_at,updated_at) values(5 , '2013-10-02',2,now(),now());
insert into order_details(order_id,item_id,item_quantity,created_at,updated_at) values(5 , 2 ,80,now(),now());
```

limit句で１件しか取得していないため、受注金額の一番大きい受注が複数の場合問題となる可能性がある(問題にするかは要件次第)
```
select a.order_id,sum(b.price * a.item_quantity) order_price from order_details a inner join items b on a.item_id = b.id group by a.order_id having order_price = (select max(order_price) from (select a.order_id,sum(b.price * a.item_quantity) order_price from order_details a inner join items b on a.item_id = b.id group by a.order_id) c);
```