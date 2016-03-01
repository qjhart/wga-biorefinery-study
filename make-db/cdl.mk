#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

INFO::
	@echo NASS Cropland Data Layer

########################################################################
# NASS data is downloaded into zip files manually.  The data comes from 
########################################################################
${db}/cdl:
	${PG} -f cdl/schema.sql
	${PG} -c 'insert into cdl.class select distinct class_name from pfarm.scp';
	touch $@


${db}/cdl.gcdl_2007:s:=cdl
${db}/cdl.gcdl_2007:t:=cdl_2007
${db}/cdl.gcdl_2007:shp:=land_use_land_cover_NASS_CDL_756434_01/img&tiff/cdl_ca_2007
${db}/cdl.gcdl_2007:${db}/%: ${db}/cdl
	# save Temp version
	${shp2pgsql} -D -d -s 4326 -g nad83 -S ${shp}.shp $s.$t | ${PG} > /dev/null
	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'POLYGON',2);"
	${PG} -c "update $* set boundary=transform(nad83,${srid});"
	touch $@

# Newest data from
# http://www.nass.usda.gov/research/Cropland/Release/NASS_2008_CDL.zip

${db}/cdl.cdl_2007:s:=cdl
${db}/cdl.cdl_2007:t:=cdl_2007
${db}/cdl.cdl_2007:shp:=downloads/8co_iowa_cdl downloads/6co_ks_cdl
${db}/cdl.cdl_2007:${db}/%:
	# save Temp version
	for i in ${shp}; do \
	  ${shp2pgsql} -D -d -s 32615 -g nad83 -S $$i.shp cdl.`basename $$i` | ${PG} > /dev/null; \
	done;
#	${PG} -c "select AddGeometryColumn('tmp','iowa','boundary',$(srid),'POLYGON',2); update tmp.iowa set boundary=transform(nad83,${srid}); create index iowa_boundary_gist on tmp.iowa using gist(\"boundary\" gist_geometry_ops);"
