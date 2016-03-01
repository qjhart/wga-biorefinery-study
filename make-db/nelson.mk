#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

INFO::
	@echo Input/Output files for Richard Nelson

##########################################################################
# Output files
##########################################################################
${db}/nelson:${db}/public
	${PG} -c 'drop schema if exists nelson cascade; create schema nelson;'
	touch $@

# Replaced with ag_residues
#${db}/nelson.acr: ${down}/nelson.acr.csv ${db}/nelson
#	cat nelson/acr.sql | sed -e "s|acr.csv|`pwd`/${down}/nelson.acr.csv|" | ${PG} -f -
#	touch $@

#${db}/nelson.wga_ag: ${db}/nelson ${down}/nelson.ag_cellulosic_co.csv ${down}/nelson.sd_ne_new.csv ${down}/nelson.ok_new.csv 
#	cat nelson/wga_ag.sql | \
#	sed -e "s|nelson.ag_cellulosic_co.csv|`pwd`/${down}/nelson.ag_cellulosic_co.csv|" \
#	    -e "s|nelson.sd_ne_new.csv|`pwd`/${down}/nelson.sd_ne_new.csv|" \
#	    -e "s|nelson.ok_new.csv|`pwd`/${down}/nelson.ok_new.csv|" |\
#	 ${PG} -f -
#	touch $@


${down}/nelson.ag_residue.csv:g:=https://spreadsheets.google.com/pub?key=0ApcT3MKdRQLQdDU4S3ZVVWczalRYVHpNM2FuTXowcmc&hl=en&single=true&gid=0&output=csv
${down}/nelson.ag_residue.csv:
	wget -O $@ '${g}' 

${db}/nelson.ag_residue: ${down}/nelson.ag_residue.csv
	cat nelson/ag_residue.sql | sed -e "s|ag_residue.csv|`pwd`/${down}/nelson.ag_residue.csv|" | ${PG} -f -
	touch $@

.PHONY: db
db::${db}/nelson.feedstock
${db}/nelson.feedstock:${db}/network.county ${db}/nelson.ag_residue ${db}/nass.commcode_biomass_yield
	${PG} -f nelson/feedstock.sql
	touch $@

${out}/nelson_soils.dbf:
	${PG} -c "drop table if exists tmp.nelson;"
	${PG} -c "create table tmp.nelson as select area.areasymbol::varchar(5),fips,(county||', '||state)::varchar(32) as county,c.cokey,mu.muname,c.compname,c.comppct_r as comp_perc,(c.slope_l||'-'||c.slope_h)::varchar(5) as slope,(nirrcapcl||nirrcapscl)::varchar(2) as land_capability,tfact,acres from ssurgo.mapunit mu join ssurgo.component c using (mukey) join (select areasymbol,county_gid,cokey,sum((area(the_geom)*comppct_r/100.0/4046.86))::decimal(10,0) as acres from pfarm.scp join ssurgo.component c using (mukey) where comppct_r is not null group by areasymbol,county_gid,cokey) as area using (cokey) join network.county using (county_gid);"
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) ${database} tmp.nelson

${out}/nelson_soils_100.dbf:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) ${database} 'select * from tmp.nelson where acres > 100;'

year:=2007
mui-pfarm:=pfarm/pfarm_fitness pfarm/pfarm_crop_fitness pfarm/m_pfarm_crop_score pfarm/pfarm_crop_residue
mui-pfarm-year:=pfarm/m_pfarm_crop_production pfarm/m_pfarm_actual_production pfarm/pfarm_actual_biomass
mui-other:=pfarm/pfarm_county cdl/iowa ssurgo/map_unit
mui:=${mui-pfarm} ${mui-pfarm-year} ${mui-other}

.PHONY:mui
mui:$(patsubst %,${out}/%.prj,${mui}) $(patsubst %,${out}/%.shp,${mui})

$(patsubst %,${out}/%.prj,${mui}):
	echo ${srid-prj} > $@

${out}/pfarm/pfarm_county.shp:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} pfarm.pfarm_county;

${out}/cdl/iowa.shp:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} tmp.iowa;

${out}/ssurgo/map_unit.shp:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} ssurgo.map_unit;

$(patsubst %,${out}/%.shp,${mui-pfarm}):${out}/pfarm/%.shp:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} "select b.*,boundary from pfarm.$* b join pfarm.pfarm_county c using (pfarm_gid)"

$(patsubst %,${out}/%.shp,${mui-pfarm-year}):${out}/pfarm/%.shp:
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} "select b.*,boundary from pfarm.$* b join pfarm.pfarm_county c using (pfarm_gid) where year=${year}"


