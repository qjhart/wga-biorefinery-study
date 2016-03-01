#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

msw.mk:=1

INFO::
	@echo Make MSW info

db::${db}/msw ${db}/msw.feedstock 

${db}/msw.feedstock: ${db}/msw.msw_by_city ${db}/msw.pop_growth 
	${PG} -f msw/feedstock.sql
	touch $@

${down}/msw.pop_growth.csv:
	wget -O $@ 'http://spreadsheets.google.com/pub?key=tpLRk5taexWiZJreWN_Nzqw&single=true&gid=0&output=csv'

${db}/msw.pop_growth:${down}/msw.pop_growth.csv
	cat msw/pop_growth.sql | sed -e "s|pop_growth.csv|`pwd`/${down}/msw.pop_growth.csv|" | ${PG} -f -
	touch $@

${db}/msw ${db}/msw.msw_by_city:
	${PG} -f msw/schema.sql
	touch ${db}/msw ${db}/msw.msw_by_city


${out}/msw.msw_by_city.dbf:${out}/%.dbf:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	${pgsql2shp} -f $@ ${database} 'select gid as id,* from $(notdir $*)'






