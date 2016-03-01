\set s polysis
\set ON_ERROR_STOP 1
BEGIN;

drop SCHEMA IF exists :s CASCADE;
CREATE SCHEMA :s;
SET search_path = :s, pg_catalog;
SET default_with_oids = false;

CREATE TABLE crop (
       crop_id int primary key,
       crop varchar(32)
);

COPY crop FROM STDIN WITH DELIMITER AS ':';
1:corn
2:sorghum
3:oats
4:barley
5:wheat
6:soybeans
7:cotton
8:rice
9:switchgrass
12:hay
\.

CREATE TABLE tillage (
       tillage_id int primary key,
       tillage varchar(32)
);

COPY tillage FROM STDIN WITH DELIMITER AS ':';
1:CT
2:RT
3:NT
\.

END;
