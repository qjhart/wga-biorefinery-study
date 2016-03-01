\set ON_ERROR_STOP 1
BEGIN;

set search_path=msw,public;

create or replace view msw.feedstock as 
select c.qid,
'msw'::varchar(24) as scenario, 
'msw.yard'::varchar(24) as type, 
10::float as price, 
msw_landfilled_tons_yr*0.07*0.75*
msw.population_growth(substr(qid,2,5),2006,2015) as marginal_addition 
from msw.msw_by_city c
union
select c.qid,
'msw' as scenario, 
'msw.wood' as type, 
27.5 as price_id,
msw_landfilled_tons_yr*0.089*0.75*
msw.population_growth(substr(qid,2,5),2006,2015) as marginal_addition 
from msw.msw_by_city c
union
select c.qid,
'msw' as scenario, 
'msw.paper' as type, 
27.5 as price_id, 
msw_landfilled_tons_yr*0.207*0.5*
msw.population_growth(substr(qid,2,5),2006,2015) as marginal_addition 
from msw.msw_by_city c
union
select c.qid,
'msw' as scenario, 
'msw.food' as type, 
27.5 as price_id, 
msw_landfilled_tons_yr*0.186*0.5*
msw.population_growth(substr(qid,2,5),2006,2015) as marginal_addition 
from msw.msw_by_city c
union
select c.qid,
'msw' as scenario, 
'msw.dirty' as type, 
27.5 as price, 
msw_landfilled_tons_yr*(0.819-0.207*0.5-0.089*0.75-0.07*0.75-0.186*0.5)*0.75*
msw.population_growth(substr(qid,2,5),2006,2015) as marginal_addition 
from msw.msw_by_city c
union
select c.qid,
'msw' as scenario, 
'grease' as type, 
320.0 as price, 
(pop_2000*1.29*9/2000)*msw.population_growth(substr(p.qid,2,5),2000,2015) as marginal_addition 
from msw.msw_by_city c join network.place p using (gid)
union -- per capita construction/demo from nathan
select c.qid,
'msw' as scenario, 
'msw.constr_demo' as type, 
27.5 as price, 
((0.02723+0.2897)*(pop_2000*msw.population_growth(substr(p.qid,2,5),2000,2015))) as marginal_addition 
from msw.msw_by_city c join network.place p using (gid);
--union
--select c.qid,
--'msw' as scenario, 
--'msw.demo' as type, 
--27.5 as price, 
--(0.2897*(pop_2000*msw.population_growth(substr(p.qid,2,5),2000,2015))) as marginal_addition 
--from msw.msw_by_city c join network.place p using (gid);

END;
