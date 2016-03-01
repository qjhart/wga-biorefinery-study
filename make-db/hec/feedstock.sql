\set ON_ERROR_STOP 1
BEGIN;
set search_path=hec,public;

drop table if exists available_land cascade;
create table available_land as 
select qid,2007 as year,
       ('0'||regexp_replace(d1.data,'[^0-9]','','g'))::integer
       as crop_pasture,
       ('0'||regexp_replace(d2.data,'[^0-9]','','g'))::integer
       as crop_idle,
       ('0'||regexp_replace(d3.data,'[^0-9]','','g'))::integer
       as crop_fallow,
       ('0'||regexp_replace(d4.data,'[^0-9]','','g'))::integer
       as permanent_pasture,
       ('0'||regexp_replace(d5.data,'[^0-9]','','g'))::integer
       as pastureland
from 
nass.ch2table8 d1 join 
nass.ch2table8 d2 using (qid) join
nass.ch2table8 d3 using (qid) join
nass.ch2table8 d4 using (qid) join
nass.ch2table8 d5 using (qid) 
where 
d1.row=84 and 
d2.row=92 and
d3.row=100 and
d4.row=116 and
d5.row=124
union
select qid,2002 as year,
       ('0'||regexp_replace(d1.data,'[^0-9]','','g'))::integer
       as crop_pasture,
       ('0'||regexp_replace(d2.data,'[^0-9]','','g'))::integer
       as crop_idle,
       ('0'||regexp_replace(d3.data,'[^0-9]','','g'))::integer
       as crop_fallow,
       ('0'||regexp_replace(d4.data,'[^0-9]','','g'))::integer
       as permanent_pasture,
       ('0'||regexp_replace(d5.data,'[^0-9]','','g'))::integer
       as pastureland
from 
nass.ch2table8 d1 join 
nass.ch2table8 d2 using (qid) join
nass.ch2table8 d3 using (qid) join
nass.ch2table8 d4 using (qid) join
nass.ch2table8 d5 using (qid) 
where 
d1.row=85 and 
d2.row=93 and
d3.row=101 and
d4.row=117 and
d5.row=125
;

drop table if exists hec.feedstock cascade;
create table hec.feedstock as 
select 
qid,'no_past_low'::varchar(12) as scenario,
'hec'::varchar(12) as type,
0.0::float as price,
(crop_idle*0.25+crop_pasture*0.25) as marginal_acres,
(crop_idle*0.25+crop_pasture*0.25)*up_mean/2.24 as marginal_addition
from hec.available_land join hec.ornl_yields using (qid)
where year=2007 and up_mean > 0
UNION
select
qid,'no_past_high' as scenario,
'hec'::varchar(12) as type,
0.0::float as price,
(crop_idle*0.5+crop_pasture*0.5) as marginal_acres,
(crop_idle*0.5+crop_pasture*0.5)*up_mean/2.24 as marginal_addition
from hec.available_land join hec.ornl_yields using (qid)
where year=2007 and up_mean > 0
UNION
select
qid,'past_low' as scenario,
'hec'::varchar(12) as type,
0.0::float as price,
(crop_idle*0.25+crop_pasture*0.25+pastureland*0.05)
as marginal_acres,
(crop_idle*0.25+crop_pasture*0.25+pastureland*0.05)*up_mean/2.24 
as marginal_addition
from hec.available_land join hec.ornl_yields using (qid)
where year=2007 and up_mean > 0
UNION
select
qid,'past_high' as scenario,
'hec'::varchar(12) as type,
0.0::float as price,
(crop_idle*0.50+crop_pasture*0.5+pastureland*0.1)
as marginal_acres,
(crop_idle*0.50+crop_pasture*0.5+pastureland*0.1)*up_mean/2.24
as marginal_addition
from hec.available_land  join hec.ornl_yields using (qid)
where year=2007 and up_mean > 0;

delete from hec.feedstock where marginal_addition = 0;

update hec.feedstock f set price=
(COALESCE(
polysis.cost_per_yield(substr(f.qid,2,5),up_mean/2.24,'switchgrass','NT'),
         polysis.cost_per_yield('00000',up_mean/2.24,'switchgrass','NT'))
+inl.land_rent(substr(f.qid,2,5),2017))/(up_mean/2.24)
from hec.ornl_yields y 
where y.qid=f.qid;

END;
