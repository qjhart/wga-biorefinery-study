#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

#NOTES from PT for systematically dealing with results:
# add location of the gams output: /var/home/ncparker/doe_gams_output
# see results.sql for incorporating .csv files into the db... 

gams_out:=/home/ncparker/doe_gams_out

scenarios:=baseline maxfeed fedforest hiencrop loencrop cblend ffv badlce

fprices:=run2 run3 run4 run5 run6 run7 run8 run9 run10 run11 run12 run13 run14 run15 run16 run17 run18 run19 run20 run21 run22 run23 run24 run25 run26 run27 run28

#shps:=$(patsubst %,${out}/${schema}.%.shp,links fs_links fuel_links termvol)

define corn
r_$1.corn::${out}/r_$1.$2_corn.feed.csv ${out}/r_$1.$2_corn.tech.csv

${out}/r_$1.$2_corn.feed.csv:${db}/r_$1.corn_variance
	${PG-CSV} -c "set search_path=r_$1,public; select price,max(ag_res) over w as ag_res,max(animal_fats) over w as animal_fats,max(corngrain) over w as corngrain,max(forest) over w as forest,max(grease) over w as grease,max(hec) over w as hec,max(msw_dirty) over w as msw_dirty,max(msw_food) over w as msw_food,max(msw_paper) over w as msw_paper,max(msw_wood) over w as msw_wood,max(msw_yard) over w as msw_yard,max(ovw) over w as ovw,max(pulpwood) over w as pulpwood,max(seed_oils) over w as seed_oils from (select * from crosstab('select $2_corn,fstk_type,sum(mgge) from corn_variance group by $2_corn,fstk_type order by $2_corn,fstk_type','select distinct fstk_type from corn_variance order by 1') as ct (price float,ag_res float,animal_fats float,corngrain float,forest float,grease float,hec float,msw_dirty float,msw_food float,msw_paper float,msw_wood float,msw_yard float,ovw float,pulpwood float,seed_oils float)) as ct WINDOW w as (ORDER BY price)" > $$@

${out}/r_$1.$2_corn.tech.csv:${db}/r_$1.corn_variance
	${PG-CSV} -c "set search_path=r_$1,public; select price,max(dry_mill) over w as dry_mill,max(fame) over w as fame,max(ft_diesel) over w as ft_diesel,max(lce) over w as lce,max(wet_mill) over w as wet_mill from (select * from crosstab('select $2_corn,f_type,sum(mgge) from corn_variance group by $2_corn,f_type order by $2_corn,f_type','select distinct f_type from corn_variance order by 1') as ct (price float, dry_mill float, fame float, ft_diesel float, lce float, wet_mill float)) as ct WINDOW w as (ORDER BY price)" > $$@
endef

define carbon
r_$1.carbon::${out}/r_$1.price_w_carbon_$2.feed.csv ${out}/r_$1.price_w_carbon_$2.tech.csv

${out}/r_$1.price_w_carbon_$2.feed.csv:${db}/r_$1.carbon
	${PG-CSV} -c "set search_path=r_$1,public; select price,max(ag_res) over w as ag_res,max(animal_fats) over w as animal_fats,max(corngrain) over w as corngrain,max(forest) over w as forest,max(grease) over w as grease,max(hec) over w as hec,max(msw_dirty) over w as msw_dirty,max(msw_food) over w as msw_food,max(msw_paper) over w as msw_paper,max(msw_wood) over w as msw_wood,max(msw_yard) over w as msw_yard,max(ovw) over w as ovw,max(pulpwood) over w as pulpwood,max(seed_oils) over w as seed_oils from (select * from crosstab('select price_w_carbon_$2,fstk_type,sum(mgge) from carbon_prices group by price_w_carbon_$2,fstk_type order by price_w_carbon_$2,fstk_type','select distinct fstk_type from carbon_prices order by 1') as ct (price float,ag_res float,animal_fats float,corngrain float,forest float,grease float,hec float,msw_dirty float,msw_food float,msw_paper float,msw_wood float,msw_yard float,ovw float,pulpwood float,seed_oils float)) as ct WINDOW w as (ORDER BY price)" > $$@

${out}/r_$1.price_w_carbon_$2.tech.csv:${db}/r_$1.carbon
	${PG-CSV} -c "set search_path=r_$1,public; select price,max(dry_mill) over w as dry_mill,max(fame) over w as fame,max(ft_diesel) over w as ft_diesel,max(lce) over w as lce,max(wet_mill) over w as wet_mill from (select * from crosstab('select price_w_carbon_$2,f_type,sum(mgge) from carbon_prices group by price_w_carbon_$2,f_type order by price_w_carbon_$2,f_type','select distinct f_type from carbon_prices order by 1') as ct (price float, dry_mill float, fame float, ft_diesel float, lce float, wet_mill float)) as ct WINDOW w as (ORDER BY price)" > $$@
endef

.PHONY: scenarios
define by_scenario
.PHONY:shps
shps::${out}/$1.brfn.shp

scenarios::$1
.PHONY:$1
$1:${db}/r_$1

${db}/r_$1:${gams_out}/results_$1_brfn.put ${gams_out}/results_$1_links.put 
	sed -e "s|results_|${gams_out}/results_|" -e "s|@SCENARIO@|$1|"  results/results.sql | ${PG} -f -
	touch $$@

.PHONY:r_$1.carbon
${db}/r_$1.carbon:${db}/r_$1
	echo 'set search_path=r_$1,public;' | cat - results/carbon.sql |${PG} -f -
	touch $$@
$(foreach p,10 30 100,$(eval $(call carbon,$1,$p)))

.PHONY:r_$1.corn_variance
${db}/r_$1.corn_variance:${db}/r_$1
	echo 'set search_path=r_$1,public;' | cat - results/corn_variance.sql |${PG} -f -
	touch $$@
$(foreach p,low high,$(eval $(call corn,$1,$p)))

#THis scetion culd be used to generate tables for each price point.
#.PHONY: fprices

#fprices::$3
#.PHONY:$3
#${db}/r_$1.fprice_$3:${db}/r_$1.fprice_3
#	sed -e "s|@SCENARIO@|$1|" -e"s|@RUN@|$3" | cat - results/map_tables.sql #|${PG} -f -
#	touch $$@
#$(foreach f,$3,$(eval $(call fprice,$1,$f)))

${out}/$1.$2.brfn.shp:${out}/%.shp:${db}/%
	${pgsql2shp} -f $@ ${database} 'select d_id, f_type, sum(production) as production, location, sum(ag_res)as ag_res,sum(forest)as forest,sum(hec)as hec,sum(msw_paper)as msw_paper,sum(msw_wood)as msw_wood,sum(msw_yard)as msw_yard,sum(ovw)as ovw,sum(pulpwood)as pulpwood,sum(corn)as corn,sum(animal_fats)as animal_fats,sum(grease)as grease,sum(seed_oils)as seed_oils,sum(mcost)as mcost,avg(acost)as acost,avg(fpcost)as fpcost,avg(ftcost)as ftcost,avg(ccost)as scost ,avg(tcost)as tcost,avg(credit)as credit from $*.brfn_ct where run=$2 group by d_id, f_type, location;' 
	echo '${srid-prj}' > ${out}/$*.prj

${out}/$1.$2.fs_links.shp:${out}/%.shp:${db}/%
	${pgsql2shp} -f $@ ${database} 'select * from $*.fs_links where run=$2'

	echo '${srid-prj}' > ${out}/$1.prj
#${shps}:${out}/%.shp:${db}/%
#	${pgsql2shp} -f $@ ${database} $*
#	echo '${srid-prj}' > ${out}/$*.prj

endef

$(foreach s,${scenarios},$(eval $(call by_scenario,$s)))
