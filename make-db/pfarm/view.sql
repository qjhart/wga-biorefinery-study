-- Want to get these back in once we get the schema organized.

create or replace view  pfarm_fitness as 
  select pfarm_gid,
         case when (sum(area(the_geom))>1000000) 
              then 1000000::decimal(10,0) 
              else sum(area(the_geom))::decimal(10,0) end as arable,
         sum(comppct_r*irrcapcl::integer/100.0*area(the_geom))/sum(comppct_r/100.0*area(the_geom)) as arable_irrcapcl,
         sum(comppct_r*nirrcapcl::integer/100.0*area(the_geom))/sum(comppct_r/100.0*area(the_geom)) as arable_nirrcapcl 
 from pfarm.scp join component c using (mukey) 
 where class_name not like 'NLCD%' 
 group by pfarm_gid having sum(area(the_geom))>100000 
 order by arable;

create or replace view pfarm_crop_fitness as
select pfarm_gid,crop_id,nass.area as nass_area,
                         ssurgo.area as ssurgo_area,
                         ssurgo.irr_yield,
			 ssurgo.nonirr_yield,
			 ssurgo.yldunits
                         from
 (select pfarm_gid,crop_id,
         sum(area(the_geom))::decimal(10,0) as area 
  from pfarm.scp join pfarm.crop_class_name using(class_name) 
  group by pfarm_gid,crop_id having sum(area(the_geom)) > 10000
 ) as nass 
full outer join 
( select pfarm_gid,crop_id,yldunits,
         sum(area(the_geom))::decimal(10,0) as area,
         avg(irryield_r) as irr_yield,
         avg(nonirryield_r) as nonirr_yield
  from pfarm.scp join ssurgo.mucropyld using (mukey)
           join pfarm.crop_cropname using(cropname)
  group by pfarm_gid,crop_id,yldunits having sum(area(the_geom)) > 10000
) as ssurgo 
using (pfarm_gid,crop_id);

--create or replace view pfarm_county_crop_fitness as
--select pfarm_gid,crop_id,county_gid,nass_area,ssurgo_area,irr_yield
--from pfarm_crop_fitness join pfarm.pfarm_county using (pfarm_gid);

create or replace view pfarm_crop_score as 
  select pfarm_gid,crop_id,arable,
         case when ssurgo_area is null then 4*nass_area 
              when nass_area is null then (5-arable_irrcapcl)*ssurgo_area*(irr_yield/max_irr_yield)
              else 4*nass_area+(5-arable_irrcapcl)*ssurgo_area*(irr_yield/max_irr_yield) end as irr_score,
         case when ssurgo_area is null then 4*nass_area 
              when nass_area is null then (5-arable_irrcapcl)*ssurgo_area*(irr_yield/max_irr_yield)
              else 4*nass_area+(5-arable_irrcapcl)*ssurgo_area*(irr_yield/max_irr_yield) end as score,
         case when ssurgo_area is null then 4*nass_area 
              when nass_area is null then (5-arable_irrcapcl)*ssurgo_area*(nirr_yield/max_nirr_yield)
              else 4*nass_area+(5-arable_irrcapcl)*ssurgo_area*(nirr_yield/max_nirr_yield) end as nirr_score 
  from pfarm_fitness 
  join pfarm_crop_fitness using (pfarm_gid) 
  join (select crop_id,max(irr_yield) as max_irr_yield,max(nirr_yield) as max_nirr_yield from pfarm_crop_fitness group by crop_id) as max_yield using (crop_id)
order by score desc;

--create or replace view pfarm_county_crop_score as 
--  select pfarm_gid,county_gid,crop_id,arable,
--         case when ssurgo_area is null then 4*nass_area 
--              when nass_area is null then (5-arable_irrcapcl)*ssurgo_area 
--              else 4*nass_area+(5-arable_irrcapcl)*ssurgo_area*(irr_yield/max_yield) end as score 
--  from pfarm_fitness 
--  join pfarm_county_crop_fitness using (pfarm_gid) 
--  join (select crop_id,max(irr_yield) as max_yield from pfarm_crop_fitness group by crop_id) as max_yield using (crop_id)
--order by score desc;

-- This View 
create view pfarm_crop_production as 
 select year,harvested,yield as years_yield,pc.county_gid,my.crop_id,pfarm_gid,
        (pf.arable/4047)::decimal(5,0) as arable_acres,
        pf.arable_irrcapcl::decimal(5,2),
        pcf.irr_yield::decimal(7,2) as typical_irr_yield, 
        pcf.nonirr_yield::decimal(7,2) as typical_nonirr_yield,
        pcf.yldunits
 from pfarm_county pc join pfarm_fitness pf using (pfarm_gid) 
 join (select return_pfarms_trojan(county_gid,crop_id,harvested*4047) as pfarm_gid,
              county_gid,crop_id,harvested,year,yield 
       from tmp.counties x 
       join network.county c using(county_gid) 
       join tmp.nass_input n using (fips) 
       join crop_commodity cc using (commcode,praccode)
      ) as my using (pfarm_gid) 
 join pfarm_crop_fitness pcf using (pfarm_gid,crop_id) 
 order by county_gid,crop_id;

create view pfarm_actual_production as 
 select year,pfarm_gid,county_gid,crop_id,arable_acres,arable_irrcapcl,
        (CASE WHEN typical_irr_yield IS NULL 
              THEN years_yield 
              ELSE typical_irr_yield*years_yield/average_irr_yield END)::decimal(7,2) as actual_yield,
        typical_irr_yield,
	typical_nonirr_yield,
	yldunits
 from m_pfarm_crop_production 
 join (select county_gid,crop_id,
              (sum(typical_irr_yield*arable_acres)/sum(CASE WHEN typical_irr_yield is not NULL THEN arable_acres ELSE 0 END))::decimal(7,2) as average_irr_yield,
              (sum(typical_nonirr_yield*arable_acres)/sum(CASE WHEN typical_nonirr_yield is not NULL THEN arable_acres ELSE 0 END))::decimal(7,2) as average_nonirr_yield 
       from m_pfarm_crop_production 
       group by county_gid,crop_id
      ) as avg 
 using (county_gid,crop_id);
