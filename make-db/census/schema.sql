drop SCHEMA IF exists census CASCADE;
CREATE SCHEMA census;
SET search_path = census, public;

\set srid 102004
\set ON_ERROR_STOP 1
BEGIN;
--shp2pgsql -I -s 4269 -p tl_2008_04_tract00.shp census.tract00
CREATE TABLE tract00 (
gid serial PRIMARY KEY,
"statefp00" varchar(2),
"countyfp00" varchar(3),
"tractce00" varchar(6),
"ctidfp00" varchar(11) unique,
"name00" varchar(7),
"namelsad00" varchar(20),
"mtfcc00" varchar(5),
"funcstat00" varchar(1));
SELECT AddGeometryColumn('census','tract00','the_geom','4269','MULTIPOLYGON',2);
--CREATE INDEX "tract00_the_geom_gist" ON "census"."tract00" using gist ("the_geom" gist_geometry_ops);
SET search_path = census, public;
SELECT AddGeometryColumn('census','tract00','boundary',:srid,'MULTIPOLYGON',2);
update tract00 set boundary=transform(the_geom,:srid);
CREATE INDEX "tract00_boundary_gist" ON "census"."tract00" using gist ("boundary" gist_geometry_ops);
SELECT AddGeometryColumn('census','tract00','centroid',:srid,'POINT',2);
update tract00 set centroid=centroid(boundary);
CREATE INDEX "tract00_centroid_gist" ON "census"."tract00" using gist ("centroid" gist_geometry_ops);
END;




