\set ON_ERROR_STOP 1
--BEGIN;
drop schema if exists billion_ton cascade;
create schema billion_ton;
set search_path=billion_ton,public;

create table code (
col text,
code text,
descr text
);

\COPY code (col,code,descr) FROM 'codes.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

create table supply (
year integer,
scenario varchar(32),
basis varchar(32),
feedstck varchar(32),
fcode varchar(6),
produnit varchar(3),
price float,
production float);

\COPY supply (year,scenario,basis,feedstck,fcode,produnit,price,production) FROM 'WGA-Engy-BLY+EC1_BLT.dat' WITH DELIMITER AS ';' QUOTE AS '"' CSV HEADER
\COPY supply (year,scenario,basis,feedstck,fcode,produnit,price,production) FROM 'WGA-Frst.dat' WITH DELIMITER AS ';' QUOTE AS '"' CSV HEADER

update supply set fcode='S'||fcode;
alter table supply rename fcode to qid;
create index supply_qid on supply(qid);



