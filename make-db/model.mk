#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

model.mk:=1
year:=2007

models:=north south east west
model-zips:=$(patsubst %,${out}/%_input.zip,${models})

gams-files:=source_list price supply src2refine src2refine_liq refine terminal_odcosts pulpmills

INFO::
	@echo GAMS Model inputs

run-price.url:=http://spreadsheets.google.com/pub?key=t1Vy-xDiV-7B2Mjs3WoVB-Q&single=true&gid=2&output=csv
technology.url:=http://spreadsheets.google.com/pub?key=t1Vy-xDiV-7B2Mjs3WoVB-Q&single=true&gid=1&output=csv
conversion.url:=http://spreadsheets.google.com/pub?key=t1Vy-xDiV-7B2Mjs3WoVB-Q&single=true&gid=0&output=csv

${db}/model:
	${PG} -f ${src}/model/schema.sql
	wget -O - '${run-price.url}' |\
	 ${PG} -c 'COPY model.runs (run,price_point) from STDIN WITH CSV HEADER'
	wget -O - '${technology.url}' |\
	 ${PG} -c 'COPY model.technology (tech,energy_density_gge_per_gal) from STDIN WITH CSV HEADER'
	wget -O - '${conversion.url}' |\
	 ${PG} -c 'COPY model.conversion_efficiency (type,tech,gal_per_bdt,ghg_intensity_Mg_per_gge) from STDIN WITH CSV HEADER'
	touch $@

.PHONY:gams_input.zip
gams_input.zip:${out}/gams_input.zip
${out}/gams_input.zip: $(patsubst %,${out}/%.csv,${gams-files})
	zip $@ $^

.PHONY:source_list.csv
source_list.csv:db/feedstock.feedstock
	@${PG-CSV} -c 'select distinct qid as source from feedstock.feedstock order by source'

${out}/source_list.csv:db/feedstock.feedstock
	${PG-CSV} -c 'select distinct qid as source from feedstock.feedstock order by source' > $@;

${out}/price.csv:db/feedstock.feedstock
	${PG-CSV} -c "select distinct 'PL'||price::integer as price_id,price::integer as price from feedstock.feedstock order by price asc" > $@

${out}/supply.csv:db/feedstock.feedstock
	${PG-CSV} -c "select qid as source,scenario,type,'PL'||price::integer as price_id,marginal_addition from feedstock.feedstock" > $@

${out}/src2refine.csv:db/network.feedstock_odcosts
	${PG-CSV} -c 'select src_qid,dest_qid,cost as bale_cost,road_mi,rail_mi,water_mi,road_hrs from $(notdir $<)' > $@

${out}/src2refine_liq.csv:db/network.liquid_odcosts
	${PG-CSV} -c 'select src_qid,dest_qid,cost as liq_cost,road_mi,rail_mi,water_mi,road_hrs from $(notdir $<)' > $@

${out}/terminal_odcosts.csv:db/network.terminal_odcosts
	${PG-CSV} -c 'select src_qid,dest_qid,cost as fuel_cost,water_mi,rail_mi from $(notdir $<)' > $@

${out}/refine.csv: db/refineries.m_proxy_location db/refineries.ethanol_facility
	${PG-CSV} -c 'select distinct proxy_qid as qid,t.qid as terminal_qid,e.qid as ethanol_qid,e.status as ethanol_status,e.capacity as ethanol_capacity,e.capital_in as ethanol_capital_investment from refineries.proxy_location p left join refineries.has_terminal t on (src_qid=t.qid) left join refineries.ethanol_facility e on (src_qid=e.qid) order by proxy_qid' > $@

${out}/pulpmills.csv:
	${PG-CSV} -c 'select qid,cap_2000,sulfit2000,sulfat2000 from forest.pulpmills;' > $@

# Greedy model inputs ?

greedy.tables:=vmt.vmt_by_census vmt.tract00_closest_terminal vmt.terminal_vmt feedstock.feedstock network.feedstock_odcosts network.terminal_odcosts

${out}/greedy.Fc:
	pg_dump -Fc -O $(patsubst %,--table=%,${greedy.tables}) ${database} --file=$@

.PHONY: model-zips
model-zips:${model-zips}
#travel_cost_per_bdt:=25
$(patsubst %,${db}/%.test,${models}):${db}/%.test:db/%
	cat model/test.sql | sed -e 's/REGION/$*/' | psql -d bioenergy -f -

$(patsubst %,${db}/%,${models}):${db}/%:db/model db/feedstock.feedstock
	cat model/region.sql | sed -e 's/REGION/$*/' | psql -d bioenergy -f -
	touch ${db}/$*

${model-zips}:${out}/%_input.zip:${db}/%
	rm -rf ${out}/$*; mkdir ${out}/$*;
	${PG-CSV} -c "select * from $*.source_list" > ${out}/$*/source_list.csv
	${PG-CSV} -c "select * from $*.price" > ${out}/$*/price.csv
	${PG-CSV} -c "select * from $*.supply" > ${out}/$*/supply.csv
	${PG-CSV} -c "select * from $*.src2refine" > ${out}/$*/src2refine.csv
	${PG-CSV} -c "select * from $*.src2refine_liq" > ${out}/$*/src2refine_liq.csv
	${PG-CSV} -c "select * from $*.terminal_odcosts" > ${out}/$*/terminal_odcosts.csv
	${PG-CSV} -c "select * from $*.refine" > ${out}/$*/refine.csv
	${PG-CSV} -c "select * from $*.pulpmills" > ${out}/$*/pulpmills.csv
	zip -r $@ ${out}/$*

$(patsubst %,${db}/%.test,corn lipids):${db}/%.test:db/%
	cat model/test.sql | sed -e 's/REGION/national/;s/lce/$*/' | psql -d bioenergy -f -

$(patsubst %,${db}/%,corn lipids):${db}/%:db/model db/feedstock.feedstock
	cat model/region.sql | sed -e 's/REGION/national/;s/lce/$*/' | psql -d bioenergy -f -
	touch ${db}/$*

$(patsubst %,${out}/%_input.zip,corn lipids):${out}/%_input.zip:${db}/%
	rm -rf ${out}/$*; mkdir ${out}/$*;
	${PG-CSV} -c "select * from $*.source_list" > ${out}/$*/source_list.csv
	${PG-CSV} -c "select * from $*.price" > ${out}/$*/price.csv
	${PG-CSV} -c "select * from $*.supply" > ${out}/$*/supply.csv
	${PG-CSV} -c "select * from $*.src2refine" > ${out}/$*/src2refine.csv
	${PG-CSV} -c "select * from $*.src2refine_liq" > ${out}/$*/src2refine_liq.csv
	${PG-CSV} -c "select * from $*.terminal_odcosts" > ${out}/$*/terminal_odcosts.csv
	${PG-CSV} -c "select * from $*.refine" > ${out}/$*/refine.csv
	${PG-CSV} -c "select * from $*.pulpmills" > ${out}/$*/pulpmills.csv
	zip -r $@ ${out}/$*

# src_qid,'type',loading
${out}/model.dest_preprocessing_costs.csv:
# dest_qid,type,unloading,grinder,grinder_loading,handling,receiving
${out}/odcost.csv:
# src_qid,dest_qid,travel_cost,road_miles,rail_miles,waterway_miles


db/model.odcost:
	${PG} -c "create table model.odcost as select f.src_qid,f.qid as dest_qid,r.total_cost as road_cost,rr.total_cost as rail_cost,w.total_cost as water_cost from (select distinct s.qid as src_qid,src_id,d.qid as qid from vertex_source s join feedstock_travel_odcosts c on (s.id=c.src_id) join vertex_dest d on (d.id=c.dest_id)) as f left join ( select * from feedstock_travel_odcosts r join vertex_dest d on (r.dest_id=d.id and d.type='road')) as r using (src_id,qid) left join ( select * from feedstock_travel_odcosts r join vertex_dest d on (r.dest_id=d.id and d.type='rail')) as rr using (src_id,qid) left join ( select * from feedstock_odcosts r join vertex_dest d on (r.dest_id=d.id and d.type='water')) as w using (src_id,qid);"
	touch $@


#${out}/hec.csv:${db}/nass.hec_proxy
#	${PG-CSV} -c "select qid,crop_pasture,crop_idle,crop_fallow,permanent_pasture,pastureland,min_acres,min_acres/(area(boundary)/4046.86) as min_perc,max_acres,max_acres/(area(boundary)/4096.86) as max_perc from nass.hec_proxy join network.county using (qid) where year=2007" > $@

${out}/state.feedstock.csv: ${db}/feedstock.feedstock
	${PG-CSV} -f model/state.sql > $@

${out}/county.feedstock.csv:${db}/feedstock.feedstock
	${PG-CSV} -c "create temp table feedstock as select qid,type,sum(marginal_addition) as amount from feedstock.feedstock group by qid,type; select qid,t.sum as sum, 100*ag.sum/t.sum as ag,100*f.sum/t.sum as forest,100*msw.sum/t.sum as clean_msw,100*d.sum/t.sum as dirty_msw from (select qid, sum(amount) from feedstock where type in ('ag','forest','msw_dirty','msw_yard','msw_paper','msw_wood') group by qid) as t left join (select qid, sum(amount) from feedstock where type='forest' group by qid) as f using(qid) left join (select qid,sum(amount) from feedstock where type='ag' group by qid) as ag using (qid) left join  (select qid,sum(amount) from feedstock where type in ('msw_paper','msw_wood','msw_yard') group by qid) as msw using (qid) left join (select qid,sum(amount) from feedstock where type in ('msw_dirty') group by qid) as d using (qid);" > $@


${out}/county.json:${db}/network.county
	echo '{' > $@;
	${PG} -A -F',' --pset footer -t -q -c "select '\"'||qid||'\":{\n \"longitude\" :'||x(transform(centroid,4269))||',\n \"latitude\" :'||y(transform(centroid,4269))||'\n \"border\" :'||asKML(2,transform(simplify(boundary,1000),4269),6)||'\n},' from network.county" >>$@
	echo '}' >> $@;

#select cost,via_road,via_rail,via_water from (select (road_cost/25)::integer*25 as cost,count(*) as via_road from model.odcost group by (road_cost/25)::integer*25) as r full outer join (select (rail_cost/25)::integer*25 as cost,count(*) as via_rail from model.odcost group by (rail_cost/25)::integer*25) as rr using (cost) full outer join (select (water_cost/25)::integer*25 as cost,count(*) as via_water from model.odcost group by (water_cost/25)::integer*25) as w using (cost);

# cost | via_road | via_rail | via_water 
#------+----------+----------+-----------
#    0 |    91808 |   236653 |     45835
#   25 |  1436705 |  1763066 |    490330
#   50 |  1121587 |   738503 |    248601
#   75 |   341263 |   112743 |     65980
#  100 |    39399 |     7342 |     14015
#  125 |     1916 |       75 |      3030
#  150 |       65 |        2 |       253
#  175 |          |          |         4
#  225 |        1 |          |          

${db}/model.fuel_transport_results:${db}/model.%:${down}/%.csv
	sed -e "s|$*.csv|`pwd`/$<|" model/$*.sql | ${PG} -f -
	touch $@

${out}/model.fuel_transport_results.shp:%.shp:${db}/model.fuel_transport_results
	${pgsql2shp} -f $@ ${database} model.fuel_transport_results
	echo '${srid-prj}' > $*.prj

${out}/switchgrass_summary.csv:${db}/hec.ornl_yields ${db}/hec.feedstock
	${PG-CSV} -c 'select qid,up_mean as yield,scenario,amount from hec.feedstock join hec.ornl_yields using (qid) where year=2007' > $@

# INPUTS from Nathan

${db}/model.results:${down}/results_all_250gge_brfn.csv ${down}/results_all_250gge_links.csv
	sed -e "s|_results_|`pwd`/${down}/results_all_250gge_|" model/results.sql | ${PG} -f -
