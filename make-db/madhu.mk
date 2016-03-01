#! /usr/bin/make -f
ifndef db
include configure.mk
endif

INFO::
	@echo HEC from Madhu Khanna, Professor Department of Agricultural and Consumer Economics Energy Biosciences Institute, Institute of Genomic Biology University of Illinois, Urbana-Champaign 1306, W. Gregory Drive, Urbana, IL 61801


${db}/madhu:${db}/public
	${PG} -c 'drop schema if exists madhu cascade; create schema madhu;'
	touch $@

# This is the first time I save data to the make-db part.  More simple
# sql functions that can work always in that directory.
madhu/madhu.csv:
	wget -O $@ 'https://spreadsheets.google.com/pub?key=0AmgH34NLQLU-dDEwUzdmRHNHa3U4NUE5dU4zZlRmbFE&hl=en&single=true&gid=0&output=csv'

.PHONY:db
db::${db}/madhu.feedstock

${db}/madhu.feedstock:madhu/madhu.csv db/madhu
	(cd madhu; ${PG} -f feedstock.sql)
	touch $@

