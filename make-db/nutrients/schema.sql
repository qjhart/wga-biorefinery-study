\set ON_ERROR_STOP 1
drop SCHEMA IF exists nutrients CASCADE;
CREATE SCHEMA nutrients;
set search_path=nutrients,public;

-- Note these are similar to the values used in the
-- nass.commcode_biomass_per_crop, but vary from county to county.
create table crop_commcode (
       crop varchar(32),
       commcode integer
);

\copy crop_commcode (crop,commcode) FROM STDIN CSV HEADER
crop,commcode
barley,11399999
corn,11199199
sorghum,11499199
wheat,10119999
wheat,10129999
wheat,10139999
\.

create table residue_yields (
       qid varchar(8),
       crop varchar(32),
       gross_residue_per_acre float,
       required_residue_per_acre float,
       acres float,
       biomass_residue_38 float,
       biomass_residue_70 float
);       

create table nutrients (
       crop varchar(32),
       N float,
       P float,
       K float,
       cost_per_residue_bdt float
);       


\COPY residue_yields (qid,crop,gross_residue_per_acre,required_residue_per_acre,acres,biomass_residue_38,biomass_residue_70) FROM 'residue_yields.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

\COPY nutrients (crop,N,P,K,cost_per_residue_bdt) FROM 'nutrients.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

\echo Making nutrient cost function
CREATE OR REPLACE FUNCTION nutrient_cost(crop varchar(8), county_fips char(5), year float, OUT cost float) 
AS $$ 
select cost_per_residue_bdt as cost  
from nutrients.nutrients where crop=$1; 
$$ LANGUAGE 'sql';

\echo Calcuating feedstocks

-- create table feedstock (
-- qid varchar(8),
-- scenario varchar(32),
-- type varchar(32),
-- price float,
-- marginal_acres float,
-- marginal_addition float,
-- primary key(qid,scenario,type,price)
-- );
-- create index feedstock_qid on feedstock(qid);

create or replace view commodity_feedstock as
select
qid, 'nass_acres+nut'::varchar(32) as scenario,
commodity_description::varchar(32) as type,
(inl.harvest_cost
 (fips, 2018, 450.0,
  inl.residue(
  gross_residue_per_acre,
  required_residue_per_acre,
  0.38))
).total + cost_per_residue_bdt as price,
harvested::float as marginal_acres,
harvested*inl.residue(gross_residue_per_acre,
                      required_residue_per_acre,0.38)
 as marginal_addition
from nutrients.residue_yields y
join nutrients.nutrients using (crop)
join nutrients.crop_commcode using (crop)
join network.county using (qid)
join nass.nass using (fips,commcode)
join nass.commodity using (commcode)
where year=2007 and praccode=9 
and harvested*inl.residue(gross_residue_per_acre,
                      required_residue_per_acre,0.38) <> 0
union select
qid, 'nutrients38'::varchar(32) as scenario,
crop,
(inl.harvest_cost
 (substr(qid,2,5), 2018, 450.0,
  inl.residue(
  gross_residue_per_acre,
  required_residue_per_acre,
  0.38))
).total + cost_per_residue_bdt as price,
acres as marginal_acres,
acres*inl.residue(gross_residue_per_acre,required_residue_per_acre,0.38) 
  as marginal_addition
from nutrients.residue_yields y
join nutrients.nutrients using (crop)
where acres*inl.residue(gross_residue_per_acre,
                      required_residue_per_acre,0.38) <> 0
union select
qid, 'nutrients70'::varchar(32) as scenario,
crop,
(inl.harvest_cost
 (substr(qid,2,5), 2018, 450.0,
  inl.residue(
  gross_residue_per_acre,
  required_residue_per_acre,0.70))
).total + cost_per_residue_bdt as price,
acres as marginal_acres,
acres*inl.residue(gross_residue_per_acre,required_residue_per_acre,0.7) 
  as marginal_addition
from nutrients.residue_yields y
join nutrients.nutrients using (crop)
where acres*inl.residue(gross_residue_per_acre,
                      required_residue_per_acre,0.7) <> 0
;

create or replace view feedstock
as
select 
qid,
scenario,
'ag'::varchar(32) as type,
price,
sum(marginal_acres) as marginal_acres,
sum(marginal_addition) as marginal_addition
from commodity_feedstock
group by qid,scenario,price;


