drop SCHEMA IF exists cmz CASCADE;
CREATE SCHEMA cmz;
SET search_path = cmz, public;

delete from spatial_ref_sys where srid=999999;
insert into spatial_ref_sys (srid,auth_name,auth_srid,srtext,proj4text)
values (
999999,'quinn',999999,
'PROJCS["NAD_1927_Albers",GEOGCS["GCS_North_American_1927",DATUM["D_North_American_1927",SPHEROID["Clarke_1866",6378206.4,294.9786982]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Albers"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-96.0],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["Latitude_Of_Origin",23.0],UNIT["Meter",1.0]]',
'+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0 +lon_0=-96 +x_0=0 +y_0=0 +ellps=clrk66 +datum=NAD27 +units=m +no_defs');

create table farm_production_region (
fpr_id serial primary key,
region varchar(32)
);

create temp table foo (
state varchar(32),
region varchar(32)
);
COPY foo (state,region) from STDIN WITH CSV HEADER QUOTE AS '"';
"STATE","FARM_PRODUCTION_REGION"
"Alabama","Southeast"
"Alaska","Pacific"
"Arizona","Mountain"
"Arkansas","Delta States"
"California","Pacific"
"Colorado","Mountain"
"Connecticut","Northeast"
"Delaware","Northeast"
"District of Columbia",\N
"Florida","Southeast"
"Georgia","Southeast"
"Hawaii","Pacific"
"Idaho","Mountain"
"Illinois","Corn Belt"
"Indiana","Corn Belt"
"Iowa","Corn Belt"
"Kansas","Northern Plains"
"Kentucky","Appalachia"
"Louisiana","Delta States"
"Maine","Northeast"
"Maryland","Northeast"
"Massachusetts","Northeast"
"Michigan","Lake States"
"Minnesota","Lake States"
"Mississippi","Delta States"
"Missouri","Corn Belt"
"Montana","Mountain"
"Nebraska","Northern Plains"
"Nevada","Mountain"
"New Hampshire","Northeast"
"New Jersey","Northeast"
"New Mexico","Mountain"
"New York","Northeast"
"North Carolina","Appalachia"
"North Dakota","Northern Plains"
"Ohio","Corn Belt"
"Oklahoma","Southern Plains"
"Oregon","Pacific"
"Pennsylvania","Northeast"
"Rhode Island","Northeast"
"South Carolina","Southeast"
"South Dakota","Northern Plains"
"Tennessee","Appalachia"
"Texas","Southern Plains"
"Utah","Mountain"
"Vermont","Northeast"
"Virginia","Appalachia"
"Washington","Pacific"
"West Virginia","Appalachia"
"Wisconsin","Lake States"
"Wyoming","Mountain"
\.

insert into farm_production_region (region) select distinct region from foo order by region;

create table fpr_state as select fpr_id,state_fips from foo join network.state using (state) join farm_production_region using (region);

\echo The following states are not good
select distinct state from foo left join (select state from network.state join fpr_state using (state_fips)) as f using (state) where f is null;