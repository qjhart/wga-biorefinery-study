#! /usr/bin/make -f
ifndef db
include configure.mk
endif

billion_ton.mk:=1

INFO::
	@echo Billion Ton Study from ORNL

${db}/billion_ton:billion_ton/codes.csv billion_ton/WGA-Frst.dat billion_ton/WGA-Engy-BLY+EC1_BLT.dat
	cd billion_ton; ${PG} -f  schema.sql
	touch $@

# Required files were downloaded from ORNL
# WGA-Frst.dat and WGA-Engy-BLY+EC1_BLT.dat
billion_ton/codes.csv:
	wget -O $@ 'https://spreadsheets.google.com/pub?key=0AmgH34NLQLU-dC1INjV4N2dHanROTVFnZ01rQ1VYeGc&hl=en&single=true&gid=1&output=csv' > $@

.PHONY:db
db::${db}/billion_ton


