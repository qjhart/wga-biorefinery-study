\set ON_ERROR_STOP 1
BEGIN;

\set s polysis
\set t cost_per_yield_linear_fit

set search_path=:s,public;

drop table if exists :t;

create table :t as 
select substr(fips,1,2) as state_fips,
       crop_id,
       tillage_id,
       regr_count(cost,yield) as count,
       regr_slope(cost,yield) as m,
       regr_intercept(cost,yield) as b,
       regr_r2(cost,yield) as r2
from 
(
  select 
   (CASE WHEN length(''||fips::int)=4 THEN '0'||fips::int ELSE ''||fips::int END) as fips,
   crop::int as crop_id,
   tillage::int as tillage_id,
   variableco as cost,
   yield 
  from variable 
  where variableco is not null and yield <> 0
union
  select 
   '00000',
   crop::int as crop_id,
   tillage::int as tillage_id,
   variableco as cost,
   yield 
  from variable 
  where variableco is not null and yield <> 0) as foo
group by substr(fips,1,2),crop_id,tillage_id  order by state_fips,crop_id,tillage_id;

\echo The following states are not good
select distinct t.state_fips from :t t left join network.state s using(state_fips) where s is null;

\echo Making functions
CREATE OR REPLACE FUNCTION polysis.cost_per_yield(county_fips char(5),yield float,crop varchar(32),tillage varchar(2),OUT cost numeric) 
AS $$ 
select (b+m*$2)::decimal(6,2) as cost 
from polysis.cost_per_yield_linear_fit 
join polysis.tillage using (tillage_id)
join polysis.crop using (crop_id)
where state_fips=substr($1,1,2) and crop=$3 and tillage=$4
$$ 
LANGUAGE 'sql';

END;

