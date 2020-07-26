create table digit(n int);

insert into digit value(0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

set @var:=0, @var3:=3 ,@var5:=5;

select if(fizz is null,if(buzz is null,var,buzz),if(buzz is null,fizz,concat(fizz,buzz))) as '?' from (
select @var3:=@var3-1 , @var5:=@var5-1 , @var:=@var+1 as var,
@fizz:=if (@var3=0,"fizz",null) as fizz,
@buzz:=if (@var5=0,"buzz",null) as buzz,
if (@var3=0,@var3:=3,null),
if (@var5=0,@var5:=5,null)
from(
  select d1.n + d2.n * 10 + 1 n
  from digit d1, digit d2
) d ) a
;