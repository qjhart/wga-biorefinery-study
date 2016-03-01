\set ON_ERROR_STOP 1
BEGIN;
set search_path=nelson,public;

drop table if exists feedstock cascade;
create table feedstock (
qid varchar(8),
scenario varchar(32),
type varchar(32),
price float,
marginal_addition float,
primary key(qid,scenario,type,price)
);
create index feedstock_qid on feedstock(qid);

-- insert into feedstock (qid,scenario,type,price,marginal_addition)
-- select 
-- qid,
-- 'inl'::varchar(32) as scenario,
-- 'ag'::varchar(32) as type,
-- price,
-- sum(marginal_addition) 
-- from wga_ag 
-- where type in ('wwheatstraw','oats','swheatstraw','rye','barley','cornstover')
-- group by qid,price;

insert into feedstock (qid,scenario,type,price,marginal_addition)
select distinct
 qid,
 'inl','ag',
 CASE WHEN p is NULL then 45 ELSE p.price END,
 marginal_addition
 from ag_residue join network.county using (qid)
 left join 
 (select fips,
         avg((inl.harvest_cost(fips, 2015, 450.0,
                     (yield*biopercrop*bioavail),0.0)).total) as price 
  from nass.nass join nass.commcode_biomass_yield 
  using (commcode) 
  where yield !=0 and biopercrop !=0 and bioavail != 0 and year=2007 and
  commcode in (10129999, 10139999, 10499999, 11199199, 11299999)
  group by fips) as p
 using (fips)
 where marginal_addition != 0;

END;

-- HEC         |  2136
-- OVW         |   260



