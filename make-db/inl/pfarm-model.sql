set search_path=inl,pfarm,public;
SET default_with_oids = false;

create table inl.pfarm_refinery_centroids ( pfarm_gid integer , gid integer references network.place(gid));

COPY inl.pfarm_refinery_centroids (pfarm_gid) FROM STDIN;
2304
4068
7626
16213
\.

create temp table pcd as select pfarm_gid,c.gid,distance(c.centroid,centroid(boundary)) from pfarm_centroids e join pfarm.pfarm_county using (pfarm_gid),network.city c where ST_DWithin(c.centroid,centroid(boundary),10000);

update pfarm_centroids c set gid=f.gid from (select p.pfarm_gid,p.gid from pcd p join (select pfarm_gid,min(distance) as min from pcd group by pfarm_gid) as m on (p.pfarm_gid=m.pfarm_gid and distance=m.min)) as f where (c.pfarm_gid=f.pfarm_gid);

create or replace view inl.pfarm_dest as select v.id,v.point from inl.pfarm_refinery_centroids p join network.place c using (gid) left join network.vertex v on (v.point=c.centroid);

create view pfarm_source as select v.id,v.point from pfarm.m_pfarm_actual_production p join pfarm.pfarm_county_centroid c on (p.pfarm_gid=c.gid and p.year=2007) join network.vertex v on (v.point=c.centroid);



drop table if exists inl.edge;
create table inl.edge as select e.id,source,target,miles,hours02,(inl.transportation_cost('bale',c.fips,2010,miles,hours02)).*,1.17*hours02+0.47*miles as wga from network.edge e join network.vertex v on (e.source=v.id) join network.county c on (ST_within(v.point,c.boundary));

select addgeometrycolumn('inl','edge','route',102004,'LINESTRING',2);
update inl.edge set route=makeline(v1.point,v2.point) from network.vertex v1,network.vertex v2 where (source=v1.id) and (target=v2.id);


--create table inl.shortest_path as select v.id as src,d.id as dest,(shortest_path('select id,source,target,total as cost from inl.edge'::text,v.id,d.id,false,false)).* from pfarm.m_pfarm_actual_production p join pfarm.pfarm_county_centroid c on (p.pfarm_gid=c.gid and p.year=2007) join network.vertex v on (v.point=c.centroid),(select v.id from pfarm_refinery_centroids p join network.city c using (gid) left join network.vertex v on (v.point=c.centroid)) as d;


--create table inl.shortest_path_sum select src,dest,sum(cost) as cost from inl.shortest_path group by src,dest;

--create table inl.shortest_path_sum_shortest as  select dest,min(cost) from inl.shortest_path_sum group by dest;


create view pfarm.pfarm_irr_harvest_cost as 
SELECT 
p.year, p.pfarm_gid,p.county_gid,c.fips,p.crop_id,p.arable_acres,p.actual_irr_yield,crop_yldunit_bdt.bdt,r.residue,(inl.harvest_cost(c.fips,p.year,p.arable_acres,p.actual_irr_yield*crop_yldunit_bdt.bdt,r.residue)).*
FROM m_pfarm_actual_production p 
JOIN pfarm_crop_residue r USING (pfarm_gid, crop_id) 
JOIN crop_yldunit_bdt USING (crop_id) 
JOIN network.county c using (county_gid);

create table pfarm.m_pfarm_irr_harvest_cost as select * from pfarm.pfarm_irr_harvest_cost;

create view pfarm.pfarm_nonirr_harvest_cost as 
SELECT 
p.year, p.pfarm_gid, p.county_gid,c.fips,p.crop_id,p.arable_acres,p.actual_nonirr_yield,crop_yldunit_bdt.bdt,r.residue,(inl.harvest_cost(c.fips,p.year,p.arable_acres,p.actual_nonirr_yield*crop_yldunit_bdt.bdt,r.residue)).*
FROM m_pfarm_actual_production p 
JOIN pfarm_crop_residue r USING (pfarm_gid, crop_id) 
JOIN crop_yldunit_bdt USING (crop_id) 
JOIN network.county c using (county_gid);

create table pfarm.m_pfarm_nonirr_harvest_cost as select * from pfarm.pfarm_nonirr_harvest_cost;
