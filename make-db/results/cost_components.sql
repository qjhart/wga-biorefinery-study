drop table if exists t_links;
create temp table t_links as 
select * from links where source_id not like 'D%';

update t_links set source_id='D'||substr(source_id,2) 
where source_id like 'M%';

drop table if exists model_feedstock_use;
create temp table model_feedstock_use as 
select l.m_run,source_id,f_type,fstk_type,
       sum(quant_tons*fraction) as total_tons
from t_links l 
join 
(select run as m_run,d_id as dest_id,f_type,fstk_type,
       tons/sum(tons) over w as fraction,sum(tons) over w as tons 
 from 
 ( select run,d_id,f_type,fstk_type,sum(quant_mgy) as tons 
   from brfn 
   join (select distinct fstk_type from brfn_feedstock) as f 
   using (fstk_type) 
   group by run,d_id,f_type,fstk_type
 )  as t 
 window w as (partition by run,d_id,fstk_type)
) as b
on (l.m_run=b.m_run and l.dest_id=b.dest_id and l.type=b.fstk_type)
group by l.m_run,source_id,f_type,fstk_type;

drop table if exists availability;
create temp table availability as 
select qid as source_id,
       price,fstk_type,marginal_addition,
       sum(marginal_addition) over w as cumulative_addition 
from 
(select qid,price,fstk_type,sum(marginal_addition) as marginal_addition
from feedstock.feedstock 
join brfn_feedstock 
using (type) 
join model.test_feedstock_scenario 
using (type,scenario) group by qid,price,fstk_type) as f
window w as (partition by qid,fstk_type order by price) ;

drop table if exists model_feedstock_cost;
create temp table model_feedstock_cost as 
select m_run,source_id,fstk_type,total_tons,
       sum(marginal_cost) as total_cost 
from (
 select m_run,source_id,fstk_type,
 CASE WHEN (total_tons>=cumulative_addition) 
      THEN price*marginal_addition 
      WHEN (total_tons>=cumulative_addition-marginal_addition) 
      THEN price*(total_tons-(cumulative_addition-marginal_addition)) 
      ELSE 0 
 END as marginal_cost,
       price,marginal_addition,cumulative_addition,total_tons 
 from model_feedstock_use 
 join availability 
 using (source_id,fstk_type)
) as f 
group by m_run,source_id,fstk_type,total_tons;

drop table if exists model_feedstock_destination_cost;
create temp table model_feedstock_destination_cost as 
select run,d_id,fstk_type,
       avg(total_cost/(total_tons*gal_per_bdt*energy_density_gge_per_gal)) 
       as cost_per_gge 
from brfn 
join t_links l on (d_id=dest_id  and fstk_type=l.type and run=m_run) 
join model_feedstock_cost using (source_id,fstk_type,m_run) 
join model.conversion_efficiency e on (f_type=e.tech and fstk_type=e.type) 
join model.technology t on (f_type=t.tech) 
group by run,d_id,fstk_type;

-- Make the crosstab

drop table if exists model_feedstock_destination_cost_run_dest;
create temp table model_feedstock_destination_cost_run_dest 
(
 rd_id serial primary key,
 run varchar(8),
 d_id varchar(24)
);

insert into model_feedstock_destination_cost_run_dest (run,d_id) 
select distinct run,d_id from model_feedstock_destination_cost;

drop table if exists model_feedstock_destination_cost_ct;
create temp table model_feedstock_destination_cost_ct as 
select run,d_id,ag_res,animal_fats,corngrain,forest,
       grease,hec,msw_dirty,msw_food,
       msw_paper,msw_wood,msw_yard,ovw,pulpwood,seed_oils
from crosstab('
 select rd_id,fstk_type,cost_per_gge 
 from model_feedstock_destination_cost 
 join model_feedstock_destination_cost_run_dest 
 using (run,d_id) 
 order by rd_id,fstk_type',
 'select distinct fstk_type 
  from model_feedstock_destination_cost 
  order by 1'
) as ct (
 rd_id integer,
 ag_res float, animal_fats float, corngrain float, forest float,
 grease float, hec float, msw_dirty float, msw_food float,
 msw_paper float, msw_wood float, msw_yard float, ovw float,
 pulpwood float, seed_oils float
)
join model_feedstock_destination_cost_run_dest using (rd_id)
order by run,d_id;



