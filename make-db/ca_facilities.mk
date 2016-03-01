#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

shapefiles:=food_processing flaredlfgonly meatprocessor LF_ventingNoControl \
            compost_and_mulch permitted_food_scrap_compost rendering_company composting \
            disposal transfer_processing transformation waste_tire_site \
            landfill bdircomb05_83 bdircomb05_83_msw bdircomb05_83_biomass \
            digestergas animalwaste_dairy animalwaste_swine foodwaste wastewatertreatment lfgte \
            lfgte_electricity lfgte_heat lfgte_planned ethanol 

# Directories used
dir_food_processing:=foodProcessing
dir_flaredlfgonly:=flaringLFGOnly
dir_meatprocessor:=meatProcessor
dir_LF_ventingNoControl:=landfillVentingWithoutControl
dir_compost_and_mulch:=compostAndMulch
dir_permitted_food_scrap_compost:=permittedFoodScrapCompost
dir_rendering_company:=renderingCompany
dir_composting:=composting
dir_disposal:=disposal
dir_transfer_processing:=transferProcessing
dir_transformation:=transformation
dir_waste_tire_site:=wasteTireSite
#dir_directcombustion_biomass:=directCombustion
#dir_directcombustion_msw:=directCombustion
dir_landfill:=totalLandfill
dir_bdircomb05_83:=directCombustion
dir_bdircomb05_83_msw:=directCombustion
dir_bdircomb05_83_biomass:=directCombustion
dir_digestergas:=digesterGas
dir_animalwaste_dairy:=digesterGas
dir_animalwaste_swine:=digesterGas
dir_foodwaste:=digesterGas
dir_wastewatertreatment:=digesterGas
dir_lfgte:=LFGToEnergy
dir_lfgte_electricity:=LFGToEnergy
dir_lfgte_heat:=LFGToEnergy
dir_lfgte_planned:=LFGToEnergy
dir_ethanol:=ethonal


# This file is updated every Monday, Wednesday, and Friday at 6:00 a.m. 
# The data dictionary includes a description of each of the data fields.
swis_url:=http://www.calrecycle.ca.gov/Files/SWFacilities/Directory/SwisGis.txt
swis_data_dictionary:=http://www.calrecycle.ca.gov/SWFacilities/Directory/Definitions/default.aspx

ca_facilities.mk:=1

INFO::
	@echo Make California biomass facilities

db::${db}/ca_facilities ${db}/ca_facilities.waste_tire_sites ${db}/ca_facilities.swis

#${down}/msw.pop_growth.csv:
#	wget -O $@ 'http://spreadsheets.google.com/pub?key=tpLRk5taexWiZJreWN_Nzqw&single=true&gid=0&output=csv'

${db}/ca_facilities:
	${PG} -f ca_facilities/schema.sql
	touch $@

${db}/ca_facilities.swis:${down}/swis.csv
	cat ca_facilities/swis.sql | sed -e "s|swis.csv|`pwd`/$<|" | ${PG} -f -
	touch $@

${down}/swis.csv:
	wget -O $@ ${swis_url}

${out}/swis.csv:${db}/ca_facilities.swis
	${PG} -c "copy (select * from ca_facilities.swis_fusion) to STDOUT with csv header quote as '\"'" > $@

# $(patsubst %,db/ca_facilities.%,${shapefiles}):${db}/ca_facilities.%:${down}/biomassFacilities/%.shp
# 	${shp2pgsql} -d -s 3310 -g centroid -S ${down}/biomassFacilities/${dir_$*}/$* $(notdir $@)| ${PG}
# 	touch $@

define in_shp
.PHONY:db
db::${db}/ca_facilities.$1

${db}/ca_facilities.$1:${down}/biomassFacilities/$2/$1.shp
	${shp2pgsql} -d -s 3310 -g centroid -S $$< ca_facilities.$1 | ${PG}
	touch $$@

endef

$(foreach s,${shapefiles},$(eval $(call in_shp,$s,${dir_$s})))





