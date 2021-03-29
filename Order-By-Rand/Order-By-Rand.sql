set @rownum=0;

drop table teams;

create table teams (team varchar(30));

insert into teams values
;

select  (SELECT @rownum:=@rownum+1) as "登壇順", team as "登壇チーム" from
 (select team from teams order by rand()) c;
