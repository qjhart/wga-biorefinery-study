SET search_path = feedstock, public;
\set ON_ERROR_STOP 1
BEGIN;

drop table if exists feedstock;
create table feedstock (
    fid serial primary key,
    qid varchar(8),
    scenario varchar(32),
    type varchar(24),
    price float,
    marginal_addition float);
create index feedstock_qid on feedstock(qid);
create index feedstock_type on feedstock(type);
create index feedstock_scenario on feedstock(scenario);

-- Get all the feedstocks together.

-- Soybean and canola oil are shipped to their closest (as bird flies)
-- destinations
create or replace view oils as
select 'SB'||e.gid as qid,
'all'::varchar(32) as scenario,
'soybean_oil'::varchar(32) as type, 
price,
sum(n.harvested*g.yield_growth*g.acreage_growth*11.28*33/2000) as marginal_addition 
from nass.nass n 
join (select fips,min(distance(c.centroid,e.centroid)) as min 
      from nass.nass n 
      join network.county c 
      using (fips),refineries.epa_facility e 
      where e.sic_code=2075 and n.commcode=15499199 and year=2007 
      group by fips) as min 
using (fips) 
join network.county c using (fips) 
join nass.commcode_growth_2007_2015 as g using (commcode),
refineries.epa_facility e 
where e.sic_code=2075 
and n.commcode=15499199 
and year=2007 
and c.fips=min.fips 
and distance(e.centroid,c.centroid)=min.min 
group by e.gid,g.price
union
select 
'CB'||e.gid as qid,
'all' as scenario,
'canola_oil' as type,
price,
sum(n.harvested*g.yield_growth*g.acreage_growth*0.383) as marginal_addition
from nass.nass n 
join (select fips,min(distance(c.centroid,e.centroid)) as min 
      from nass.nass n 
      join network.county c 
      using (fips),refineries.epa_facility e 
      where e.sic_code=2076 and n.commcode=15825599 and year=2007 
      group by fips) as min 
using (fips) 
join network.county c using (fips) 
join nass.commcode_growth_2007_2015 as g using (commcode)
,refineries.epa_facility e 
where e.sic_code=2076 and n.commcode=15825599 and year=2007 
and c.fips=min.fips 
and distance(e.centroid,c.centroid)=min.min 
group by e.gid,g.price;

insert into feedstock (qid,scenario,type,price,marginal_addition) 
select qid,scenario,type,price,marginal_addition from msw.feedstock;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from oils;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from forest.feedstock;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from nass.feedstock;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from hec.feedstock;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from animal_fats;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from cotton_trash;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from nelson.feedstock;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from feedstock.ovw;
insert into feedstock (qid,scenario,type,price,marginal_addition)
select qid,scenario,type,price,marginal_addition from madhu.feedstock;

delete from feedstock where marginal_addition = 0;
END;