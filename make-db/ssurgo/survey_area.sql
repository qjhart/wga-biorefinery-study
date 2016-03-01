-- SET search_path = ssurgo, pg_catalog;

-- TMP Region is used to collect the polygons into multi-polygons.
DROP TABLE if EXISTS ssurgo.tmp_survey_area;
CREATE TABLE ssurgo.tmp_survey_area (
    survey_area_gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    lkey character varying(30),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POLYGON'::text) OR (the_geom IS NULL)))
);

DROP TABLE if EXISTS ssurgo.survey_area CASCADE;
CREATE TABLE ssurgo.survey_area (
    survey_area_gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    lkey character varying(30)
);
SELECT AddGeometryColumn('ssurgo','survey_area','boundary',102004,'MULTIPOLYGON',2);
CREATE INDEX "survey_area_boundary_gist" ON "ssurgo"."survey_area" using gist ("boundary" gist_geometry_ops);

