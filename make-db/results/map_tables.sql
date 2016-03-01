\set ON_ERROR_STOP 1
\set s r_@SCENARIO@
\set qs '''r_@SCENARIO@'''
\set r @RUN@

drop TABLE IF EXISTS :r_brfn_locations;
BEGIN;
set search_path=:s,public;

create table :r_brfn_locations as 
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
from brfn_ct where run=:r group by d_id, f_type, location;

create table :r_fs_links as 
select m_run, source_id, dest_id, route, sum(quant_tons) as quant_tons 
from links 
where type in ('ovw','msw_wood','hec','forest','ag_res','msw_yard',
               'animal_fats','pulpwood','msw_paper') and m_run=:r
group by source_id, dest_id, route, m_run;

create table :r_fuel_links as 
select m_run, source_id, dest_id, route, sum(quant_tons) as quant_tons 
from links 
where type in ('lce','fame','dry_mill','wet_mill') and m_run=:r
group by source_id, dest_id, route, m_run;

END;