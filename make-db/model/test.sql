\set r REGION
set search_path=:r,public;

\echo Number of sources per county
select region,state,state_fips,count 
from (select substring(source from 2 for 2) as state_fips,count(*) 
      from source_list 
      group by substring(source from 2 for 2)) as c 
join model.region_states using (state_fips) 
join network.state using (state_fips) 
where region != 'national' 
order by region,state;

\echo List without Supplies
select * from source_list p left join supply s using (source) where s is NULL;
\echo Supplies not in List
select distinct source from source_list p right join supply s using (source) where p is NULL;

\echo Prices with no supply

select * from price p left join supply s using (price_id) where s is NULL;
\echo Supply w/ no prices
select * from price p right join supply s using (price_id) where p is NULL;

\echo Dry feedstock w/ no connectors
select type,source from source_list join (select distinct type,source from supply where type not in ('grease','tallow','lard_cwg','canola_oil','soybean_oil')) as foo using (source) left join (select distinct src_qid as source from src2refine) as f using (source) where f is null order by type,source;

\echo Liquid stock w/ no connectors
select type,source from source_list join (select distinct type,source from supply where type in ('grease','tallow','lard_cwg','canola_oil','soybean_oil')) as foo using (source) left join (select distinct src_qid as source from src2refine_liq) as f using (source) where f is null order by type,source;

\echo Connectors w/ no Supplies 
select * from source_list p 
right join (select distinct src_qid as source from src2refine) as s 
using (source) where p is NULL;

\echo Refine w/ no connectors
select * from refine p 
left join (select distinct dest_qid as qid from src2refine) as s 
using (qid) where s is NULL;

\echo Connectors w/ no Refine 
select * from refine p 
right join
(select distinct dest_qid as qid from src2refine) as s 
using (qid) where p is NULL;



