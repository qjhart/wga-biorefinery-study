#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
# include 'bts.mk'
ifndef db
include configure.mk
endif

# for county def
ifndef national_atlas
include national_atlas.mk
endif

cmz.url:=ftp://fargo.nserl.purdue.edu/pub/RUSLE2/Crop_Management_Templates/CMZ%20maps/CMZ%20map%20shape%20files/

cmz.prj:=999999	quinn	999999	PROJCS["NAD_1927_Albers",GEOGCS["GCS_North_American_1927",DATUM["D_North_American_1927",SPHEROID["Clarke_1866",6378206.4,294.9786982]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Albers"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-96.0],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["Latitude_Of_Origin",23.0],UNIT["Meter",1.0]]	+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0 +lon_0=-96 +x_0=0 +y_0=0 +ellps=clrk66 +datum=NAD27 +units=m +no_defs

INFO::
	@echo Crop Management Zone Data
	@echo   from ${cmz.url}

.PHONY:db

db::${db}/cmz.zones ${db}/cmz.cmz_county ${db}/cmz.county_percentage;

${db}/cmz:
	${PG} -f cmz/schema.sql
	touch $@

${db}/cmz.zones: ${db}/cmz
	$(call fetch_zip,${cmz.url},CMZ110104.zip)
	${shp2pgsql} -d -s 999999 -S -g the_geom -S -I ${down}/cmz110104.shp cmz.zones | ${PG} > /dev/null;
	${PG} -c "select AddGeometryColumn('cmz','zones','boundary',$(srid),'POLYGON',2); update cmz.zones set boundary=transform(the_geom,${srid}); create index zones_boundary_gist on cmz.zones using gist(boundary gist_geometry_ops);"
	touch $@

${db}/cmz.cmz_county: ${db}/cmz.zones
	${PG} -c "create table cmz.cmz_county as select fips,cmz,intersection(z.boundary,c.boundary) as intersection from cmz.zones z join network.county c on z.boundary &&  c.boundary and ST_Intersects(z.boundary,c.boundary);"
	touch $@

${db}/cmz.county_percentage:
	${PG} -c 'create table cmz.county_percentage as select fips,cmz,sum((area(intersection)*20/area(c.boundary))::integer*5) as percentage from cmz.cmz_county join network.county as c using (fips) group by fips,cmz having sum((area(intersection)*20/area(c.boundary))::integer*5) > 0'
	touch $@;

${out}/cmz.county_percentage.csv:${db}/cmz.county_percentage
	${PG-CSV} -c 'select fips,cmz,percentage from cmz.county_percentage' > $@

${out}/cmz.county_max.csv:
	${PG-CSV} -c 'select c.fips,c.cmz,c.percentage from cmz.county_percentage c join (select fips,max(percentage) as max from cmz.county_percentage group by fips) as max on (c.fips=max.fips and c.percentage=max.max);' > $@
