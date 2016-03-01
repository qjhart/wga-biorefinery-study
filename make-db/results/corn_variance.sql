drop table if exists corn_variance;
create table corn_variance as
select price_point,f_type,fstk_type,sum(quant_mgy*gal_per_bdt*energy_density_gge_per_gal)/1000 as Mgge,
price_point-0.62 as low_corn,
price_point+1.01 as high_corn 
from brfn join model.runs m using(run) 
join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) 
join model.technology using (tech)
where type='corngrain'
group by price_point,f_type,fstk_type 
UNION
select price_point,f_type,fstk_type,sum(quant_mgy*gal_per_bdt*energy_density_gge_per_gal)/1000 as Mgge,
price_point as low_corn,
price_point as high_corn 
from brfn join model.runs m using(run) 
join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) 
join model.technology using (tech)
where type != 'corngrain'
group by price_point,f_type,fstk_type 
order by price_point,f_type,fstk_type;


-- select * from crosstab('select price,fstk_type,sum(quant_mgy*energy_density_gge_per_gal) as gge from (select 1.2+0.1*a as price from generate_series(0,((5.5-1.2)/0.1)::integer) as a) as p join carbon_prices c on (price_w_carbon_100 < price) join model.technology on (f_type=tech) group by price,fstk_type order by price,fstk_type','select distinct fstk_type from carbon_prices order by 1') as ct(price float,ag_res float,animal_fats float,corngrain float,forest float,grease float,hec float,msw_dirty float,msw_food float,msw_paper float,msw_wood float,msw_yard float,ovw float,pulpwood float,seed_oils float);

