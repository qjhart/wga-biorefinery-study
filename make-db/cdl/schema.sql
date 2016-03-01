drop SCHEMA cdl if exists;
CREATE SCHEMA cdl;
SET search_path = cdl, pg_catalog;
SET default_with_oids = false;

CREATE TABLE class (
    class_name character varying(32) primary key
);

-- taken from the data itself so could be wrong.
