#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif


web:=/var/www

bts:=/home/ncparker/bts
scenarios:=base50 base60 base40 pes60 opt50 opt40 opt60 pes50 pes40

files:=fuel_links.csv feedstock_links.put brfn.put biomass_consumed.put

#terminal_cost.csv terminal_fips.csv terminal_list.csv feedstock_composition_bts.csv  terminal_vmt_fraction.csv lipids.csv plot_list_bts.csv
# one for each PL40, PL50 and PL60
feedstock_inputs:=$(patsubst %,${bts}/inputs/2022%_PL50.csv,_BTS_ag_supply forest_nofed _pulpwood _wood_waste) ${bts}/inputs/supply_corn.csv


# BTS data
#db::${db}/bts
#	${PG} -c 'create schema bts;';

$(patsubst %,${bts}/results_BTS_%_fuel_links.csv,${scenarios}):${bts}/results_BTS_%_fuel_links.csv:${bts}/results_BTS_%_fuel_links.put
	perl -n -e 'sub rt {my $$f=shift; $$f=~s/\s+$$//;$$f;};' -e '/(.{13})(.{4})(.{12})(.{12})(.{18})(.{6})/; printf "\"%s\",%0.2f,\"%s\",\"%s\",\"%s\",%0.2f\n",rt($$1),$$2,rt($$3),rt($$4),rt($$5),$$6' $< > $@  

.PHONY: scenarios shps kml

shps::${out}/bts/census.tract00.shp ${out}/bts/vmt.csv
${out}/bts/census.tract00.shp:
	${pgsql2shp} -f $@ ${database} "select statefp00,countyfp00,tractce00,  ctidfp00,  name00, boundary from census.tract00"

${out}/bts/vmt.csv:
	${PG-CSV} -c "select * from vmt.vmt_by_census" > $@

define by_scenario

scenarios::$1
.PHONY:$1
db::${db}/bts_$1
$1:${db}/bts_$1

${db}/bts_$1:$(patsubst %,${bts}/results_BTS_$1_%,${files})
	sed -e "s|results_|${bts}/results_|"  -e "s|@SCENARIO@|BTS_$1|" results_bts/results.sql | ${PG} --variable=d=${bts} --variable=s=bts_$1 --variable="qs='''bts_$1'''" -f -
	touch $$@

db::${db}/bts_$1.feedstock

${db}/bts_$1.feedstock:${feedstock_inputs}
	cat ${feedstock_inputs} | sed -e 's/PL//' | ${PG} -c 'COPY bts_$1.feedstock (qid,type,price,marginal_addition) FROM STDIN CSV'
	touch $$@

#kml:${kmls} ${line_kmls}
kmls::$(patsubst %,${web}/$1/%.kml,brfn_summary)

$(patsubst %,${web}/$1/%.kml,brfn_summary):${web}/$1/%.kml:
	${db2kml} $$@ ${ogrdsn} -sql 'select * from bts_$1.$$*';

kmls::$(patsubst %,${web}/$1/%.kml,ag_res hec forest ovw pulpwood msw_wood msw_paper msw_constr_demo msw_yard msw_food msw_dirty corngrain animal_fats grease seed_oils sugar)

$(patsubst %,${web}/$1/%.kml,ag_res hec forest ovw pulpwood msw_wood msw_paper msw_constr_demo msw_yard msw_food msw_dirty corngrain animal_fats grease seed_oils sugar):${web}/$1/%.kml:
	${db2kml} $$@ ${ogrdsn} -sql "select scenario,fuel_price,source_id,dest_id,type,quant_tons/470.0 as quant_tons,route from bts_$1.feedstock_link_shp where type='$$*'";


shps::${out}/bts/$1/refinery.shp ${out}/bts/$1/feedstock.shp ${out}/bts/$1/feedstock.csv ${out}/bts/$1/refinery.csv ${out}/bts/$1/links.csv

${out}/bts/$1:
	mkdir -p $$@

${out}/bts/$1/feedstock.csv:${out}/bts/$1
	${PG-CSV} -c "select * from bts_$1.feedstock" > $$@

${out}/bts/$1/refinery.csv:${out}/bts/$1
	${PG-CSV} -c "select brfn_ser_id,qid, technology as tech, class, feedstock_capacity*1000 as capacity, sorghum*1000 as sorghum, stover*1000 as stover, straw*1000 as straw, switchgrass*1000 as switchgrass, woody_crop*1000 as woody_crop, forest*1000 as forest, pulpwood*1000 as pulpwood, msw_woody*1000 as msw_woody, corngrain*1000 as corngrain, animal_fats*1000 as animal_fats, grease*1000 as grease, seed_oils*1000 as seed_oils, sugar*1000 as sugar from bts_$1.brfn" > $$@

${out}/bts/$1/links.csv:${out}/bts/$1
	${PG-CSV} -c "select fuel_price, source_id, dest_id,type, quant_tons/24 as quantity from bts_$1.feedstock_links" > $$@;

${out}/bts/$1/refinery.shp:${out}/bts/$1
	${pgsql2shp} -f $$@ ${database} "select * from bts_$1.brfn_summary"

${out}/bts/$1/feedstock.shp:${out}/bts/$1
	${pgsql2shp} -f $$@ ${database} "select scenario,fuel_price,source_id,dest_id,type,quant_tons/470.0 as quant_tons,route from bts_$1.feedstock_link_shp";

endef

$(foreach s,${scenarios},$(eval $(call by_scenario,$s)))
