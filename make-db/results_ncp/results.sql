\set ON_ERROR_STOP 1
\set s ncp_@SCENARIO@
\set qs '''ncp_@SCENARIO@'''

drop SCHEMA IF EXISTS :s cascade;
create SCHEMA :s;
set search_path=:s,public;

BEGIN;

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
ag_res float,
hec float,
forest float,
ovw float,
pulpwood float,
msw_wood float,
msw_paper float,
msw_constr_demo float,
msw_yard float,
msw_food float,
msw_dirty float,
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
COMMENT ON COLUMN brfn.ag_res IS '(K bdt/yr)'; 
COMMENT ON COLUMN brfn.hec IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.forest IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.ovw IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.pulpwood IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_wood IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_paper IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_constr_demo IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_yard IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_food IS '(K bdt/yr)';
COMMENT ON COLUMN brfn.msw_dirty IS '(K bdt/yr)';
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

copy brfn(scenario,fuel_price,"qid","technology","class","fuel_output","electricity_output","naptha","feedstock_capacity","ag_res","hec","forest","ovw","pulpwood","msw_wood","msw_paper","msw_constr_demo","msw_yard","msw_food","msw_dirty","corngrain","animal_fats","grease","seed_oils","sugar","capital_cost","annual_cost","annual_capital","o_m","feedstock_procurement","feedstock_transport","fuel_distribution","marginal_feedstock","mc","ac","max_trans_dist","feed_truck_freight","feed_rail_freight","feed_barge_freight") from  'results_@SCENARIO@_brfn.csv' with csv HEADER;


-- msw_food | hec?
-- dry_mill=corngrain
-- wet_mill=corngrain
-- sugar_etoh=sugar
-- fahc=animal_fats|grease
-- ft_diesel=ag_res|hec|forest|ovw|pulpwood|msw_wood|msw_paper|msw_constr_demo|msw_yard|msw_food|msw_dirty 
-- fame=animal_fats|grease

create or replace view brfn_shp as 
select b.*,d.name,d.county,d.state,d.centroid 
from brfn b 
join network.place d 
using (qid);

-- In functions.sql too :( this is the makefile version.
create or replace function summary_chart(t brfn) 
returns TEXT AS $$
DECLARE
total float;
nmes text;
vals text;
BEGIN
total=t.ag_res+t.hec+t.forest+t.ovw+t.pulpwood+t.msw_wood+t.msw_paper
     +t.msw_constr_demo+t.msw_yard+t.msw_food+t.msw_dirty+t.corngrain
     +t.animal_fats+t.grease+t.seed_oils+t.sugar;
if (t.technology = 'dry_mill' or t.technology = 'wet_mill') THEN
nmes='corngrain';
vals=coalesce(t.corngrain,0);
elsif (t.technology='sugar_etoh') THEN
nmes='sugar';
vals=coalesce(t.sugar,0);
elsif (t.technology='fahc' or t.technology='fame') THEN
nmes='animal_fats|grease|seed_oils';
vals=coalesce(t.animal_fats,0)||','||coalesce(t.grease,0)||','||coalesce(t.seed_oils,0);
else
nmes='ag_res|hec|forest|ovw|pulpwood|msw_wood|msw_paper|msw_constr_demo|msw_yard|msw_food|msw_dirty';
vals=coalesce(t.ag_res,0)||','||coalesce(t.hec,0)||','||coalesce(t.forest,0)||','||coalesce(t.ovw,0)||','||coalesce(t.pulpwood,0)||','||coalesce(t.msw_wood,0)||','||coalesce(t.msw_paper,0)||','||coalesce(t.msw_constr_demo,0)||','||coalesce(t.msw_yard,0)||','||coalesce(t.msw_food,0)||','||coalesce(t.msw_dirty,0);
end if;

RETURN 'http://chart.apis.google.com/chart?chxs=0,676767,13&chxt=x&chs=300x225&cht=p&chco=008000,3399CC,FFFF88'||
       '&chds=0,'||total||
       '&chd=t:'|| vals ||
'&chdlp=l&chl='|| nmes ||'&chma=5,5,5,5&chtt=Feedstocks';
END;
$$ LANGUAGE plpgsql;

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
FROM 'results_@SCENARIO@_feedstock_links.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;


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


END;

