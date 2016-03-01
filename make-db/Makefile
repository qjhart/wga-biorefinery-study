#! /usr/bin/make --include-dir=src -f

# This is the default Makefile for everything.  You need to specify
ifndef configure.mk
include configure.mk
endif
ifndef network.mk
include network.mk
endif
ifndef feedstock.mk
include feedstock.mk
endif
ifndef model.mk
include model.mk
endif


# Here are some projections not used in the standard postgis setup.
${db}/srid.sql: 
	# USA_Contiguous_AEA
	${PG} -c "delete from spatial_ref_sys where srid=102008"
	${PG} -c "insert into spatial_ref_sys (srid,auth_name,auth_srid,srtext,proj4text) values (102008,'esri',102008,'PROJCS[\"North_America_Albers_Equal_Area_Conic\",GEOGCS[\"GCS_North_American_1983\",DATUM[\"D_North_American_1983\",SPHEROID[\"GRS_1980\",6378137.0,298.257222101]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Albers\"],PARAMETER[\"False_Easting\",0.0],PARAMETER[\"False_Northing\",0.0],PARAMETER[\"Central_Meridian\",-96.0],PARAMETER[\"Standard_Parallel_1\",20.0],PARAMETER[\"Standard_Parallel_2\",60.0],PARAMETER[\"Latitude_Of_Origin\",40.0],UNIT[\"Meter\",1.0]]','+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs <>');"
	# USA_Contiguous_LCC
	${PG} -c "delete from spatial_ref_sys where srid=102004"
	${PG} -c "insert into spatial_ref_sys (srid,auth_name,auth_srid,srtext,proj4text) values (102004,'esri',102004,'PROJCS[\"USA_Contiguous_Lambert_Conformal_Conic\",GEOGCS[\"GCS_North_American_1983\",DATUM[\"North_American_Datum_1983\",SPHEROID[\"GRS_1980\",6378137,298.257222101]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Lambert_Conformal_Conic_2SP\"],PARAMETER[\"False_Easting\",0],PARAMETER[\"False_Northing\",0],PARAMETER[\"Central_Meridian\",-96],PARAMETER[\"Standard_Parallel_1\",33],PARAMETER[\"Standard_Parallel_2\",45],PARAMETER[\"Latitude_Of_Origin\",39],UNIT[\"Meter\",1],AUTHORITY[\"EPSG\",\"102004\"]]','+proj=lcc +lat_1=33 +lat_2=45 +lat_0=39 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs');"
	${PG} -c "select * from spatial_ref_sys where srid in (102008,102004)" > $@


#CREATE SCHEMA network
#       AUTHORIZATION quinn;
#COMMENT ON SCHEMA network IS 'This schema holds information about the transportation network.';
#GRANT USAGE ON SCHEMA network TO public;
#CREATE SCHEMA tmp
#       AUTHORIZATION quinn;
#COMMENT ON SCHEMA tmp IS 'Temporary files.';



