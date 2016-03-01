\set ON_ERROR_STOP 1
BEGIN;
\set t cotton_trash

set search_path=feedstock,public;

drop table if exists :t;
create table :t (
       qid varchar(8),
       scenario varchar(32),
       type varchar(24),
       price float,
       marginal_addition float
);       

create temp table foo as select * from :t;

COPY foo (type,qid,price,marginal_addition) FROM 'cotton_trash.csv' 
WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

insert into :t (qid,scenario,type,price,marginal_addition) 
select distinct qid,'all',type,price,marginal_addition 
from foo 
where marginal_addition != 0 and qid not like '%00';

\echo The following  qids are not good
select s.qid from foo s left join network.county c using (qid) 
where c is NULL and qid not like '%00';

END;
