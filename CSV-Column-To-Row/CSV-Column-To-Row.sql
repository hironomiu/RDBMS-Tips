CREATE TABLE csv (
  id int NOT NULL AUTO_INCREMENT,
  col varchar(10) DEFAULT NULL,
  PRIMARY KEY (id)
);

insert into csv(col) values ("a,b,c"), ("x,y,z"), ("1,3");

select SUBSTRING_INDEX(SUBSTRING_INDEX(col, ',', n), ',', -1) cut_col
from csv,
(select d1.n + d2.n * 10 + 1 n from
(select 1 as n
union select 2 as n
union select 3 as n
union select 4 as n
union select 5 as n
union select 6 as n
union select 7 as n
union select 8 as n
union select 9 as n
union select 0 as n) d1,
(select 1 as n
union select 2 as n
union select 3 as n
union select 4 as n
union select 5 as n
union select 6 as n
union select 7 as n
union select 8 as n
union select 9 as n
union select 0 as n) d2) d
where n <= (select length(col) - length(replace(col,',','')) + 1 as a )
order by id,n;

select id,n,SUBSTRING_INDEX(SUBSTRING_INDEX(col, ',', n), ',', -1) cut_col
from csv,
(select d1.n + d2.n * 10 + 1 n from
(select 1 as n
union select 2 as n
union select 3 as n
union select 4 as n
union select 5 as n
union select 6 as n
union select 7 as n
union select 8 as n
union select 9 as n
union select 0 as n) d1,
(select 1 as n
union select 2 as n
union select 3 as n
union select 4 as n
union select 5 as n
union select 6 as n
union select 7 as n
union select 8 as n
union select 9 as n
union select 0 as n) d2) d
where n <= (select length(col) - length(replace(col,',','')) + 1 as a )
order by id,n;
