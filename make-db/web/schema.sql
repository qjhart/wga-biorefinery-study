\set ON_ERROR_STOP 1
--BEGIN;

drop SCHEMA
 IF exists web CASCADE;
CREATE SCHEMA web;
grant usage on schema web to public;
SET search_path = web, public,pg_catalog;

grant select on public.spatial_ref_sys to public;
grant usage on schema greedy to public;
grant select on greedy.technology to public;
grant select on greedy.test to public;
grant select on greedy.conversion_efficiency to public;

grant usage on schema network to public;
grant select on network.vertex to public;
grant select on network.edge to public;
grant select on network.place to public;
grant select on network.county to public;
grant select on network.state to public;

grant usage on schema refineries to public;
grant select on refineries.m_potential_location to public;
grant select on refineries.m_proxy_location to public;

grant usage on schema feedstock to public;
grant select on feedstock.feedstock to public;


\echo Creating sources table
create table sources as 
select qid,name,county,state,centroid
from (select distinct qid from feedstock.feedstock) as f left join 
(select qid,name::varchar(48) as county,name::varchar(48),state,centroid 
   from network.county 
 union select qid,county::varchar(48),name::varchar(48),state,centroid
   from network.place) as n 
using (qid) 
order by qid;
create index sources_qid on sources (qid) ;
grant select on sources to public;


create table type_summary (
 stype varchar(32),
 type varchar(32)
);
\copy type_summary (stype,type) FROM STDIN CSV HEADER
stype,type
seed_oils,seed_oils
pulpwood,pulpwood
animal_fats,animal_fats
forest,forest
grease,grease
ag_res,ag_res
ovw,ovw
corngrain,corngrain      
hec,hec
msw,msw_wood
msw,msw_yard
msw,msw_food
msw,msw_paper
msw,msw_dirty
\.

\echo Creating special table of optimization outputs
create table baseline_run17 as 
select dest_id,(p.name||' '||p.state)::varchar(64) as dest,
       source_id,s.name as source,
                 (s.county||' '||s.state)::varchar(128) as county,
       ts.stype,quant_tons,st_makeline(p.centroid,s.centroid) as connect
from r_baseline.links l 
join type_summary ts using (type)
left join network.place p on (dest_id=p.qid) 
left join web.sources s on (replace(source_id,'M','D')=s.qid) 
where m_run='run17';
grant select on baseline_run17 to public;

create or replace view baseline_ct as 
SELECT *
FROM crosstab(
  'select dest_id as qid,stype,sum(quant_tons)::integer as total_bdt
   from web.baseline_run17 group by dest_id,stype 
   union 
   select dest_id as qid,''total'',sum(quant_tons)::integer as total_bdt
   from web.baseline_run17 group by dest_id
   order by 1,2',
   'select distinct stype from web.type_summary union select ''total'' order by 1'
)
AS ct(
qid varchar(8),
ag integer,
animal_fats integer,
corngrain integer,
forest integer,
grease integer,
hec integer,
msw integer,
ovw integer,
pulpwood integer,
seed_oils integer,
total integer
);

create or replace function summary_chart(t baseline_ct) 
returns TEXT AS $$
BEGIN
RETURN 'http://chart.apis.google.com/chart?chxs=0,676767,13&chxt=x&chs=300x225&cht=p&chco=008000,3399CC,FFFF88'||
       '&chds=0,'||t.total||
       '&chd=t:'||
coalesce(t.ag,0)||','||coalesce(t.animal_fats,0)||','||coalesce(t.corngrain,0)||','||
coalesce(t.forest,0)||','||coalesce(t.grease,0)||','||coalesce(t.hec,0)||','||coalesce(t.msw,0)||','||coalesce(t.ovw,0)||','||
coalesce(t.pulpwood,0)||','||coalesce(t.seed_oils,0)||
'&chdlp=l&chl=ag|animal_fats|corngrain|forest|grease|hec|msw|ovw|pulpwood|seed_oils&chma=5,5,5,5&chtt=Feedstocks';
END;
$$ LANGUAGE plpgsql;

create or replace view baseline_summary as 
select ct.*,(p.name||' '||p.state)::varchar(64) as name,
       ('<img src="'||summary_chart(ct.*)||'">')::text as chart,
       p.centroid as centroid
from web.baseline_ct ct
left join network.place p using (qid) ;
grant select on baseline_summary to public;

create or replace view potential_refineries as 
select p.*,
('http://bioenergy.casil.ucdavis.edu:8080/biovizsource/BioenergyVisualizationSource.html?tq=select%20%2A&view=refinery_costs%28%27lce%27,%27'||p.qid||'%27,100,1.50%29')::text as feedstocks,
('http://bioenergy.casil.ucdavis.edu:8080/biovizsource/bioenergy/export?tq=select%20%2A&view=refinery_costs%28%27lce%27,%27'||p.qid||'%27,100,1.50%29&out=csv')::text as feedstock_csv,
('http://bioenergy.casil.ucdavis.edu:8080/biovizsource/bioenergy/export?tq=select%20%2A&view=refinery_costs%28%27lce%27,%27'||p.qid||'%27,100,1.50%29&out=excel')::text as feedstock_xls
from refineries.m_proxy_location p;

create or replace view web.refineries as 
select p.qid,p.name,p.county,p.state,
x(transform(p.centroid,4326)) as longitude,y(transform(p.centroid,4326)) as latitude
from refineries.m_proxy_location l join network.place p using (qid);

-- Returns All feedstocks at some price
CREATE OR REPLACE FUNCTION web.feedstock(
max_cost float)
RETURNS TABLE(
qid varchar(8),
name varchar(32),
county varchar(48),
state varchar(2),
scenario varchar(32),
type varchar(24),
total_bdt numeric,
avg_cost numeric
)
AS $$
select 
qid,s.name,s.county,s.state,scenario,type,
sum(marginal_addition)::decimal(12,0) as total_bdt
(CASE WHEN sum(marginal_addition) = 0 
 THEN Null 
 ELSE sum(price*marginal_addition)/sum(marginal_addition) 
 END)::decimal(6,2) as avg_cost
from feedstock.feedstock f
where f.marginal_addition != 0
and f.price <= $1
group by qid,scenario,type order by qid,type,scenario
join web.sources s using (qid);
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION web.feedstock(
test_name varchar(8),
max_cost float)
RETURNS TABLE(
qid varchar(8),
name varchar(32),
state varchar(2),
scenario varchar(32),
type varchar(24),
total_bdt numeric,
avg_cost numeric
)
AS $$
select 
qid,name,state,scenario,type,
sum(marginal_addition)::decimal(12,0) as total_bdt,
(CASE WHEN sum(marginal_addition) = 0 
 THEN Null 
 ELSE sum(price*marginal_addition)/sum(marginal_addition) 
 END)::decimal(6,2) as avg_cost
from feedstock.feedstock f join web.sources s using (qid),
greedy.test tst join greedy.technology t using (tech)
where tst.name=$1 
and f.marginal_addition != 0
and f.scenario=ANY(tst.scenarios)
and f.type=ANY(t.types)
and f.price <= $2
group by qid,scenario,type order by qid,type;
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION web.feedstock_tech_summary(
test_name varchar(8),
max_cost float)
RETURNS TABLE(
qid varchar(8),
name varchar(32),
state varchar(2),
tech varchar(24),
total_bdt numeric
)
AS $$
select 
qid,name,state,t.tech,sum(marginal_addition)::decimal(12,0) as total_bdt
from greedy.test tst,
greedy.technology t 
join feedstock.feedstock f on (f.type=ANY(t.types))
join sources s using (qid)
where tst.name=$1 
and f.scenario=ANY(tst.scenarios)
and f.marginal_addition != 0
and f.price <= $2
group by qid,t.tech order by qid,t.tech;
$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION web.feedstock_by_type(
max_cost float
)
RETURNS TABLE(
qid varchar(8),
"ag_inl" integer,
"ag_nass" integer,
"canola_oil" integer,
"corngrain" integer,
"cotton_trash" integer,
"f_log_all" integer,
"f_log_nf" integer,
"f_mill_all" integer,
"f_mill_nf" integer,
"f_other_all" integer,
"f_other_nf" integer,
"f_thin_all" integer,
"f_thin_nf" integer,
"grease_msw" integer,
"hec_np_h" integer,
"hec_np_l" integer,
"hec_p_h" integer,
"hec_p_l" integer,
"lard_cwg" integer,
"msw_dirty" integer,
"msw_paper" integer,
"msw_wood" integer,
"msw_yard" integer,
"pulpwood" integer,
"soy_oil" integer,
"tallow" integer
)
AS $$
SELECT *
FROM crosstab(
  'select qid,type||''_''||scenario,total_bdt
   from web.feedstock('||$1||')
   order by 1,2',
   'select distinct type||''_''||scenario from feedstock.feedstock order by 1'
)
AS ct(
qid varchar(8),
"ag_inl" integer,
"ag_nass" integer,
"canola_oil_all" integer,
"corngrain_nass" integer,
"cotton_trash_all" integer,
"forest.log_all forest" integer,
"forest.log_non-fed forest" integer,
"forest.mill_all forest" integer,
"forest.mill_non-fed forest" integer,
"forest.other_all forest" integer,
"forest.other_non-fed forest" integer,
"forest.thin_all forest" integer,
"forest.thin_non-fed forest" integer,
"grease_msw" integer,
"hec_no_past_high" integer,
"hec_no_past_low" integer,
"hec_past_high" integer,
"hec_past_low" integer,
"lard_cwg_all" integer,
"msw.dirty_msw" integer,
"msw.paper_msw" integer,
"msw.wood_msw" integer,
"msw.yard_msw" integer,
"pulpwood_usfs" integer,
"soybean_oil_all" integer,
"tallow_all" integer
);

$$ LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION web.feedstock_by_tech(
test_name varchar(8),
max_cost float
)
RETURNS TABLE(
qid varchar(8),
name varchar(32),
state varchar(2),
test varchar(8),
cost float,
biod integer, 
drymill integer, 
lce integer, 
pulp integer, 
pyr integer
)
AS $$
SELECT *
FROM crosstab(
  'select qid,name,state,'''||$1||''','||$2||',tech, total_bdt
   from web.feedstock_tech_summary('''||$1||''','||$2||')
   order by 1,2',
   'select distinct tech from greedy.technology order by 1')
AS ct(
qid varchar(8), 
name varchar(32),
state varchar(2),
test varchar(8),
cost float,
biod integer, 
drymill integer, 
lce integer, 
pulp integer, 
pyr integer
);

$$ LANGUAGE 'sql' VOLATILE;

-- Use m_potential when we get that.
CREATE OR REPLACE FUNCTION web.closest_source(
long float,
lat float,
use_potential_location boolean, 
max_distance float,
OUT source_id integer,
OUT source_qid varchar(8),
OUT source_point geometry,
OUT distance float) as $$
BEGIN
IF (use_potential_location is True) THEN
select v.id,p.qid,v.point,
ST_Distance(transform(setsrid(Makepoint(long,lat),4269),102004),v.point) as d
into source_id,source_qid,source_point,distance
from refineries.m_proxy_location 
join network.place p using (qid) 
join network.vertex v on (p.centroid=v.point) 
where ST_DWithin(transform(setsrid(Makepoint(long,lat),4269),102004),v.point,max_distance)
order by d asc limit 1;
ELSE
select v.id,Null::varchar(8),v.point,
ST_Distance(transform(setsrid(Makepoint(long,lat),4269),102004),v.point) as d
into source_id,source_qid,source_point,distance
from network.vertex v 
where ST_DWithin(transform(setsrid(Makepoint(long,lat),4269),102004),v.point,max_distance)
order by d asc limit 1;
END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION web.refinery_costs(
test_name varchar(8),
source_qid varchar(8),
max_delivered_cost float,
exp_price_per_gal float)
RETURNS TABLE(
qid varchar(8),
name varchar(32),
county varchar(32),
state varchar(2),
type varchar(24),
marginal_addition_bdt float,
marginal_addition_fuel float,
travel_cost float,
delivered_cost float,
total_bdt float,
total_fuel float,
total_feedstock_cost float,
refinery_cost float,
levelized_bdt_cost numeric,
levelized_fuel_cost numeric,
max_feed_for_min_levelized_cost numeric,
max_feed_for_max_profit numeric
)
AS $$
select 
qid,s.name,s.county,s.state,type,marginal_addition,
fuel_addition,travel_cost,delivered_cost,
total_bdt,total_gal,total_feedstock_cost,
(greedy.refinery_costs(
tech,
total_bdt,
total_gal,
total_feedstock_cost,
$4)).*
from (
select
f.fid,c.src_qid as qid,t.tech,f.type,f.marginal_addition,
f.marginal_addition*e.gal_per_bdt as fuel_addition,
c.cost as travel_cost,
(f.price+c.cost) as delivered_cost,
sum(marginal_addition) OVER w as total_bdt,
sum(marginal_addition*e.gal_per_bdt) OVER w as total_gal,
sum(f.price+c.cost) OVER w as total_cost,
sum((f.price+c.cost)*f.marginal_addition) OVER w as total_feedstock_cost
from greedy.test tst join greedy.technology t using (tech),
network.feedstock_odcosts c 
join feedstock.feedstock f on (f.qid=src_qid)
join greedy.conversion_efficiency e using (type)
where tst.name=$1
and f.scenario=ANY(tst.scenarios)
and f.type=ANY(t.types)
and gal_per_bdt>0
and c.dest_qid=$2
and (f.price+c.cost) < $3
WINDOW w as (ORDER BY (f.price+c.cost),marginal_addition)
) as f join web.sources s using (qid) order by total_bdt;
$$ LANGUAGE 'sql' VOLATILE;

-- CREATE OR REPLACE FUNCTION web.transportation_costs(
-- source_id integer,
-- max_cost float)
-- RETURNS TABLE(
-- id integer,
-- target integer,
-- bale_cost float,
-- path integer[],
-- targets integer[]
-- )
-- AS $$
-- with recursive se(id,target,bale_cost,path,targets) as (
--    select e.id,e.target,
--    e.bale_cost,e.path,e.targets
--    from (select e.id,e.target,
--    e.bale_cost,
--    min(bale_cost) OVER W as min_bale_cost,
--    ARRAY[e.id] as path,
--    ARRAY[e.id] as targets
--    from network.edge e where (source=$1)
--    WINDOW w as ( partition by e.source)) as e where e.bale_cost=e.min_bale_cost
--    UNION ALL
--    select e.id,e.target,
--           (s.bale_cost+e.bale_cost) as bale_cost,
--           path || e.id as path,
-- 	  targets || e.target as targets
--    from se s
--    join network.edge e on (s.target=e.source)
--    where
--    NOT e.target=ANY(s.targets) and
--    NOT e.id=ANY(path) and (s.bale_cost+e.bale_cost) < $2
--  )
--  select * from se;
-- $$ LANGUAGE 'sql' VOLATILE;


--END;

