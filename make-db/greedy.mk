#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

greedy.mk:=1

greedy_tables:=greedy.feedstock_m network.feedstock_odcosts
greedy_csv:=$(patsubst %,${out}/%.csv,${greedy_tables})

INFO::
	@echo ${greedy_csv}

db::${db}/greedy

${db}/greedy:
	$(call add_schema_cmd,$(notdir $@))
	wget -O - 'http://spreadsheets.google.com/pub?key=tesMc7L-HTLfAAayVur38Xw&single=true&gid=0&output=csv' | ${PG} -c 'COPY greedy.conversion_efficiency (tech,type,gal_per_bdt) from STDIN WITH CSV HEADER;'
	${PG} -f greedy/model.sql
	touch $@

${greedy_csv}:${out}/%.csv:db/%
	${PG} -c "select * from $*" > $@

${out}/greedy.tgz:${greedy_csv}
	tar -czf $@ ${greedy_csv}

${out}/greedy.shp:%.shp:
	${pgsql2shp} -f $@ ${database} -g line "select rank,f.qid as src_qid,dest_qid,type,price,travel_cost,(price+travel_cost) as delivered_cost,marginal_addition,makeline(s.centroid,d.centroid) as line from greedy.feedstock_m f join greedy.used_feedstocks using (fid) join (select qid,centroid from network.place union select qid,centroid from network.county) as s using (qid) join network.place d on (dest_qid=d.qid)"
	echo '${srid-prj}' > $*.prj

${out}/greedy_dest.shp:%.shp:
	${pgsql2shp} -f $@ ${database} -g centroid "select dest_qid,rank,size::integer,cost::integer,(cost/size)::decimal(6,2) as cost_per_ton,d.centroid from greedy.built_refineries b join network.place d on (dest_qid=d.qid)"
	echo '${srid-prj}' > $*.prj

${out}/greedy.zip:${out}/greedy.shp ${out}/greedy_dest.shp
	zip $@ $(patsubst %,${out}/greedy.%,shp shx prj dbf) $(patsubst %,${out}/greedy_dest.%,shp shx prj dbf)

db/input:${down}/network.feedstock_odcosts.csv
	sed -e "s|network.feedstock_odcosts.csv|`pwd`/${down}/network.feedstock_odcosts.csv|" \
	    -e "s|feedstock.csv|`pwd`/${down}/greedy.feedstock_m.csv|" greedy/input.sql | ${PG} -f -




