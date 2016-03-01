#! /usr/bin/make -f
vmt.mk:=1

ifndef db
include configure.mk
endif

ifndef census.mk
include census.mk
endif

INFO::
	@echo Vehicle Miles Traveled

.PHONY:db
db::${db}/vmt

${db}/db.vmt: ${down}/vmt_by_census_tract.csv ${db}/census.tract00
	cat vmt/schema.sql | sed -e "s|$(notdir $<)|`pwd`/$<|" | ${PG} -f -
	touch $@





