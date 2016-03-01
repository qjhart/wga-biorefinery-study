drop SCHEMA IF exists vmt CASCADE;
CREATE SCHEMA vmt;
SET search_path = vmt, census, public;

\set ON_ERROR_STOP 1
BEGIN;

create table vmt_by_census (
       ctidfp00 varchar(11),
       state_fips varchar(2),
       county_fips varchar(3),
       fips varchar(5),
       total_vmt float,
       growth float,
       vmt_2015 float
);

COPY vmt_by_census (ctidfp00,state_fips,county_fips,fips,total_vmt,growth,vmt_2015) FROM 'vmt_by_census_tract.csv' WITH DELIMITER AS ',' CSV HEADER;

update vmt_by_census set ctidfp00='0'||ctidfp00 where length(ctidfp00)=10;
update vmt_by_census set state_fips='0'||state_fips where length(state_fips)=1;
update vmt_by_census set county_fips='00'||county_fips where length(county_fips)=1;
update vmt_by_census set county_fips='0'||county_fips where length(county_fips)=2;
update vmt_by_census set fips='0'||fips where length(fips)=4;

create table tract00_closest_terminal as
select ctidfp00,qid,distance 
from (select ctidfp00,p.qid,ST_Distance(c.centroid,p.centroid) as distance,
             min(ST_Distance(c.centroid,p.centroid)) OVER (partition by ctidfp00) as min 
      from census.tract00 c,
      (select distinct qid,centroid from refineries.terminals t join network.place p using (qid)) as p
     ) as m 
where min=distance;

create view terminal_vmt as 
select qid,sum(total_vmt) as total_vmt,sum(vmt_2015) as vmt_2015 
from tract00_closest_terminal join vmt_by_census using (ctidfp00) group by qid;

END;



