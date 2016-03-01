\set ON_ERROR_STOP 1
BEGIN;
\set s model
\set t fuel_transport_results
\set st model.fuel_transport_results

set search_path=:s,public;

drop table if exists :st;
create table :st (
       src_qid varchar(8),
       dest_qid varchar(8),
       type varchar(32),
       amount float
);       

COPY :st (src_qid,dest_qid,type,amount) FROM 'fuel_transport_results.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

select addgeometrycolumn('model','fuel_transport_results','route',102004,'LINESTRING',2);

update :st set route=makeline(s.centroid,d.centroid) from network.place s,network.place d where s.qid=src_qid and d.qid=dest_qid;

update :st set route=makeline(s.centroid,d.centroid) from network.county s,network.place d where s.qid=src_qid and d.qid=dest_qid;

\echo The following routes are empty
select src_qid,dest_qid from :st s where route is Null;

END;
