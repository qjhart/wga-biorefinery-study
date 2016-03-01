drop SCHEMA IF EXISTS inl CASCADE;
CREATE SCHEMA inl;

SET search_path = inl, pfarm, public,pg_catalog;
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

