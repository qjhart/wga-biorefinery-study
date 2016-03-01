\set ON_ERROR_STOP 1
BEGIN;
\set s model
set search_path=:s,public;

drop table if exists brfn;
create table brfn (
qid varchar(8),
tech varchar(16),
class varchar(16),
production float,
ag_res float,
forest float,
hec float,
msw_paper float,
msw_wood float,
msw_yard float,
ovw float,
pulpwood float,
corn float,
animal_fats float,
grease float,
seed_oils float,
mcost float,
acost float,
fpcost float,
ftcost float,
ccost float,
tcost float,
credit float);

COPY brfn ("qid","tech","class","production","ag_res","forest",
"hec","msw_paper","msw_wood","msw_yard","ovw",
"pulpwood","corn","animal_fats","grease","seed_oils","mcost",
"acost","fpcost","ftcost","ccost","tcost","credit") FROM '_results_brfn.csv' 
WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

drop table if exists links;
create table links (
run varchar(5),
source_qid varchar(8),
dest_qid varchar(8),
type varchar(16),
amount float
);

copy links(run,source_qid,dest_qid,type,amount) FROM '_results_links.csv' 
WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

END;
