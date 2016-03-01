\set ON_ERROR_STOP 1
\set s r_@SCENARIO@
\set qs '''r_@SCENARIO@'''

drop SCHEMA IF EXISTS :s cascade;
BEGIN;
create SCHEMA :s;

set search_path=:s,public;

create table brfn (
       pid serial primary key,
       run varchar(8),
       d_id varchar(24),
       f_type varchar(32),
       lcetype varchar(32),
       fstk_type varchar(32),
       quant_mgy real
);

copy brfn (run,d_id,f_type,lcetype,fstk_type,quant_mgy) from 'results_@SCENARIO@_brfn.put' with csv;

create table brfn_ct as select * from crosstab(
       'select pid, 
       	       d_id, 
	       run, 
	       f_type, 
	       lcetype, 
	       fstk_type, 
	       quant_mgy 
	       from brfn order by 1',
	'select distinct fstk_type from brfn order by 1') 
       	       as ct(
	       	  pid int,
		  d_id text, 
		  run text, 
		  f_type text, 
		  lcetype text, 
		  acost real,  
		  ag_res real,  
		  animal_fats real,  
		  ccost real,  
		  corngrain real,  
		  credit real,  
		  forest real,  
		  fpcost real,  
		  ftcost real,  
		  grease real,  
		  hec real,  
		  mcost real,  
		  msw_dirty real,  
		  msw_food real,  
		  msw_paper real,  
		  msw_wood real,  
		  msw_yard real,  
		  ovw real,  
		  production real,  
		  pulpwood real,  
		  seed_oils real,  
		  tcost real);

--creates geographic name identifier columns
alter table brfn_ct add column city varchar(48);
alter table brfn_ct add column county varchar(56);
alter table brfn_ct add column state varchar(48);


--links table schema:
create table links (
       m_run varchar(8),
       source_id varchar(8),
       dest_id varchar(8),
       type varchar(32),
       quant_tons float
);

--links table source

COPY links (m_run, source_id, dest_id, type, quant_tons) 
FROM 'results_@SCENARIO@_links.put' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

--create geography colums for map results

select addgeometrycolumn(:qs,'brfn_ct','location',102004,'POINT',2);
select addgeometrycolumn(:qs,'links','route', 102004,'LINESTRING',2); 

--populate the geo names fields
update brfn_ct set location=d.centroid 
from network.place d where d.qid=d_id;

update brfn_ct set city=d.name, county=d.county, state=d.state 
from network.place d where d.qid=d_id;

--create lines linking sources and destinations for all pairs (feedstock-->refinery and refinery--> terminal)
update links l set route=makeline(s.centroid,d.centroid) 
from network.place s, network.place d 
where (l.source_id like 'D%' or l.source_id like 'M%') 
and s.qid='D'||substr(l.source_id,2,7) and d.qid=l.dest_id;

update links l set route=makeline(s.centroid,d.centroid) 
from network.county s, network.place d 
where l.source_id like 'S%' 
and s.qid=l.source_id and d.qid=l.dest_id;

--subset the links table for only feedstock-->refinery links at proce points
--run12
create table run12fs_links as 
select m_run, source_id, dest_id, route, sum(quant_tons) as quant_tons 
from links 
where type in ('ovw','msw_wood','hec','forest','ag_res','msw_yard',
               'animal_fats','pulpwood','msw_paper') and m_run='run12'
group by source_id, dest_id, route, m_run;

--run17
create table run17fs_links as 
select m_run, source_id, dest_id, route, sum(quant_tons) as quant_tons 
from links 
where type in ('ovw','msw_wood','hec','forest','ag_res','msw_yard',
               'animal_fats','pulpwood','msw_paper') and m_run='run17'
group by source_id, dest_id, route, m_run;

--subset the links table for only refinery-->terminal links

create table fuel_links as 
select m_run, source_id, dest_id, route, sum(quant_tons) as quant_tons 
from links 
where type in ('lce','fame','dry_mill','wet_mill')
group by source_id, dest_id, route, m_run;

--create a termial table with delivered volumes and calculate the distance traveled by each delivery. It would be good to add a calculation for weighted average distance distance traveled/galon of fuel....

create table termvol as 
select m_run, dest_id, source_id, quant_tons, 
ST_Length(route)*0.000621371192 as st_dist_mi 
from fuel_links;

select addgeometrycolumn(:qs,'termvol', 'location', 102004, 'POINT',2);

update termvol set location=d.centroid 
from network.place d 
where d.qid=dest_id;
--create a map table for price points

--run12 $2.50
create table run12brfn_locations as 
       select
       d_id, 
       f_type, 
       --run,
       sum(production) as production, 
       location, 
       sum(ag_res)as ag_res,
       sum(forest)as forest,
       sum(hec)as hec,
       sum(msw_paper)as msw_paper,
       sum(msw_wood)as msw_wood,
       sum(msw_yard)as msw_yard,
       sum(ovw)as ovw,
       sum(pulpwood)as pulpwood,
       sum(corngrain)as corn,
       sum(animal_fats)as animal_fats,
       sum(grease)as grease,
       sum(seed_oils)as seed_oils,
       sum(mcost)as mcost,
       avg(acost)as acost,
       avg(fpcost)as fpcost,
       avg(ftcost)as ftcost,
       avg(ccost)as scost ,
       avg(tcost)as tcost,
       avg(credit)as credit 
from r_@SCENARIO@.brfn_ct where run='run12' group by d_id, f_type, location;
--run17 $3.00
create table run17brfn_locations as 
       select
       d_id, 
       f_type, 
       --run,
       sum(production) as production, 
       location, 
       sum(ag_res)as ag_res,
       sum(forest)as forest,
       sum(hec)as hec,
       sum(msw_paper)as msw_paper,
       sum(msw_wood)as msw_wood,
       sum(msw_yard)as msw_yard,
       sum(ovw)as ovw,
       sum(pulpwood)as pulpwood,
       sum(corngrain)as corn,
       sum(animal_fats)as animal_fats,
       sum(grease)as grease,
       sum(seed_oils)as seed_oils,
       sum(mcost)as mcost,
       avg(acost)as acost,
       avg(fpcost)as fpcost,
       avg(ftcost)as ftcost,
       avg(ccost)as scost ,
       avg(tcost)as tcost,
       avg(credit)as credit 
from r_@SCENARIO@.brfn_ct where run='run17' group by d_id, f_type, location;

END;
