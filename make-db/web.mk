#! /usr/bin/make -f
web.mk:=1

ifndef db
include configure.mk
endif

web:=/var/www

INFO::
	@echo Web data

web::{$db}/web

${db}/web:
	${PG} -f web/schema.sql
	touch $@


.PHONY:gis
.PHONY:kml

kmls:=$(patsubst %,${web}/%.kml,potential_refineries baseline_summary)
line_kmls:=$(patsubst %,${web}/baseline_%.kml,ag_res animal_fats corngrain forest grease hec msw ovw pulpwood seed_oils)

kml:${kmls} ${line_kmls}

${kmls}:${web}/%.kml:
	${db2kml} $@ ${ogrdsn} -sql 'select * from web.$*';

${line_kmls}:${web}/baseline_%.kml:
	${db2kml} $@ ${ogrdsn} -sql "select * from web.baseline_run17 where stype='$*'";

${web}/baseline/run17.csv:
	${PG-CSV} -c "select dest_id,dest,source_id,source,county,stype,quant_tons from web.baseline_run17" > $@

${web}/baseline/summary.csv:
	${PG-CSV} -c "select qid,name,ag,animal_fats,corngrain,forest,grease,hec,msw,ovw,pulpwood,seed_oils,total from web.baseline_summary" > $@

define feedstock
gis::${web}/feedstock/p_$1_$2.shp ${web}/feedstock/c_$1_$2.shp

${web}/feedstock/p_$1_$2.shp:${db}/feedstock.feedstock
	pgsql2shp -g centroid -f $$@ ${database} "select t.*,p.centroid from web.feedstock_by_tech('$1',$2) t join network.place p on (substring(t.qid from 2)=substring(p.qid from 2)) union select t.*,e.centroid from web.feedstock_by_tech('$1',$2) t join refineries.epa_facility e on (ltrim(t.qid,'SBC')=e.gid::text)"

${web}/feedstock/c_$1_$2.shp:${db}/feedstock.feedstock
	pgsql2shp -g boundary -f $$@ ${database} "select t.*,c.boundary from web.feedstock_by_tech('$1',$2) t join network.county c using (qid)"

endef

$(foreach t,low mid high,$(foreach m,25 50 75 100 125 150 200 500 1000,$(eval $(call feedstock,$t,$m))))

gis::${web}/feedstock/point_feedstocks.shp ${web}/feedstock/county_feedstocks.shp

${web}/feedstock/point_feedstocks.shp:${db}/feedstock.feedstock
	pgsql2shp -g centroid -f $@ ${database} "select t.*,p.centroid from web.feedstock_by_type(20000) t join network.place p on (substring(t.qid from 2)=substring(p.qid from 2)) union select t.*,e.centroid from web.feedstock_by_type(20000) t join refineries.epa_facility e on (ltrim(t.qid,'SBC')=e.gid::text)"

${web}/feedstock/county_feedstocks.shp:${db}/feedstock.feedstock
	pgsql2shp -g boundary -f $@ ${database} "select t.*,c.boundary from web.feedstock_by_type(20000) t join network.county c using (qid)"

gis::${web}/feedstock/feedstocks.csv

${web}/feedstock/feedstocks.csv:${db}/feedstock.feedstock
	${PG-CSV} -c "select p.qid,t.* from web.feedstock_by_type(20000) t join network.place p on (substring(t.qid from 2)=substring(p.qid from 2)) union select t.qid,t.* from web.feedstock_by_type(20000) t join refineries.epa_facility e on (ltrim(t.qid,'SBC')=e.gid::text) union select c.qid,t.* from web.feedstock_by_type(20000) t join network.county c using (qid)" > $@

ref:=m_potential_location m_proxy_location epa_facility biopower_facility ethanol_facility
gis-ref:=$(patsubst %,${web}/refineries/%.shp,${ref})

gis::${gis-ref}

${gis-ref}:${web}/refineries/%.shp:${db}/refineries.%
	pgsql2shp -g centroid -f $@ ${database} refineries.$*

gis::${web}/transportation/edge.shp
${web}/transportation/edge.shp:db/network.edge
	pgsql2shp -g segment -f $@ ${database} $(notdir $<)


gis::${web}/pulpmills/pulpmills.shp
${web}/pulpmills/pulpmills.shp:${db}/forest.pulpmills
	[[ -d $(dir $@) ]] || mkdir $(dir $@)
	pgsql2shp -g centroid -f $@ ${database} $(notdir $<)


# with recursive se(id,source,target,type,miles,hours,bale_cost) as (
#   select e.id,e.source,e.target,e.type,e.miles,e.hours,e.bale_cost 
#   from refineries.m_potential_location p join network.place n using (gid) 
#   join network.edge e on (gid=source) where p.qid like 'D0662364%' 
#   UNION 
#   select e.id,e.source,e.target,e.type,s.miles+e.miles,e.hours,
#          s.bale_cost+e.bale_cost 
#   from se s join network.edge e on (s.target=e.source)
# ) 
# select * from se limit 10000; 

