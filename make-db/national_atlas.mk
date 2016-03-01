#! /usr/bin/make -f

ifndef db
include configure.mk
endif

# Avoid multiple inserts

national_atlas:=1

INFO::
	@echo National Atlas Makefile.
	@echo  All variables local to the targets

db::db/network.county db/network.state 

########################################################################
# National Atlas Data
# citiesx020 Cities from this file are used as locations for
# landings,point sources, potential biorefineries, existing
# biorefineries, and more
########################################################################
# First stage, so we can locate other city_parameters
${db}/network.city:${db}/%:
	${PG} -c "drop table if exists $* cascade;"
	[[ -f ${down}/citiesx020.tar.gz ]] || ( cd ${down}; wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/citiesx020.tar.gz; tar -xzf citiesx020.tar.gz )
	${shp2pgsql} -D -d -s 4326 -g nad83 -S downloads/citiesx020.shp network.city | ${PG} > /dev/null
	${PG} -c "select AddGeometryColumn('network','city','centroid',$(srid),'POINT',2);"
	${PG} -c "update $* set centroid=transform(nad83,${srid}); create index city_centroid_gist on city using gist(centroid gist_geometry_ops);"
	${PG} -c "alter table $* add column qid char(8); update $* set qid='D'||state_fips||fips55;"
	touch $@

${db}/network.county:s:=network
${db}/network.county:t:=county
${db}/network.county:tgz:=countyp020.tar.gz
${db}/network.county:${db}/%:${db}/network
	[[ -f ${down}/${tgz} ]] || ( cd ${down}; wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/${tgz}; tar -xzf ${tgz} )
	# save Temp version
	${shp2pgsql} -D -d -s 4326 -g nad83 -S downloads/$(word 1,$(subst ., ,${tgz})).shp $s.tmp_$t | ${PG} > /dev/null
	# Make one entry per county
	${PG} -c "drop table if exists $s.$t cascade;"
	${PG} -c "create table $s.$t as select 'S'||fips as qid,state_fips,fips,state,county as name from $s.tmp_$t limit 0"
	${PG} -c "alter table $s.$t add column county_gid serial primary key;"
	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'MULTIPOLYGON',2);"
	${PG} -c "insert into $s.$t (qid,state_fips,fips,state,name,boundary) select 'S'||fips as qid,state_fips,fips,state,county,collect(transform(nad83,${srid})) as boundary from $s.tmp_$t group by 'S'||fips,state_fips,fips,state,county;"
	${PG} -c "select AddGeometryColumn('$s','$t','centroid',$(srid),'POINT',2); update $* set centroid=centroid(boundary);"
	${PG} -c "create index $t_centroid on $*(centroid)"
	${PG} -c "create index $t_centroid_gist on $* using gist(centroid gist_geometry_ops)"
	${PG} -c "create index $t_boundary_gist on $* using gist(boundary gist_geometry_ops)"
	${PG} -c "drop table $s.tmp_$t;"
	touch $@;

${db}/network.state:s:=network
${db}/network.state:t:=state
${db}/network.state:tgz:=statesp020.tar.gz
${db}/network.state:${db}/%:${db}/network.county
	[[ -f ${down}/${tgz} ]] || ( cd ${down}; wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/${tgz}; tar -xzf ${tgz} )
	# save Temp version
	${shp2pgsql} -D -d -s 4326 -g nad83 -S downloads/$(word 1,$(subst ., ,${tgz})).shp $s.tmp_$t | ${PG} > /dev/null
	# Make one entry per state
	${PG} -c "drop table if exists $s.$t cascade;"
	${PG} -c "create table $s.$t as select state_fips,state from $s.tmp_$t limit 0"
	${PG} -c "alter table $s.$t add column state_gid serial primary key;"
	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'MULTIPOLYGON',2);"
	${PG} -c "insert into $s.$t (state_fips,state,boundary) select state_fips,state,collect(transform(nad83,${srid})) as boundary from $s.tmp_$t group by state_fips,state;"
	${PG} -c "alter table network.state add column state_abbrev varchar(2);update network.state n set state_abbrev=s.state from (select distinct state_fips,state from network.county) as s where s.state_fips=n.state_fips;"
	${PG} -c "drop table $s.tmp_$t;"
	touch $@;

