#! /usr/bin/make -f
ifndef db
include configure.mk
endif

INFO::
	@echo PIER Makefile
	@echo -- Includes DWR Landuse Map
	@echo 

${db}/pier:
	${PG} -c "create schema pier"
	touch $@;

${db}/pier.landuse_06_2:s:=pier
${db}/pier.landuse_06_2:t:=landuse_06_2
${db}/pier.landuse_06_2:shp:=pier/bdwrld06_2
${db}/pier.landuse_06_2:${db}/%: ${db}/pier
# From last PIER geodatabase file::/natmapa/PIER2007/geodata/biomass.gdb
#	[[ -f ${down}/${tgz} ]] || ( cd ${down}; wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/${tgz}; tar -xzf ${tgz} )
	# save Temp version
	${shp2pgsql} -D -d -s 3310 -g teale -S ${down}/${shp}.shp $s.$t | ${PG} > /dev/null
	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'POLYGON',2);"
	${PG} -c "update $* set boundary=transform(teale,${srid});"
	touch $@

${out}/landuse_centroids.shp:${out}/%: ${db}/pier.landuse_06_2
	${pgsql2shp} -f $@ ${database} "select class1 as class,subclass1 as subclass,type1 as type,CASE WHEN pcnt1='00' THEN area(boundary) ELSE pcnt1::float*area(boundary) END as area,centroid(boundary) as centroid from pier.landuse_06_2 where type1 is not null and pcnt1 <> '**' union select class2 as class,subclass2 as subclass,type2 as type,CASE WHEN pcnt2='00' THEN area(boundary) ELSE pcnt2::float*area(boundary) END as area,centroid(boundary) as centroid from pier.landuse_06_2 where type2 is not null and pcnt2 <> '**' union select class3 as class,subclass3 as subclass,type3 as type,CASE WHEN pcnt3='00' THEN area(boundary) ELSE pcnt3::float*area(boundary) END as area,centroid(boundary) as centroid from pier.landuse_06_2 where type1 is not null and pcnt3 <> '**'"
