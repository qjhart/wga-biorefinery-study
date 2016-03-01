#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif


web:=/var/www

ncp:=/home/ncparker/ncp_thesis


scenarios:=baseline_RFS2 opt_tech_ffv_RFS e15_etoh high_feed high_feed_RFS low_feed_RFS pes_tech_RFS hist_res_RFS high_residue_RFS fair_share_RFS fs_etoh_RFS corn_high

files:=fuel_links.csv feedstock_links.csv brfn.csv biomass_consumed.put
#results_baseline_RFS.csv

#$(patsubst %,${ncp}/results_%_feedstock_links.csv,${scenarios}):${ncp}/results_%_feedstock_links.csv:${ncp}/results_%_feedstock_links.put
#	ln -s $< $@

$(patsubst %,${ncp}/results_%_feedstock_links.csv,${scenarios}):${ncp}/results_%_feedstock_links.csv:
	ln -s ${ncp}/results_$*_feedstock_links.put $@

$(patsubst %,${ncp}/results_%_brfn.csv,${scenarios}):${ncp}/results_%_brfn.csv:
	ln -s ${ncp}/results_$*_brfn.put $@

$(patsubst %,${ncp}/results_%_fuel_links.csv,${scenarios}):${ncp}/results_%_fuel_links.csv:${ncp}/results_%_fuel_links.put
	perl -n -e 'sub rt {my $$f=shift; $$f=~s/\s+$$//;$$f;};' -e '/(.{15She})(.{4})(.{12})(.{12})(.{18})(.{6})/; printf "\"%s\",%0.2f,\"%s\",\"%s\",\"%s\",%0.2f\n",rt($$1),$$2,rt($$3),rt($$4),rt($$5),$$6' $< > $@  

.PHONY: scenarios shps kml
define by_scenario

scenarios::$1
.PHONY:$1
db::${db}/ncp_$1
$1:${db}/ncp_$1

${db}/ncp_$1:$(patsubst %,${ncp}/results_$1_%,${files})
	sed -e "s|results_|${ncp}/results_|" -e "s|@SCENARIO@|$1|"  results_ncp/results.sql | ${PG} -f -
#	${PG} --variable=s=ncp_$1 -f results_ncp/functions.sql
	touch $$@

kmls::$(patsubst %,${web}/$1/brfn.%.kml,dry_mill wet_mill sugar fahc ft_diesel fame)


$(patsubst %,${web}/$1/brfn.%.kml,dry_mill wet_mill sugar fahc ft_diesel fame):${web}/$1/brfn.%.kml:
	${db2kml} $$@ ${ogrdsn} -sql "select * from ncp_$1.brfn_summary where technology='$$*'";

kmls::$(patsubst %,${web}/$1/%.kml,ag_res hec forest ovw pulpwood msw_wood msw_paper msw_constr_demo msw_yard msw_food msw_dirty corngrain animal_fats grease seed_oils sugar)

$(patsubst %,${web}/$1/%.kml,ag_res hec forest ovw pulpwood msw_wood msw_paper msw_constr_demo msw_yard msw_food msw_dirty corngrain animal_fats grease seed_oils sugar):${web}/$1/%.kml:
	${db2kml} $$@ ${ogrdsn} -sql "select scenario,fuel_price,source_id,dest_id,type,quant_tons/470.0 as quant_tons,route from ncp_$1.feedstock_link_shp where type='$$*'";

shps::${out}/ncp/$1/refinery.shp ${out}/ncp/$1/feedstock.shp

${out}/ncp/$1:
	mkdir -p $$@

# e15_etoh and high_feed are set to 3.40 output
${out}/ncp/$1/refinery.shp:${out}/ncp/$1
	${pgsql2shp} -f $$@ ${database} "select * from ncp_$1.brfn_summary"

${out}/ncp/$1/feedstock.shp:${out}/ncp/$1
	${pgsql2shp} -f $$@ ${database} "select scenario,fuel_price,source_id,dest_id,type,quant_tons/470.0 as quant_tons,route from ncp_$1.feedstock_link_shp  $(if ,where fuel_price=3.4,)";

endef

$(foreach s,${scenarios},$(eval $(call by_scenario,$s)))
