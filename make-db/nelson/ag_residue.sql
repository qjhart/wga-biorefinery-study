\set ON_ERROR_STOP 1
BEGIN;

set search_path=nelson,public;

drop table if exists ag_residue;
create table ag_residue (
       qid varchar(8),
       type varchar(5),
       marginal_addition float
);       

-- This was from the old version of the table 
-- http://spreadsheets.google.com/pub?key=tb_IODHNpsZBP2HS06YWWnA&single=true&gid=0&output=csv
-- create temp table foo (
-- fips varchar(8),
-- county varchar(128),
-- state varchar(32),
-- cmz float,
-- acres float,
-- lbs float,
-- tons float,
-- tonsperacrce float,
-- rotations integer
-- );       


-- COPY foo (fips,county,state,cmz,acres,lbs,tons,tonsperacrce,rotations) FROM 'ag_residue.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

-- insert into ag_residue (qid,type,marginal_addition)
-- select 'S'||state_fips||substring(fips from 3) as qid,
--        'ag' as type,
--        tons as marginal_addition
-- from nelson.foo r join network.state s on (substring(r.fips from 1 for 2)=s.state_abbrev);

create temp table foo (
state varchar(32),
state_fips integer,
stateab varchar(2),
co_fips integer,
fubar varchar(6),
residue float,
tons float
);       


COPY foo (state,state_fips,stateab,co_fips,fubar,residue,tons) FROM 'ag_residue.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

insert into ag_residue (qid,type,marginal_addition)
select 'S'||repeat('0',2-length(state_fips::text))||state_fips||
            repeat('0',3-length(co_fips::text))||co_fips as qid,
       'ag' as type,
       tons as marginal_addition
from foo r;

-- \echo The following states are not good
-- select f.state from foo f left join network.state s using(state) where s is null;

END;
