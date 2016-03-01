#! /usr/bin/make -f
ifndef network
include network.mk
endif

ifndef statsgo
include statsgo.mk
endif

ifndef nass.mk
include nass.mk
endif

hec.mk:=1

INFO::
	@echo HEC

${db}/hec:
	${PG} -f ${src}/hec/schema.sql
	touch $@

# Use this to 
${out}/hay_yields_nirrcapcl.csv:
	${PG-CSV} -c "select yield,nirrcapcl from statsgo.county_fitness join network.county c using (county_gid) join (select fips,year,commcode,praccode,yield,yieldunit from nass.nass where commcode in (18999999,19591999,19599999) and praccode=2) as hy using (fips)" >$@

${down}/hec.ornl_yields.csv:
	wget -O $@ 'http://spreadsheets.google.com/pub?key=tXtcfSiOWBdBIkxorwEFDVQ&single=true&gid=0&output=csv'

${db}/hec.ornl_yields:${down}/hec.ornl_yields.csv ${db}/hec
	sed -e "s|hec.ornl_yields.csv|`pwd`/${down}/hec.ornl_yields.csv|" hec/ornl_yields.sql | ${PG} -f -
	touch $@

${db}/hec.available_lands ${db}/hec.feedstock:${db}/nass.ch2table8 ${db}/hec.ornl_yields
	${PG} -f hec/feedstock.sql
	touch $@

