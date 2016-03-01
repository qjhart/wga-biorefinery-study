#! /usr/bin/make  -f

# This is the Configuation file for the Biomass data
configure.mk:=1

# Specify the directory for data downloads
down:=downloads

# Specify a location for output files.
out:=output

# SRC, where are the source files.  Try to figure out
src:=$(dir $(firstword ${MAKEFILE_LIST}))

# Specify a location for making notes of what tables are
# created. Right now the interface between the database and the files
# is not great, but basically, a notation in the ${db}/table file,
# indicates that it's up to date.
db:=db


# Database Information.  Make sure that you have your .pgpass
# specified so you don't neeed to use a password to log into this
# account.
#database:= biomass
database:= bioenergy
user:=${USER}
PG:=psql -d $(database)
#PG:=psql --cluster 8.3/main -d $(database)
#PG:=psql -h localhost -p 5432 -U ${user} -d $(database)

PG-CSV:=${PG} -A -F',' --pset footer

# Postgis commands.
shp2pgsql:=shp2pgsql
pgsql2shp:=pgsql2shp
#pgsql2shp:=pgsql2shp -h localhost -p 5433 -d ${database}
#shp2pgsql:=/c/Program\ Files\ \(x86\)/PostgreSQL/8.3/bin/shp2pgsql
#pgsql2shp:=/c/Program\ Files\ \(x86\)/PostgreSQL/8.3/bin/pgsql2shp -h localhost -p 5432 -u ${user}

# ogr for dbf's since Postgis is screwed up now.
ogrdsn:=PG:"dbname=${database}"
ogr_dbf:=ogr2ogr -overwrite -f "PostgreSQL" PG:"dbname=${database}"
db2kml:=ogr2ogr -overwrite -f KML 

# We use a projection that doesn't come standard in the postgis
# database, so we need to add it in here.  It is the contiguous albers
# equal area projection.  ESRI uses the folloinwg code for the
# projection.
srid:=102004
srid-prj:=PROJCS["USA_Contiguous_Lambert_Conformal_Conic",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-96],PARAMETER["Standard_Parallel_1",33],PARAMETER["Standard_Parallel_2",45],PARAMETER["Latitude_Of_Origin",39],UNIT["Meter",1]]
srid-url:=http://spatialreference.org/ref/esri/${srid}/postgis/
# This is what you get.
#INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 9102004, 'esri', 102004, '+proj=lcc +lat_1=33 +lat_2=45 +lat_0=39 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Lambert_Conformal_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_2SP"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-96],PARAMETER["Standard_Parallel_1",33],PARAMETER["Standard_Parallel_2",45],PARAMETER["Latitude_Of_Origin",39],UNIT["Meter",1],AUTHORITY["EPSG","102004"]]');

# This is seutp to be the first item to get run. 
.PHONY: configure.INFO
configure.INFO:
	@echo This is the configure makefile
	@echo configure.mk:=${configure.mk}
	@echo srid:=${srid}	

# This should be moved somewhere
.PHONY: db
#db::db/public

# And this
db/public:
	wget -nv -O - ${srid-url} | ${PG}
	wget -nv -O - ${srid-url} | sed -e 's/9102004/102004/' | ${PG}
	${PG} -f configure/schema.sql
	touch $@

define add_schema_cmd
	${PG} -f $1/schema.sql
endef

define add_schema_rule
${db}/$1:
	$(call add_schema_cmd,$1)
	touch ${db}/$1
endef


define fetch_zip 
	[[ -f ${down}/$2 ]] || ( cd ${down}; wget $1/$2; unzip $2 )
endef

define add_dbf_cmd
	${PG} -c 'drop table if exists $1 cascade '
	${ogr_dbf} $2 -nln $1
	${PG} -c 'alter table $1 rename ogc_fid to gid'
#	${shp2pgsql} -d -n $2 $1 | ${PG} > /dev/null
endef

define add_dbf_rule
db/$1:${down}/$2
	$(call add_dbf_cmd,$1,${down}/$2)
	touch db/$1
endef

#bts has a function for shapefiles, we might use.
