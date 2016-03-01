\set ON_ERROR_STOP 1
BEGIN;
\set t animal_fats

set search_path=feedstock,public;

drop table if exists :t cascade;
create table :t (
       qid varchar(8),
       scenario varchar(32),
       type varchar(12),
       price float,
       marginal_addition float
);       

create temp table foo (
       name varchar(55),
       state char(20),
       type varchar(12),
       price float,
       marginal_addition float
);       

COPY foo (name,state,type,price,marginal_addition) 
FROM 'animal_fats.csv' 
WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

insert into :t (qid,scenario,type,price,marginal_addition)
select distinct p.qid,'all',f.type,price,marginal_addition 
from foo f join network.place p using (state,name) 
where marginal_addition != 0;

\echo The following  qids are not good
select s.state,s.name 
from foo s left join (select p.state,p.name,p.qid from network.place p 
union 
select s.state,p.name,p.qid 
from network.state s 
join network.place p on (s.state_fips=p.stfips)) as p 
using (state,name) 
where p is NULL;

END;
