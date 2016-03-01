-- TMP Region is used to collect the polygons into multi-polygons.
set search_path=ssurgo,public;
--  Modified version of
-- shp2pgsql.exe -I -p soilmu_a_az649.shp ssurgo.map_unit | psql -h localhost -p 5432 -U quinn -d 
--
DROP TABLE IF EXISTS ssurgo.tmp_map_unit;
CREATE TABLE ssurgo.tmp_map_unit (
    map_unit_gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    musym character varying(6),
    mukey character varying(30),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POLYGON'::text) OR (the_geom IS NULL)))
);

SELECT DropGeometryColumn('ssurgo','map_unit','boundary');

DROP TABLE IF EXISTS ssurgo.map_unit cascade;
CREATE TABLE ssurgo.map_unit (
    map_unit_gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    musym character varying(6),
    mukey character varying(30)
);

SELECT AddGeometryColumn('ssurgo','map_unit','boundary','102004','MULTIPOLYGON',2);
CREATE INDEX "map_unit_boundary_gist" ON "ssurgo"."map_unit" using gist ("boundary" gist_geometry_ops);

DROP TABLE IF EXISTS ssurgo.map_unit_poly;
CREATE TABLE ssurgo.map_unit_poly (
    map_unit_poly_gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    musym character varying(6),
    mukey character varying(30)
);

SELECT AddGeometryColumn('ssurgo','map_unit_poly','boundary','102004','POLYGON',2);
CREATE INDEX "map_unit_poly_boundary_gist" ON "ssurgo"."map_unit_poly" using gist ("boundary" gist_geometry_ops);

