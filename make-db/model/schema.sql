\set ON_ERROR_STOP 1
BEGIN;
drop SCHEMA IF exists model CASCADE;
CREATE SCHEMA model;
SET search_path = model, public;

create table technology (
tech_id serial primary key,
tech varchar(12) unique,
energy_density_gge_per_gal float);

create table runs (
run varchar(8) primary key,
price_point float
);

create table conversion_efficiency
(
  conv_eff_id serial primary key,
  tech varchar(12) references model.technology(tech),
  type varchar(24),
  gal_per_bdt float,
  ghg_intensity_Mg_per_gge float
);


CREATE TABLE test (
       test_id serial primary key,
       name character varying(32) unique,
       description text
);
COPY test (test_id,name,description) FROM stdin WITH DELIMITER '|';
1|lce|Regional Mid-prediction LCE
2|corn|National corn
3|lipids|National lipids
\.

CREATE TABLE test_feedstock_scenario (
       test_id integer references test(test_id),
       type varchar(24),
       scenario varchar(32),
       unique(test_id,type)
);
COPY test_feedstock_scenario (test_id,type,scenario) FROM stdin WITH DELIMITER '|';
1|ag|inl
1|cotton_trash|all
1|forest.log|all forest
1|forest.mill|all forest
1|forest.other|all forest
1|forest.thin|all forest
1|hec|no_past_high
1|msw.dirty|msw
1|msw.paper|msw
1|msw.wood|msw
1|msw.yard|msw
1|OVW|all
1|pulpwood|usfs
2|corngrain|nass
3|canola_oil|all
3|grease|msw
3|lard_cwg|all
3|soybean_oil|all
3|tallow|all
\.


create table test_region (
  test_id integer,
  region varchar(12)
);
COPY test_region (test_id,region) FROM STDIN with CSV HEADER;
test_id,region
1,north
1,south
1,east
1,west
2,national
3,national
\.

create table region_fpr (
fpr_id integer references cmz.farm_production_region,
region varchar(12)
);
COPY region_fpr (region,fpr_id) from STDIN WITH CSV HEADER;
region,fpr_id
west,9
west,5
east,7
east,1
east,10
north,8
north,4
north,2
south,11
south,3
national,1
national,2
national,3
national,4
national,5
national,6
national,7
national,8
national,9
national,10
national,11
\.

create view region_states as 
select state_fips,region from region_fpr join cmz.fpr_state using (fpr_id);

create table model_feedstocks as 
select distinct region,test_id,fid 
from model.test join model.test_region using (test_id) 
join model.test_feedstock_scenario fts using(test_id) 
join region_states using(region) join feedstock.feedstock f   
on (fts.type=f.type and fts.scenario=f.scenario 
    and substring(qid from 2 for 2)=state_fips);

create table model_refinery_qids as 
select distinct region,test_id,qid 
from model.test join model.test_region using (test_id) 
join region_states using (region) 
join refineries.m_proxy_location on (substring(qid from 2 for 2)=state_fips);

CREATE OR REPLACE FUNCTION model_border_feedstock_qids (
travel_cost_per_bdt float)
RETURNS TABLE(
region varchar(8),
test_id integer,
qid varchar(8)
)
AS $$
select distinct r.region,r.test_id,tf.qid
from network.feedstock_odcosts c 
join model.model_refinery_qids r on (r.qid=c.dest_qid) 
join 
( select distinct qid
  from model.test t join model.test_region using (test_id)
  join model.test_feedstock_scenario tfs using (test_id)
  join feedstock.feedstock f using(type,scenario)
  left join model.model_feedstocks mf using (test_id,region,fid)
  where mf is NULL
) as tf on (c.src_qid=tf.qid)
where c.cost < $1
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_border_feedstocks (
travel_cost_per_bdt float)
RETURNS TABLE(
region varchar(8),
test_id integer,
fid integer
)
AS $$
select region,test_id,fid
from model.test t join model.test_region using (test_id)
join model.test_feedstock_scenario using (test_id)
join feedstock.feedstock f using (type,scenario)
join model.model_border_feedstock_qids($1) using (region,test_id,qid)
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_and_border_feedstocks (
travel_cost_per_bdt float)
RETURNS TABLE(
region varchar(8),
test_id integer,
fid integer
)
AS $$
select region,test_id,fid from model.model_feedstocks union
select region,test_id,fid from model.model_border_feedstocks($1)
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_source_list(
travel_cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
source varchar(8)
)
AS $$
select distinct qid 
from feedstock.feedstock
join model.model_and_border_feedstocks($1) using (fid)
join model.test t using (test_id)
where t.name=$3 and region=$2
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_price(
travel_cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
price_id varchar(32),
price integer
)
AS $$
select distinct 'PL'||price::integer as price_id,price::integer as price 
from feedstock.feedstock
join model.model_and_border_feedstocks($1) using (fid)
join model.test t using (test_id)
where t.name=$3 and region=$2
order by price asc
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_supply(
travel_cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
source varchar(8),
scenario varchar(32),
type varchar(24),
price_id varchar(32),
marginal_addition float
)
AS $$
select qid as source,scenario,type,'PL'||price::integer as price_id,
       marginal_addition 
from model.model_and_border_feedstocks($1) 
join feedstock.feedstock using (fid) 
join model.test t using (test_id)
where t.name=$3 and region=$2;
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_refine(
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
qid varchar(8),
terminal_qid varchar(8),
ethanol_qid varchar(8),
ethanol_status varchar(254),
ethanol_start_year integer,
ethanol_capacity float,
ethanol_feedstock varchar(254)
)
AS $$
select distinct proxy_qid as qid,ht.qid::varchar(8) as terminal_qid,
     e.qid::varchar(8) as ethanol_qid,e.status as ethanol_status,
     e.start_year as ethanol_start_year,
     e.capacity as ethanol_capacity,
     e.feedstock as ethanol_feedstocks
from model.model_refinery_qids m
join model.test t using (test_id)
join refineries.proxy_location p on (m.qid=p.proxy_qid)
left join refineries.has_terminal ht on (src_qid=ht.qid)
left join refineries.ethanol_facility e on (src_qid=e.qid)
where t.name=$2 and m.region=$1
order by proxy_qid;
$$ LANGUAGE 'sql' VOLATILE;


CREATE OR REPLACE FUNCTION model_src2refine(
travel_cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
src_qid varchar(8),
dest_qid varchar(8),
bale_cost float,
road_mi float,
rail_mi float,
water_mi float,
road_hrs float)
AS $$
select src_qid,dest_qid,cost as bale_cost,road_mi,rail_mi,water_mi,road_hrs 
from 
network.feedstock_odcosts c
join
 ( select qid as dest_qid from model.model_refinery_qids 
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as d using (dest_qid)
join
 (select distinct qid as src_qid from feedstock.feedstock join 
   model.model_and_border_feedstocks($1) mf using (fid)
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as s using (src_qid)
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_src2refine_liq(
cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
src_qid varchar(8),
dest_qid varchar(8),
bale_cost float,
road_mi float,
rail_mi float,
water_mi float,
road_hrs float)
AS $$
select src_qid,dest_qid,cost as bale_cost,road_mi,rail_mi,water_mi,road_hrs 
from
network.liquid_odcosts c
join
 ( select qid as dest_qid from model.model_refinery_qids 
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as d using (dest_qid)
join
 (select qid as src_qid from feedstock.feedstock 
   join model.model_and_border_feedstocks($1) mf using (fid)
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as s using (src_qid)
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION model_terminal_odcosts(
cost_per_bdt float,
region varchar(12),
name varchar(32)
)
RETURNS TABLE (
src_qid varchar(8),
dest_qid varchar(8),
fuel_cost numeric,
water_mi numeric,
rail_mi numeric)
AS $$
select src_qid,dest_qid,cost as fuel_cost,water_mi,rail_mi
from 
network.terminal_odcosts c
join
 ( select qid as dest_qid from model.model_refinery_qids 
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as d using (dest_qid)
join
 (select qid as src_qid from feedstock.feedstock 
   join model.model_and_border_feedstocks($1) mf using (fid)
   join model.test t using(test_id)
   where t.name=$3 and region=$2) as s using (src_qid)
$$ LANGUAGE 'sql' VOLATILE;


END;

