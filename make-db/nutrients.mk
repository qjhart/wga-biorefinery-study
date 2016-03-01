#! /usr/bin/make -n
nutrients.mk:=1

ifndef db
include configure.mk
endif

# If this file is missing, then automagically run the rule below
include nutrients/google.mk

# This rule makes a file with the authorization token for
# spreadsheets.  See
# http://code.google.com/apis/gdata/articles/using_cURL.html for more
# information.  This needs to be run like: 'make
# email=qjhart@gmail.com pw=quinnIsGreat`, but then you don't have to
# supply that for as long as the token is valid
nutrients/google.mk:
	curl https://www.google.com/accounts/ClientLogin -d Email=${email} -d 'Passwd=${pw}' -d accountType=GOOGLE -d source=bioenergy -d service=wise | grep '^Auth' | sed -e 's/^Auth=/wise-auth:=/' > $@;

.PHONY:db
db::${db}/nutrients.feedstock

#old-residue_yields-key:=tXCt2nXfRpmWs4JjLdvAT7g
residue_yields-key:=0ApcT3MKdRQLQdDRPTWh0X3c1VEl2SFZIR1BhajByWWc
nutrients-key:=0ApcT3MKdRQLQdHdmOWNMejN2clVoTEhueHhtV2tKLUE

nutrients/nutrients.csv nutrients/residue_yields.csv:nutrients/%.csv:
	curl --silent --output $@ --header "Authorization: GoogleLogin auth=${wise-auth}" 'https://spreadsheets0.google.com/ccc?key=${$*-key}&single=true&gid=0&output=csv' 

${db}/nutrients ${db}/nutrients.feedstock:${db}/public nutrients/nutrients.csv nutrients/residue_yields.csv
	cd  nutrients; ${PG} -f schema.sql
#	touch $@



nut:=commodity_feedstock feedstock
nut-csv:=$(patsubst %,${out}/nutrients.%.csv,${nut})

.PHONY:csv
csv::${nut-csv} ${out}/nutrients.supply.csv

${nut-csv}:${out}/%.csv:
	${PG-CSV} -c 'select * from $*' > $@

${out}/nutrients.supply.csv:
	${PG-CSV} -c "select qid as source,scenario,type,'PL'||price::integer as price_id,marginal_addition from nutrients.feedstock order by scenario,qid" > $@

