create temp table fd as 
select qid,type,sum(marginal_addition) as amount 
from feedstock.feedstock group  by qid,type;

create temp table cats as 
select distinct type 
from fd 
where type in (
'corngrain',
'cotton_trash',
'forest',
'hec',
'idle',
'msw_dirty',
'msw_paper',
'msw_wood',
'msw_yard',
'straw',
'tallow'
);

create temp table cfd as 
select substr(qid,1,3)::varchar(3) as state,
       substr(qid,1,3)::varchar(3) as row,
type,
sum(marginal_addition)::integer as amount 
from fd
where type in (
'corngrain',
'cotton_trash',
'forest',
'hec',
'idle',
'msw_dirty',
'msw_paper',
'msw_wood',
'msw_yard',
'straw',
'tallow'
)
and substr(qid,1,1)='S'
group by substr(qid,1,3),type 
order by state,type;

create temp table sfd
as
select * from crosstab(
'select * from cfd',
'select * from cats'
) as (
state varchar(3),
corngrain integer,
cotton_trash integer,
forest integer,
hec integer,
idle integer,
msw_dirty integer,
msw_paper integer,
msw_wood integer,
msw_yard integer,
straw integer,
tallow integer);

--COPY state_feedstock to STDOUT WITH CSV HEADER FORCE QUOTE fips

-- canola_oil            |     5
-- corngrain             |  1896
-- cotton_trash          |   479
-- crop_pasture          |  2767
-- forest                | 15368
-- forest.hardwood       |  4257
-- forest.mill           |   515
-- forest.other.hardwood |  2932
-- forest.other.softwood |  2323
-- forest.softwood       |  4363
-- forest.thinnings      | 13193
-- grease                |   594
-- hec                   |  3070
-- idle                  |  2767
-- lard_cwg              |    71
-- msw_dirty             |   594
-- msw_paper             |   594
-- msw_wood              |   594
-- msw_yard              |   594
-- pastureland           |  2767
-- soybean_oil           |   173
-- straw                 |  2226
-- tallow                |    72
-- wood.urban            |  3065


