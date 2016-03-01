\set ON_ERROR_STOP 1
BEGIN;
\set s results
\set t doe_runprice
\set st results.doe_runprice

set search_path=:s,results;

drop table if exists :t;

create table :st (
       r_name varchar(12),
       price real
);

COPY :t (r_name, price) FROM 'doe_runprice.csv' WITH CSV;

END;



