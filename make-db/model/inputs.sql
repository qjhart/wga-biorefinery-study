\set ON_ERROR_STOP 1
BEGIN;
SET search_path = model, public;

create or replace view source_list as 
select distinct qid as source 
from feedstock.feedstock
order by source;

create or replace view price as 
select distinct 'PL'||price::integer as price_id,price::integer as price 
from feedstock.feedstock 
order by price asc;

create or replace view supply as 
select qid as source,scenario,type,
'PL'||price::integer as price_id,marginal_addition 
from feedstock.feedstock;

create or replace view src2refine as
select src_qid,dest_qid,cost as bale_cost,road_mi,rail_mi,water_mi,road_hrs 
from network.feedstock_odcosts;

create or replace view src2refine_liq as
select src_qid,dest_qid,cost as liq_cost,
road_mi,rail_mi,water_mi,road_hrs 
from network.liquid_odcosts;

create or replace view terminal_odcosts as
select src_qid,dest_qid,cost as fuel_cost,water_mi,rail_mi 
from network.terminal_odcosts;

-- create or replace view refine as 
-- select distinct proxy_qid as qid,t.qid as terminal_qid,
--   e.qid as ethanol_qid,e.status as ethanol_status,
--   e.capacity as ethanol_capacity,
--   e.capital_in as ethanol_capital_investment 
-- from refineries.proxy_location p 
-- left join refineries.has_terminal t on (src_qid=t.qid) 
-- left join refineries.ethanol_facility e on (src_qid=e.qid) 
-- order by proxy_qid;

create or replace view pulpmills as 
select qid,cap_2000,sulfit2000,sulfat2000 
from forest.pulpmills;

END;


