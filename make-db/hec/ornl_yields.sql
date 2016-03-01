\set ON_ERROR_STOP 1
BEGIN;
set search_path=hec,public;

drop table if exists hec.ornl_yields cascade;
create table hec.ornl_yields (
       qid varchar(8),
       low_min float,
       low_max float,
       low_range float,
       low_mean float,
       low_std float,
       up_min float,
       up_max float,
       up_range float,
       up_mean float,
       up_std float,
       max_low_up float,
       yetta float
);

COPY ornl_yields (qid,low_min,low_max,low_range,low_mean,low_std,up_min,up_max,up_range,up_mean,up_std,max_low_up,yetta) FROM 'hec.ornl_yields.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

update ornl_yields set qid='S'||qid;

\echo The following yields are not good
select qid from ornl_yields left join network.county c using(qid) where c is null;


END;
