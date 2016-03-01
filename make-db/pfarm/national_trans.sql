create or replace view cost_by_distance as 
select src_qid,dest_qid,ST_Distance(s.centroid,d.centroid)/1000 as dis,
cost,road_mi*1.609 as road_km,road_hrs,rail_mi*1.609 as rail_km,water_mi*1.609 as water_km 
from network.feedstock_odcosts c 
join (select qid,centroid from network.place union select qid,centroid from network.county) as s 
on (c.src_qid = s.qid) 
join network.place d on (c.dest_qid = d.qid);

drop table cost_by_distance_histogram ;
create table cost_by_distance_histogram as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from 
(
select 10*(dis/10)::int as idis,* 
from cost_by_distance 
where dis!=0 ) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_road_only ;
create table cost_by_distance_histogram_road_only as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance 
where rail_km=0 and water_km=0 and dis !=0) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_rail_only ;
create table cost_by_distance_histogram_rail_only as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance 
where rail_km != 0 and water_km=0 and dis != 0) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_road_rail ;
create table cost_by_distance_histogram_road_rail as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance 
where water_km=0 and dis !=0) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_road_water ;
create table cost_by_distance_histogram_road_water as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance
where rail_km=0 and dis !=0) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_county ;
create table cost_by_distance_histogram_county as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance where src_qid like 'S%' and dis!=0) as n 
group by idis order by idis;

drop table cost_by_distance_histogram_muni ;
create table cost_by_distance_histogram_muni as select idis,count(*),
avg(cost) as cost,stddev(cost) as cost_sdv, 
avg(road_hrs) as road_hrs, stddev(road_hrs) as road_hrs_sdv,
avg(road_km) as road,stddev(road_km) as road_sdv,
avg(rail_km) as rail, stddev(rail_km) as rail_sdv, 
avg(water_km) as water, stddev(water_km) as water_sdv ,
avg(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr, 
stddev(case when road_hrs=0 then NULL else road_km/road_hrs end) as km_per_hr_sdv,
avg(road_km/dis) as road_wind, stddev(road_km/dis) as road_wind_sdv,
avg(rail_km/dis) as rail_wind, stddev(rail_km/dis) as rail_wind_sdv,
avg(water_km/dis) as water_wind, stddev(water_km/dis) as water_wind_sdv
from (select 10*(dis/10)::int as idis,* from cost_by_distance where src_qid like 'D%' and dis !=0) as n 
group by idis order by idis;

