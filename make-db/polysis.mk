#! /usr/bin/make -f 
ifndef db
include configure.mk
endif

polysis.mk:=1

INFO::
	@echo Data from POLYSIS

${db}/polysis:
	${PG} -f polysis/schema.sql
	touch $@

db/polysis.variable:db/polysis ${down}/variable.dbf
	$(call add_dbf_cmd,polysis.variable,${down}/variable.dbf)
	touch $@

db/polysis.cost_per_yield:db/polysis.variable
	${PG} -f polysis/cost_per_yield.sql
	touch $@
