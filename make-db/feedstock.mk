#! /usr/bin/make -f
ifndef db
include configure.mk
endif

ifndef nass.mk
include nass.mk
endif

ifndef nelson.mk
include nelson.mk
endif

ifndef hec.mk
include hec.mk
endif

ifndef refineries
include reifineries.mk
endif

ifndef forest.mk
include forest.mk
endif

ifndef msw.mk
include msw.mk
endif

ifndef madhu.mk
include madhu.mk
endif

ifndef polysis.mk
include polysis.mk
endif

INFO::
	@echo Other Feedstocks

#define fix_csv
#	perl -p -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)(\.(\d*))?\"/$$2$$3$$4$$5/g#;' -e 's/\$$//g;' -e's/\?//g;' -e 's/,+.$$//'  $2 > $1
#endef

feedstocks:=animal_fats cotton_trash
other-schema-sources:=nass.feedstock nass.commcode_growth_2007_2015 nelson.feedstock hec.feedstock forest.feedstock msw.msw_by_city network.county refineries.epa_facility polysis.cost_per_yield msw.pop_growth madhu.feedstock

db::	${db}/feedstock.feedstock

${db}/feedstock:
	$(call add_schema_cmd,$(notdir $@))
	touch $@

##########################################################################
# Input files - These inputs are from enersol
##########################################################################
${db}/feedstock.ovw:${db}/feedstock ${down}/ovw.csv
	sed -e "s|ovw.csv|`pwd`/${down}/ovw.csv|" feedstock/ovw.sql | ${PG} -f -
	touch $@

${down}/feedstock.cotton_trash.csv:
#	wget -O $@ 'https://smartsite.ucdavis.edu:8443/access/content/group/a171c575-3239-4ecb-baa8-ee82ec3d713c/National%20Model%20data%20sets/cotton.csv'

${db}/feedstock.cotton_trash:${down}/feedstock.cotton_trash.csv ${db}/feedstock
	sed -e "s|cotton_trash.csv|`pwd`/${down}/feedstock.cotton_trash.csv|" feedstock/cotton_trash.sql | ${PG} -f -
	touch $@

${down}/feedstock.animal_fats.csv:
	echo get $@ from the Smartsite

${db}/feedstock.animal_fats:${down}/feedstock.animal_fats.csv ${db}/feedstock ${db}/network.state
#	$(call fix_csv,$<.tmp,$<)
	sed -e "s|animal_fats.csv|`pwd`/${down}/feedstock.animal_fats.csv|" feedstock/animal_fats.sql | ${PG} -f -
	touch $@

${db}/feedstock.feedstock:$(patsubst %,${db}/feedstock.%,${feedstocks}) $(patsubst %,db/%,$(other-schema-sources))
	${PG} -f feedstock/feedstock.sql
	touch $@

