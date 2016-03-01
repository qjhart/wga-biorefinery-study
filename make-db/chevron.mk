#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

#data_tables:=County18232 County910
data_tables:=County910

INFO::
	@echo Chervon Data

########################################################################
# NASS data is downloaded into zip files manually.  The data comes from 
########################################################################
${db}/chevron:
	echo create schema chevron | ${PG}
#	${PG} -f src/chevron/schema.sql
	touch $@


# I haven't completely decided on how to move cities, so for here we just use this knockoff where I got the lat,long from google's API
#biomass=# select gid,qid,name from network.city join (select gid from (select min(distance) as min from (select gid,distance(centroid,transform(setsrid(makepoint(-118.468,34.180),4326),102004)) as distance from network.city where state='CA') as foo) as min join (select gid,distance(centroid,transform(setsrid(makepoint(-118.468,34.180),4326),102004)) as distance from network.city where state='CA') as foo on (min.min=foo.distance)) as bar using (gid);
#  gid  |   qid    |     name
#-------+----------+--------------
# 26094 | D0666140 | San Fernando


${db}/chevron.terminal:s:=chevron
${db}/chevron.terminal:t:=terminal
${db}/chevron.terminal:down:=${down}/nass
${db}/chevron.terminal:${db}/%:${down}/chevron/Term_Zip_Geocoding_Result.shp
	${shp2pgsql} -d -s 4326 -g nad83 $< $s.$t | ${PG} > /dev/null
	${PG} -c \
	"\
	select AddGeometryColumn('$s','$t','boundary',$(srid),'POINT',2); \
	delete from $s.$t where state not in ('CA','NV','AZ','OR'); \
	update $s.$t set boundary=transform(nad83,${srid}); \
	alter table $s.$t add column qid varchar(8); \
	update $s.$t set boundary=transform(nad83,${srid}); \
	update $s.$t t set qid=f.qid from (select t.gid,c.qid from chevron.terminal t left join network.city c on (t.state=c.state and t.city=c.name)) as f where (f.gid=t.gid);\
	update $s.$t set qid='D0666140' where gid=166;\
	"
	touch $@;

${out}/chevron.terminals.shp:${db}/chevron.terminal
	${pgsql2shp} -f $@ ${database} "select qid,boundary from chevron.terminal join network.city using (qid)"
	echo '${srid-prj}' > $(patsubst %.shp,%.prj,$@)