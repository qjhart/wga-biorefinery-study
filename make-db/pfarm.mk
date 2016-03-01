#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.

pfarm:=1

ifndef db
include configure.mk
endif

ifndef network.mk
include network.mk
endif

ifndef nass.mk
include nass.mk
endif

ifndef ssurgo.mk
include ssurgo.mk
endif

comma:=,

# Notes on bdt per Bu
#http://www.agry.purdue.edu/ext/corn/pubs/agry9509.htm

county_fips:= 19011 19013 19019 19031 19055 19065 19113 19105 \
20079 20155 20173 20151 20095 20191 20077

INFO::
	@echo Make believe Pseudo farms.
	@echo '${.VARIABLES}'
	@echo '${MAKEFILE_LIST}'

pfarm-db::db/pfarm db/pfarm.pfarm_county db/pfarm.county_centroid db/pfarm.pfarm_map_unit_poly db/pfarm.pfarm_cdl_map_unit_poly

${db}/pfarm: ${db}/nass db/network.county
	${PG} -f ${src}/pfarm/schema.sql
	${PG} -f ${src}/pfarm/functions.sql
	touch $@

# Goes blazing fast when you don't compose the polys.  Have to be
# careful when you run this, since it does depend on pfarm_county and
# ssurgo.map_unit_poly (The single one)
${db}/pfarm.pfarm_map_unit_poly:${db}/%:${db}/pfarm ${db}/pfarm.pfarm_county ${db}/ssurgo.map_unit_poly
	${PG} -c 'insert into $* (county_gid,pfarm_gid,map_unit_poly_gid,mukey,boundary) select p.county_gid,p.pfarm_gid,m.map_unit_poly_gid,m.mukey,multi(intersection(p.boundary,m.boundary)) as boundary from pfarm.pfarm_county p, ssurgo.map_unit_poly m where (p.boundary && m.boundary) and st_overlaps(p.boundary,m.boundary);'
	touch $@

${db}/pfarm.pfarm_cdl_map_unit_poly:${db}/%:db/pfarm_county db/ssurgo.map_unit_poly
	${PG} -c 'insert into $* (county_gid,pfarm_gid,gridcode,class_name,map_unit_poly_gid,mukey,boundary) select p.county_gid,p.pfarm_gid,c.gridcode,c.class_name,m.map_unit_poly_gid,m.mukey,multi(intersection(intersection(p.boundary,m.boundary),c.boundary)) as boundary from pfarm.pfarm_county p, ssurgo.map_unit_poly m, tmp.iowa c where (p.boundary && m.boundary) and (p.boundary && c.boundary) and (m.boundary && c.boundary) and st_overlaps(p.boundary,m.boundary) and st_overlaps(c.boundary,intersection(p.boundary,m.boundary));'
	touch $@

db/pfarm.pfarm_county ${db}/pfarm.pfarm_county+:${db}/%:${db}/pfarm
	${PG} -c "delete from pfarm.pfarm_county where county_gid in (select county_gid from network.county where fips in ($(subst ' ','${comma}',$(patsubst %,'%',${county_fips}))));"
	${PG} -c "insert into pfarm.pfarm_county (county_gid,box,boundary) select county_gid,box,setsrid(box,srid) from (select c.county_gid,srid(c.boundary) as srid,pfarm.grid_boxes_trojan(c.boundary,1000,0.5) as box from network.county c where c.fips in ($(subst ' ','${comma}',$(patsubst %,'%',${county_fips})))) as b;"
	touch db/pfarm.pfarm_county
#	${PG} -c "select addGeometryColumn('pfarm','pfarm_county','centroid',${srid},'POINT',2); update pfarm.pfarm_county set centroid=centroid(boundary);"



db/pfarm.pfarm_county_centroid:db/%:db/pfarm.pfarm_county
	${PG} -c "drop table if exists $*; create table pfarm.pfarm_county_centroid (gid integer,name varchar(32)); select addGeometryColumn('pfarm','pfarm_county_centroid','centroid',102004,'POINT',2); insert into pfarm.pfarm_county_centroid select pfarm_gid,'pfarm',centroid(boundary) from pfarm.pfarm_county;"
# select network.add_road_connector('pfarm.pfarm_county_centroid','gid',40000,99);"
	touch $@


${out}/pfarm.pfarm_county.shp:${out}/%.shp:
	${pgsql2shp} -f $@ ${database} $*


${out}/inl_example.shp:${out}/%.shp:
	${PG} -c 'drop table if exists tmp.pfarms_in_production';
	${PG} -c 'create table tmp.pfarms_in_production as select pfarm_gid,year,name,fips,arable_acres,arable_irrcapcl,typical_irr_yield,actual_yield,yldunits,pf.boundary from pfarm.pfarm_county pf join pfarm.m_pfarm_actual_crop_production using(pfarm_gid,county_gid) join network.county using (county_gid) join pfarm.crop using (crop_id) where year=2007;'
	cd $(dir $@); ${pgsql2shp} -f $(notdir $@) -g boundary ${database} tmp.pfarms_in_production

.PHONY:out

cost.csvs:=${out}/pfarm.cost_by_distance_histogram.csv $(patsubst %,${out}/pfarm.cost_by_distance_histogram_%.csv,county muni road_only rail_only road_rail road_water)

out: ${cost.csvs}

${cost.csvs}:${out}/%.csv:
	${PG-CSV} -c 'select * from $*' > $@

