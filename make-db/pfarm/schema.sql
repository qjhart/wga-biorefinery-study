drop SCHEMA IF EXISTS pfarm CASCADE;
CREATE SCHEMA pfarm;

SET search_path = pfarm, public,pg_catalog;
SET default_with_oids = false;

-- create table pfarm (
--       pfarm_gid serial primary key,
--       box geometry
-- );
-- select addgeometrycolumn('pfarm','pfarm','boundary',102004,'POLYGON',2);


create table pfarm_county (
       pfarm_gid serial primary key,
       county_gid integer references network.county(county_gid),
       box geometry
);
select addgeometrycolumn('pfarm','pfarm_county','boundary',102004,'POLYGON',2);
create index pfarm_county_boundary_gist on pfarm_county using gist("boundary" gist_geometry_ops);

create table pfarm_map_unit_poly (
       county_gid integer references network.county(county_gid),
       pfarm_gid integer references pfarm.pfarm_county(pfarm_gid),
       map_unit_poly_gid integer references ssurgo.map_unit_poly(map_unit_poly_gid),
       mukey varchar(30)
);
select addgeometrycolumn('pfarm','pfarm_map_unit_poly','boundary',102004,'MULTIPOLYGON',2);

create table pfarm_cdl_map_unit_poly (
       county_gid integer references network.county(county_gid),
       pfarm_gid integer references pfarm.pfarm_county(pfarm_gid),
       map_unit_poly_gid integer references ssurgo.map_unit_poly(map_unit_poly_gid),
       gridcode integer,
       class_name varchar(254),
       mukey varchar(30)
);
select addgeometrycolumn('pfarm','pfarm_cdl_map_unit_poly','boundary',102004,'MULTIPOLYGON',2);

CREATE TABLE crop (
    crop_id integer primary key,
    name varchar(32),
    description character varying(255)
);
COPY crop from STDIN delimiter as '|';
1|Corn|Corn
3|Corn Silage|Corn Silage
2|Winter Wheat|Winter Wheat (missing dual crops?)
\.

CREATE TABLE crop_class_name (
    crop_id integer references crop(crop_id),
    class_name varchar(32)
);
COPY crop_class_name from STDIN delimiter as '|';
1|Corn
1|Dbl. Crop Oats/Corn
1|Dbl. Crop WinWht/Corn
3|Corn
3|Dbl. Crop Oats/Corn
3|Dbl. Crop WinWht/Corn
2|Dbl. Crop WinWht/Corn
2|Win. Wht./Soyb. Dbl. Cropped
2|Winter Wheat
\.

CREATE TABLE crop_cropname (
    crop_id integer references crop(crop_id),
    cropname varchar(32)
);
COPY crop_cropname from STDIN delimiter as '|';
1|Corn
3|Corn silage
2|Wheat
2|Winter wheat
2|Winter wheat-fallow
2|Wheat (October-March)
\.

--1|Sweet corn

CREATE TABLE crop_commodity (
    crop_id integer references crop(crop_id),
    commcode integer references nass.commodity(commcode),
    praccode integer references nass.practice(praccode)
);
COPY crop_commodity from STDIN delimiter as '|';
1|11199199|9
3|11199299|9
2|10119999|9
\.


-- Views

create or replace view  pfarm_fitness as 
  select pfarm_gid,
         case when (sum(area(boundary))>1000000) 
              then 1000000::decimal(10,0) 
              else sum(area(boundary))::decimal(10,0) end as arable,
         sum(comppct_r*irrcapcl::integer/100.0*area(boundary))/sum(comppct_r/100.0*area(boundary)) as arable_irrcapcl,
         sum(comppct_r*nirrcapcl::integer/100.0*area(boundary))/sum(comppct_r/100.0*area(boundary)) as arable_nirrcapcl 
 from pfarm.pfarm_cdl_map_unit_poly join component c using (mukey) 
 where class_name not like 'NLCD%' 
 group by pfarm_gid having sum(area(boundary))>100000 
 order by arable;

create or replace view pfarm_crop_fitness as
select pfarm_gid,crop_id,nass.area as nass_area,
                         ssurgo.area as ssurgo_area,
                         ssurgo.irr_yield,
			 ssurgo.nonirr_yield,
			 ssurgo.yldunits
                         from
 (select pfarm_gid,crop_id,
         sum(area(boundary))::decimal(10,0) as area 
  from pfarm.pfarm_cdl_map_unit_poly join pfarm.crop_class_name using(class_name) 
  group by pfarm_gid,crop_id having sum(area(boundary)) > 10000
 ) as nass 
full outer join 
( select pfarm_gid,crop_id,yldunits,
         sum(area(boundary))::decimal(10,0) as area,
         avg(irryield_r) as irr_yield,
         avg(nonirryield_r) as nonirr_yield
  from pfarm.pfarm_cdl_map_unit_poly join ssurgo.mucropyld using (mukey)
           join pfarm.crop_cropname using(cropname)
  group by pfarm_gid,crop_id,yldunits having sum(area(boundary)) > 10000
) as ssurgo 
using (pfarm_gid,crop_id);

-- pfarm_crop_residue is used to 
create or replace view pfarm_crop_residue as
select m.pfarm_gid,1 as crop_id,sum(cc_res*area)/sum(area) as residue from ( select pfarm_gid,county_gid,musym,sum(area(p.boundary)) as area
  from pfarm.pfarm_cdl_map_unit_poly p join ssurgo.map_unit using (mukey)
  group by pfarm_gid,county_gid,musym
) as m 
join 
(select county_gid,musym,cc_res from pfarm.required_residue join network.county using (fips) ) as r
using (county_gid,musym)
group by pfarm_gid;

-- pfarm_actual_biomass calculates the actual amount of biomass
-- available for each pfarm,crop_id, and year.  This calculates the
-- total amount of residue from the crop and then subtracts the
-- residue required to avoid soil erosion.
create or replace view pfarm_actual_biomass as 
select year,pfarm_gid,county_gid,crop_id,
       greatest(actual_irr_yield*(bdt)-residue,0) as actual_irr_biomass,
       greatest(actual_nonirr_yield*(bdt)-residue,0) as actual_nonirr_biomass 
from m_pfarm_actual_production p 
join pfarm_crop_residue r using (pfarm_gid,crop_id) 
join crop_yldunit_bdt using (crop_id);


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
              when nass_area is null then (5-arable_nirrcapcl)*ssurgo_area*(nonirr_yield/max_nonirr_yield)
              else 4*nass_area+(5-arable_nirrcapcl)*ssurgo_area*(nonirr_yield/max_nonirr_yield) end as nonirr_score 
  from pfarm_fitness 
  join pfarm_crop_fitness using (pfarm_gid) 
  join (select crop_id,max(irr_yield) as max_irr_yield,max(nonirr_yield) as max_nonirr_yield from pfarm_crop_fitness group by crop_id) as max_yield using (crop_id)
order by score desc;


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
       from pfarm.example_counties x 
       join network.county c using(fips) 
       join tmp.nass_input n using (fips) 
       join crop_commodity cc using (commcode,praccode)
      ) as my using (pfarm_gid) 
 join pfarm_crop_fitness pcf using (pfarm_gid,crop_id) 
 order by county_gid,crop_id;

create or replace view pfarm_actual_production as 
 select year,pfarm_gid,county_gid,crop_id,arable_acres,arable_irrcapcl,
        (CASE WHEN typical_irr_yield IS NULL 
              THEN years_yield 
              ELSE typical_irr_yield*years_yield/average_irr_yield END)::decimal(7,2) as actual_irr_yield,
        (CASE WHEN typical_nonirr_yield IS NULL 
              THEN years_yield 
              ELSE typical_nonirr_yield*years_yield/average_nonirr_yield END)::decimal(7,2) as actual_nonirr_yield,
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

