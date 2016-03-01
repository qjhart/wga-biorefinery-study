\set ON_ERROR_STOP 1

drop SCHEMA IF EXISTS :s cascade;
BEGIN;
create SCHEMA :s;

set search_path=:s,public;

create table brfn (
brfn_ser_id serial primary key,
scenario varchar(32),
fuel_price float,
qid varchar(8),
technology varchar(16),
class varchar(16),
fuel_output float,
electricity_output float,
naptha float,
feedstock_capacity float,
sorghum float,
stover float,
straw float,
switchgrass float,
woody_crop float,
forest float,
pulpwood float,
msw_woody float,
corngrain float,
animal_fats float,
grease float,
seed_oils float,
sugar float,
capital_cost float,
annual_cost float,
annual_capital float,
o_m float,
feedstock_procurement float,
feedstock_transport float,
fuel_distribution float,
marginal_feedstock float,
mc float,
ac float,
max_trans_dist float,
feed_truck_freight float,
feed_rail_freight float,
feed_barge_freight float
);

COMMENT ON COLUMN brfn.fuel_price IS '($/gge)';
COMMENT ON COLUMN brfn.fuel_output IS '(MGY)';
COMMENT ON COLUMN brfn.electricity_output IS '(GWh/yr)';
COMMENT ON COLUMN brfn.naptha IS '(MGY)';
COMMENT ON COLUMN brfn.feedstock_capacity IS '(bdt/day)';
COMMENT ON COLUMN brfn.sorghum IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.stover IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.straw IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.switchgrass IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.woody_crop IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.forest IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.pulpwood IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_woody IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.corngrain IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.animal_fats IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.grease IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.seed_oils IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.sugar IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.capital_cost IS '(M$)';
COMMENT ON COLUMN brfn.annual_cost IS '(M$/yr)';
COMMENT ON COLUMN brfn.annual_capital IS '(M$/yr)';
COMMENT ON COLUMN brfn.o_m IS '(M$/yr)';
COMMENT ON COLUMN brfn.feedstock_procurement IS '(M$/yr)';
COMMENT ON COLUMN brfn.feedstock_transport IS '(M$/yr)';
COMMENT ON COLUMN brfn.fuel_distribution IS '(M$/yr)';
COMMENT ON COLUMN brfn.marginal_feedstock IS '($/GJ)';
COMMENT ON COLUMN brfn.mc IS 'Marginal Cost ($/gge)';
COMMENT ON COLUMN brfn.ac IS 'Accumulative Cost ($/gge)';
COMMENT ON COLUMN brfn.max_trans_dist IS '(miles)';
COMMENT ON COLUMN brfn.feed_truck_freight IS '(ton-miles/yr)';
COMMENT ON COLUMN brfn.feed_rail_freight IS '(ton-miles/yr)';
COMMENT ON COLUMN brfn.feed_barge_freight IS '(ton-miles/yr)';


--sorghum,stover,straw,switchgrass,woody_crop,forest,pulpwood,msw_woody,corngrain,animal_fats,grease,seed_oils,sugar,


copy brfn(scenario,fuel_price,"qid","technology","class","fuel_output","electricity_output","naptha","feedstock_capacity",sorghum,stover,straw,switchgrass,woody_crop,forest,pulpwood,msw_woody,corngrain,animal_fats,grease,seed_oils,sugar,"capital_cost","annual_cost","annual_capital","o_m","feedstock_procurement","feedstock_transport","fuel_distribution","marginal_feedstock","mc","ac","max_trans_dist","feed_truck_freight","feed_rail_freight","feed_barge_freight") from  'results_@SCENARIO@_brfn.put' with csv HEADER;

create or replace function summary_chart(t brfn) 
returns TEXT AS $$
DECLARE
total float;
BEGIN
total=t.sorghum+t.stover+t.straw+t.switchgrass+t.woody_crop+t.forest+t.pulpwood+t.msw_woody+t.corngrain+t.animal_fats+t.grease+t.seed_oils+t.sugar;
RETURN 'http://chart.apis.google.com/chart?chxs=0,676767,13&chxt=x&chs=300x225&cht=p&chco=008000,3399CC,FFFF88'||
       '&chds=0,'||total||
       '&chd=t:'||
coalesce(t.sorghum,0)||','||coalesce(t.stover,0)||','||coalesce(t.straw,0)||','||coalesce(t.switchgrass,0)||','||coalesce(t.woody_crop,0)||','||coalesce(t.forest,0)||','||coalesce(t.pulpwood,0)||','||coalesce(t.msw_woody,0)||','||coalesce(t.corngrain,0)||','||coalesce(t.animal_fats,0)||','||coalesce(t.grease,0)||','||coalesce(t.seed_oils,0)||','||coalesce(t.sugar)||
'&chdlp=l&chl=sorghum|stover|straw|switchgrass|woody_crop|forest|pulpwood|msw_woody|corngrain|animal_fats|grease|seed_oils|sugar&chma=5,5,5,5&chtt=Feedstocks';
END;
$$ LANGUAGE plpgsql;


create or replace view brfn_shp as 
select b.*,d.name,d.county,d.state,d.centroid 
from brfn b 
join network.place d 
using (qid);

create or replace view brfn_summary as 
select ct.*,(p.name||' '||p.state)::varchar(64) as name,
       ('<img src="'||summary_chart(ct.*)||'">')::text as chart,
       p.centroid as centroid
from brfn ct
left join network.place p using (qid) ;
--grant select on brfn_summary to public;


--feedstocks_links table schema:
create table feedstock_links (
       link_id serial primary key,
       scenario varchar(32),
       fuel_price float,
       source_id varchar(8),
       dest_id varchar(8),
       type varchar(32),
       quant_tons float
);
COMMENT ON COLUMN feedstock_links.quant_tons IS '(bdt/yr)';

COPY feedstock_links (scenario,fuel_price, source_id, dest_id, type, quant_tons) 
FROM 'results_@SCENARIO@_feedstock_links.put' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;


-- --create lines linking sources and destinations for all pairs (feedstock-->refinery and refinery--> terminal)
-- select addgeometrycolumn(:qs,'feedstock_links','route', 102004,'LINESTRING',2); 

create or replace view feedstock_link_shp as 
select f.*,makeline(s.centroid,d.centroid) as route
from feedstock_links f 
join network.place s on(replace(f.source_id,'M','D')=s.qid)
join network.place d on(f.dest_id=d.qid)
union
select f.*,makeline(s.centroid,d.centroid) as route
from feedstock_links f 
join network.county s on(f.source_id=s.qid)
join network.place d on(f.dest_id=d.qid);


--fuel_links table schema:
create table fuel_links (
       link_id serial primary key,
       scenario varchar(32),
       fuel_price float,
       source_id varchar(8),
       dest_id varchar(8),
       type varchar(32),
       fuel_deliveries float
);
COMMENT ON COLUMN fuel_links.fuel_deliveries IS '(MGY)';

COPY fuel_links (scenario,fuel_price, source_id, dest_id, type, fuel_deliveries) 
FROM 'results_@SCENARIO@_fuel_links.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

create view fuel_links_shp as 
select f.*,makeline(s.centroid,d.centroid) as route
from fuel_links f 
join network.place s on(f.source_id=s.qid)
join network.place d on(f.dest_id=d.qid);

create table biomass_consumed (
       bmc_id serial primary key,
       scenario varchar(32),
       fuel_price float,
       source_id varchar(8),
       type varchar(32),
       price_id varchar(8),
       quantity float
);
COMMENT ON COLUMN biomass_consumed.quantity IS '(bdt/yr)';

COPY biomass_consumed (scenario,fuel_price, source_id, type,price_id,quantity) 
FROM 'results_@SCENARIO@_biomass_consumed.put' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

create table feedstock (
       qid varchar(8),
       scenario varchar(32),
       type varchar(24),
       price float,
       marginal_addition float
);


END;

