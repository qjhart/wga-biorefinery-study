\set ON_ERROR_STOP 1
BEGIN;
set search_path=nass,public;

create or replace view commodity_feedstock as
select
('S'||fips)::varchar(12) as qid,
'nass'::varchar(32) as scenario,
commodity_description::varchar(32) as type,
(inl.harvest_cost(fips, 2015, 450.0,
                  sum(yield*biopercrop*bioavail),0.0)).total as price,
sum(harvested) as marginal_acres,
sum(production*biopercrop*biohareff*bioavail) as marginal_addition
from network.county join nass.nass using (fips)
join nass.commcode_biomass_yield using (commcode)
join nass.commodity using (commcode)
where year=2007 group by fips,commodity_description,biomassunit
having sum(harvested*biopercrop*biohareff*bioavail) <> 0;

drop table if exists feedstock;
create table feedstock (
qid varchar(8),
scenario varchar(32),
type varchar(32),
price float,
marginal_acres float,
marginal_addition float,
primary key(qid,scenario,type,price)
);
create index feedstock_qid on feedstock(qid);

insert into feedstock 
(qid,scenario,type,price,marginal_acres,marginal_addition)
select 
qid,
'nass'::varchar(32) as scenario,
'ag'::varchar(32) as type,
price,
sum(marginal_acres),
sum(marginal_addition)
from commodity_feedstock
group by qid,price
union
select 
'S'||fips,
'nass'::varchar(32) as scenario,
'corngrain' as type,
130.0 as price,
n.harvested*g.acreage_growth as marginal_acres,
n.production*g.yield_growth*g.acreage_growth/35.71 as marginal_addition 
from network.county c join nass.nass n using (fips) 
join nass.commcode_growth_2007_2015 g using (commcode) 
where commcode=11199199 and praccode=9 and year=2007;


END;