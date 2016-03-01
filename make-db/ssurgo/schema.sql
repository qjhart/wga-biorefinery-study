DROP SCHEMA ssurgo CASCADE;
CREATE SCHEMA ssurgo;
SET search_path = ssurgo, public, pg_catalog;

CREATE TABLE ssurgo.survey_area (
    gid serial primary key,
    areasymbol character varying(20),
    spatialver integer,
    lkey character varying(30)
);
SELECT AddGeometryColumn('ssurgo','survey_area','boundary',102004,'MULTIPOLYGON',2);
CREATE INDEX "survey_area_extent_gist" ON "ssurgo"."survey_area" using gist ("boundary" gist_geometry_ops);

