\set ON_ERROR_STOP 1
BEGIN;

set search_path=feedstock,public;

drop table if exists ovw;
create table ovw (
       qid varchar(8),
       scenario varchar(32),
       type varchar(12),
       price float,
       marginal_addition float
);       

create temp table foo as select * from ovw;

COPY foo (type,qid,price,marginal_addition) FROM 'ovw.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

insert into ovw (qid,scenario,type,price,marginal_addition) 
select distinct 
qid,'all',type,price,marginal_addition 
from foo join network.county c using (qid) 
where marginal_addition != 0 and qid not like '%00';

\echo The following  qids are not good
select s.qid from foo s left join network.county c using (qid) 
where c is NULL and marginal_addition != 0 and s.qid not like '%00';

END;
