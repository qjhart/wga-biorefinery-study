#! /usr/bin/make -f
####################################################################
# TODO
#
# I need to snap everything to a grid so that we can get things to
# line up for ESRI with having to run the integrate step.  Even so,
# there is a problem with the connectors still.  I need to
# reinvestigate whether we can do that step in postgis.  I don't know
# why it's such a problem.  For the network, it might be best to run a
# great simple simplification on the networks, and eliminate most
# points.

#####################################################################
# You should be able to run this script either in Linux or on
# windows, with a properly configured cygwin implementation.  For the
# cygwin implementation, I used the native windows psql version, which
# works fine.  This script uses dbview, which can be compiled
# in cygwin, and is located
# at. ftp.infodrom.north.de:/pub/Linux/Devel/dbview-1.0.3.tar.gz or
# using debian with apt-get source dbview (which is what I did, then
# compiled on cygwin)
#####################################################################

db:= wga
PG:=psql -d $(db)

# Archive files - Right now, not everything can be built from the
# Makefile alone.  We need to include extra files in the distribution,
# so someone else can replicate the process.
archive:=wga.tgz
# These files are spread out thru the program, look for this variable.
archive-files:=Makefile

.PHONY: default
default:
	echo Have to make something

.PHONY: db
db: db.sql srid.sql
# Only for UNIX version, don't do this in windows.  On windows
# databases are created by default with the postgis stuff installed,
# if you've set that up properly. So create the database via pgadmin.
# Thats probably the way to to it in Unix too, but I haven't modified
# the template for that.
db.sql:
	pg_dump $(db) > $@.sql.save
	dropdb $(db)
	createdb $(db)
	createlang plpgsql -d $(db)
	$(PG) -f /usr/share/postgresql-8.2-postgis/lwpostgis.sql
	$(PG) -f /usr/share/postgresql-8.2-postgis/spatial_ref_sys.sql
#	$(PG) -c 'grant all on geometry_columns to $(user)'
#	$(PG) -c 'grant select on spatial_ref_sys to $(user)'
	${PG} -c '\d' > $@


# We use a projection that doesn't come standard in the postgis
# database, so we need to add it in here.  It is the contiguous albers
# equal area projection.  ESRI uses the folloinwg code for the
# projection.
srid:=102008
srid.sql: 
	${PG} -c "delete from spatial_ref_sys where srid=$(srid)"
	${PG} -c "insert into spatial_ref_sys (srid,auth_name,auth_srid,srtext,proj4text) values (102008,'esri',102008,'PROJCS[\"North_America_Albers_Equal_Area_Conic\",GEOGCS[\"GCS_North_American_1983\",DATUM[\"D_North_American_1983\",SPHEROID[\"GRS_1980\",6378137.0,298.257222101]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Albers\"],PARAMETER[\"False_Easting\",0.0],PARAMETER[\"False_Northing\",0.0],PARAMETER[\"Central_Meridian\",-96.0],PARAMETER[\"Standard_Parallel_1\",20.0],PARAMETER[\"Standard_Parallel_2\",60.0],PARAMETER[\"Latitude_Of_Origin\",40.0],UNIT[\"Meter\",1.0]]','+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs <>');"
	${PG} -c "select * from spatial_ref_sys where srid=${srid}" > $@

define check_or_make_table
	if ( ! ${PG} -c '\d $1' > /dev/null); then\
	 echo -e "$(2)" | sed -e 's/^\s* //' | psql -d $(db); \
	fi;
endef


# define wga_states.sql
# CREATE TABLE wga_states (
#     state character(2),
#     state_fips character(2) primary key,
#     state_name character varying(32)
# );
# COPY wga_states (state, state_fips, state_name) FROM stdin;
# AK	02	Alaska
# AZ	04	Arizona
# CA	06	California
# CO	08	Colorado
# HI	15	Hawaii
# ID	16	Idaho
# KS	20	Kansas
# MT	30	Montana
# ND	38	North Dakota
# NE	31	Nebraska
# NM	35	New Mexico
# NV	32	Nevada
# OK	40	Oklahoma
# OR	41	Oregon
# SD	46	South Dakota
# TX	48	Texas
# UT	49	Utah
# WA	53	Washington
# WY	56	Wyoming
# \.
# endef

.PHONY: wga_states
wga_states:
	$(call check_or_make_table,wga_states,$(wga_states.sql))

city_parameter_definitions.sql:=\
CREATE TABLE city_parameter_definitions (\
    parameter varchar(128),\
    network boolean,\
    feedstock boolean,\
    similar_facility boolean,\
    biomass_refinery boolean,\
    definition varchar(1000));\
COPY city_parameter_definitions (parameter,network,feedstock,similar_facility,biomass_refinery,definition) FROM stdin;\n\
biopower_facility	t	f	t	f	WGA Existing biopower facility (from Antares)\n\
cbc.ethanol	t	f	t	t	CBC exisiting biomass facilities\n\
cbc.bdircomb05_83	t	f	t	t	CBC exisiting biomass facilities\n\
cbc.msw	t	t	t	f	Locations of MSW sources from Rob\n\
cbc.sewage	t	f	f	f	Waste-water treatment plant in CA\n\
cbc.swis	f	f	f	f	SWIS location of solid waste facility\n\
epa_facility	t	f	t	f	City has a existing EPA Facility of SIC CODE in (2421,2429,2431,2077,2011,2013,5147,2041,2046,2075,2076,2074,2611,2631)\n\
ethanol_facilities	t	f	t	f	WGA Existing ethanol facilities (Antares)\n\
facility	t	f	f	f	BTS Road/Rail/Marine loading or Intermodal facility\n\
feed_mar	t	f	f	f	Feedstock Marine Terminal\n\
fuel_mar	t	f	f	f	Marine terminal for fuel\n\
municipal_source	t	t	f	f	WGA MSW Source\n\
petroleum_refinery_facility	t	f	f	f	Existing Petreoleum refinery location\n\
population	t	f	f	f	Population > 10000\n\
ports	t	f	f	f	Existing port\n\
rail_im	t	f	f	f	Road-Rail Intermodal Facility\n\
terminals	t	f	t	f	BioFuel Product Terminal\n\
with_railway	f	f	f	f	City as rail located < 12 km from town\n\
with_road	f	f	f	f	Has road < 5km from center\n\
\.\n

city_parameter_definitions.csv:%.csv:
	${PG} -c "drop table $*";
	$(call check_or_make_table,$*,${city_parameter_definitions.sql})
	${PG} -c "copy $* to STDOUT WITH CSV HEADER" >$@

feedstock_group_yield.sql:=\
CREATE TABLE feedstock_group_yield (\n\
    group_type character varying(32),\n\
    conversion character varying(32),\n\
    yield double precision\n\
);\n\
COPY feedstock_group_yield (group_type, conversion,yield) FROM stdin;\n\
grains	GE_dry	100\n\
grains	GE_wet	89\n\
stover	LCE	80.6\n\
stover	LCMD	36.8\n\
stover	LCG	21.6\n\
straw	LCE	76.8\n\
straw	LCMD	38.7\n\
straw	LCG	21.6\n\
OVW	LCE	76.9\n\
OVW	LCMD	40.6\n\
OVW	LCG	22\n\
forest	LCE	90.2\n\
forest	LCMD	42\n\
forest	LCG	22\n\
msw_paper	LCE	86\n\
msw_paper	LCMD	37.1\n\
msw_paper	LCG	23.2\n\
msw_wood	LCE	78.9\n\
msw_wood	LCMD	41.5\n\
msw_wood	LCG	22\n\
msw_yard	LCE	70\n\
msw_yard	LCMD	31.6\n\
msw_yard	LCG	21.6\n\
msw_total	LCMD	42.5\n\
msw_total	LCG	21.6\n\
msw_dirty	LCMD	42.5\n\
msw_dirty	LCG	21.6\n\
HEC	LCE	77.4\n\
HEC	LCMD	42.5\n\
HEC	LCG	21.6\n\
grease	FAME	249\n\
grease	FAHC	250\n\
oils	FAME	260\n\
oils	FAHC	250\n\
tallow	FAME	260\n\
tallow	FAHC	250\n\
\.\n

feedstock_group_yield.csv:%.csv:
	$(call check_or_make_table,$*,${feedstock_group_yield.sql})
	${PG} -c "copy $* to STDOUT WITH CSV HEADER" >$@

feedstock_group.sql:=\
CREATE TABLE feedstock_group (\n\
    type character varying(32),\n\
    group_type character varying(32)\n\
);\n\
COPY feedstock_group (type, group_type) FROM stdin;\n\
biosolids	biosolids\n\
corngrain	corn\n\
barley	straw\n\
oats	straw\n\
rye	straw\n\
swheatstraw	straw\n\
wwheatstraw	straw\n\
cornstover	stover\n\
low_forest	forest\n\
high_forest	high_forest\n\
OVW	OVW\n\
HEC	HEC\n\
HEC_h	HEC_h\n\
msw_wood	msw_wood\n\
msw_paper	msw_paper\n\
msw_yard	msw_yard\n\
msw_dirty	msw_dirty\n\
tallow	tallow\n\
grease	grease\n\
soybean_oil	soybean_oil\n\
canola_oil	canola_oil\n\
HEC	lce\n\
OVW	lce\n\
barley	lce\n\
canola_oil	oils\n\
corngrain	grains\n\
cornstover	lce\n\
grease	oils\n\
low_forest	lce\n\
msw_paper	lce\n\
msw_wood	lce\n\
msw_yard	lce\n\
oats	lce\n\
rye	lce\n\
soybean_oil	oils\n\
swheatstraw	lce\n\
tallow	oils\n\
wwheatstraw	lce\n\
MSW All non-Film Plastic	cbc_msw_fac_plastic\n\
MSW Leaves & Grass	cbc_msw_lc\n\
MSW Paper/ Cardboard	cbc_msw_fac_paper\n\
MSW Other Biomass/ Composite	cbc_msw_fac_other\n\
MSW Branches & Stumps	cbc_msw_lc\n\
MSW Film Plastic	cbc_msw_fac_film_plastic\n\
MSW C&D Lumber	cbc_msw_fac_lumber\n\
MSW Food Waste	cbc_msw_fac_food\n\
MSW Textiles & Carpet	cbc_msw_fac_textiles\n\
MSW Prunings, Trimmings	cbc_msw_lc\n\
cbc_animal_manure	cbc_animal_manure\n\
cbc_cotton	cbc_cotton\n\
cbc_dfw	cbc_dfw\n\
cbc_forest	cbc_forest\n\
cbc_msw_food	cbc_msw_food\n\
cbc_msw_mixed	cbc_msw_mixed\n\
cbc_msw_paper	cbc_msw_paper\n\
cbc_msw_wood	cbc_msw_wood\n\
cbc_msw_yard	cbc_msw_yard\n\
cbc_ovw	cbc_ovw\n\
cbc_pummace	cbc_pummace\n\
cbc_rice	cbc_rice\n\
cbc_stover	cbc_stover\n\
cbc_straw	cbc_straw\n\
cbc_tuber	cbc_tuber\n\
cbc_vegetable	cbc_vegetable\n\
\.\n

feedstock_group.csv:%.csv:
	$(call check_or_make_table,$*,$(feedstock_group.sql))
	${PG} -c "copy $* to STDOUT WITH CSV HEADER" >$@


####################################################################
# Location Standardization.  There are many datasets that need to be
# located to s sinlge city in the citiesx020 database.  The following
# setup will match first on the city name and second on the location.
# Output are fipscodes for the table, and additions to the
# city_parameters file.  Also unlinked locations and distances are
# saved.
# $1 = table_name 
# $2 = table identifier 
# $3 = table_state_code_column
# $4 = table city column
# $5 = set to NAD83 if points exist, LL otherwise

####################################################################
define add_fips_cmds
	$(call check_or_make_table,wga_states,$(wga_states.sql))
	$(PG) -c "update $1 f set qid=cx.qid from city cx where f.$3=cx.state and lower(f.$4)=lower(cx.name) and f.$3 in (select state from wga_states);";\
	$(PG) -c 'drop view $1_unlinked' || true;\
	if [[ -n "$5" ]]; then \
	 if [[ "$5" == 'LL' ]];\
	  then  \
	    ${PG} -c "create view $1_unlinked as select f.$2,f.$3,f.$4,transform(GeomFromEWKT('SRID=4326;Point('||f.longitude||' '||f.latitude||')'),$(srid)) as centroid from (select $2,$3,$4,avg(longitude) as longitude,avg(latitude) as latitude from $1 group by $2,$3,$4) as f left join city cx on (f.$3=cx.state and lower(f.$4)=lower(cx.name)) where f.$3 in (select state from wga_states) and cx is null;"; \
	  else if [[ "$5" == 'nad83' ]]; then \
	    ${PG} -c "create view $1_unlinked as select f.$2,f.$3,f.$4,transform(f.$5,$(srid)) as centroid from $1 f left join city cx on (f.$3=cx.state and lower(f.$4)=lower(cx.name)) where f.$3 in (select state from wga_states) and cx is null;";\
	  else\
	    ${PG} -c "create view $1_unlinked as select f.$2,f.$3,f.$4,f.$5 as centroid from $1 f left join city cx on (f.$3=cx.state and lower(f.$4)=lower(cx.name)) where f.$3 in (select state from wga_states) and cx is null;";\
	  fi;\
	 fi;\
	 $(PG) -c 'drop table $1_unlinked_distance' || true;\
	 ${PG} -c 'create table $1_unlinked_distance as select l.$2,l.centroid,min(distance(l.centroid,c.centroid)) as min from $1_unlinked l, city c where c.state=l.$3 group by l.$2,l.centroid;';\
	 ${PG} -c "update $1 f set qid=cx.qid from city cx join $1_unlinked_distance l on (distance(cx.centroid,l.centroid)=l.min) where f.$2=l.$2;";\
	fi;\
	$(call redo_city_parameters,$1)
endef

############################################################################
# Standard Method of building connector shapefiles.  Already in the
# right projections.  There are three things we connect to road,
# railway and marine.
############################################################################
define make_connector_cmds
	${PG} -c "drop table $2_$1_connector" || true
	 time ${PG} -c "create table $2_$1_connector as select $4,r.gid,line_interpolate_point(r.aea,line_locate_point(r.aea,c.centroid)) as near,distance(c.centroid,r.aea) as distance from $2 c, $1 r where c.$1_connector is Null and distance(c.centroid,envelope(r.aea)) < $3";
	time ${PG} -c "delete from $2_$1_connector c where distance!=(select min(distance) from $2_$1_connector where $4=c.$4)";
	time ${PG} -c "delete from $2_$1_connector c where distance>$3";
	time ${PG} -c "update $2 c set $1_connector=MakeLine(c.centroid,cn.near) from $2_$1_connector cn where c.$4=cn.$4"
	${PG} -c "drop table $2_$1_connector"
	if [[ ! -z '$5' ]]; then more=`echo "|$5" | tr '|' ','`; fi; pgsql2shp -g $1_connector -f $2_$1_connector.shp $(db) "select $4,$1_connector$$more from $2 where $1_connector is not Null and length($1_connector) <> 0"
endef

define new_centroid_cmds
	${PG} -c "drop table $2_$1_centroid" || true
	 time ${PG} -c "create table $2_$1_centroid as select $4,r.gid,line_interpolate_point(r.aea,line_locate_point(r.aea,c.centroid)) as near,distance(c.centroid,r.aea) as distance from $2 c, $1 r where c.$1_centroid is Null and distance(c.centroid,envelope(r.aea)) < $3";
	time ${PG} -c "delete from $2_$1_centroid c where distance!=(select min(distance) from $2_$1_centroid where $4=c.$4)";
	time ${PG} -c "update $2 c set $1_centroid=cn.near from $2_$1_centroid cn where c.$4=cn.$4"
	${PG} -c "drop table $2_$1_centroid"
#	if [[ ! -z '$5' ]]; then more=`echo "|$5" | tr '|' ','`; fi; pgsql2shp -g $1_centroid -f $2_$1_connector.shp $(db) "select $4,$1_centroid$$more from $2 where $1_centroid is not Null"
endef

define from_shp
.PHONY: $(notdir $1)
$(notdir $1).shp: $(patsubst %,$1.%,shp shx dbf)
	shp2pgsql -D -d -s $(srid) -S -I -g aea $1.shp public.$(notdir $1) | ${PG} > /dev/null;
	pgsql2shp -g aea -f $$@ $(db) $(notdir $1)
endef

marine.shp:%.shp:$(patsubst %,input/marine.%,shp shx dbf)
	shp2pgsql -D -d -s $(srid) -I -g the_geom $< public.$* | ${PG} > /dev/null; \
	${PG} -c "select AddGeometryColumn('public','$*','aea',$(srid),'LINESTRING',2);";\
	${PG} -c "update $* set aea=GeometryN(the_geom,1); insert into $* (linkname,rivername,aea) select linkname,rivername,GeometryN(the_geom,2) from $* where NumGeometries(the_geom)>1;";\
	pgsql2shp -g aea -f $@ $(db) $*

#$(eval $(call from_shp,county_centroid,county_centroid))
# Reimport Costs

# These two are bad, and should not have to be done.
$(eval $(call from_shp,../transportation_costs/seedoil_potential_location_100gal_road_odcost));
$(eval $(call from_shp,../transportation_costs/seedoil_potential_location_100gal_min_odcost));
 
# This is for Mui's roads layers ! FRACK!
$(eval $(call from_shp,input/road))
$(eval $(call from_shp,input/railway))
#$(eval $(call from_shp,marine)) Nope SPECIAL

###########################################################################
# Anything special about a city is added to the city_parameters table.
# This allows us to figure out which cities have what services.  
###########################################################################
define delete_city_parameters
	if ( ! ${PG} -c '\d city_parameters' > /dev/null); then \
	  ${PG} -c 'create table city_parameters (qid varchar(8),parameter varchar(128),primary key(qid,parameter));';\
	fi;\
	${PG} -c "delete from city_parameters where parameter='$1'";
endef

define redo_city_parameters
	if ( ! ${PG} -c '\d city_parameters' > /dev/null); then \
	  ${PG} -c 'create table city_parameters (qid varchar(8),parameter varchar(128),primary key(qid,parameter));';\
	fi;\
	${PG} -c "delete from city_parameters where parameter='$1'";\
	${PG} -c "insert into city_parameters (qid,parameter) select distinct qid,'$1' from $1 where qid is not null;";
endef

#######################################################################
# New Secret datasets
# Citation?
#######################################################################
terminals.shp:%.shp:input/%.csv city_locate_only.shp
	@${PG} -c 'drop table $*' || true;
	$(call check_or_make_table,wga_states,$(wga_states.sql))
	@${PG} -c 'create table $* (qid char(8),company integer, city varchar(50),state char(2));'
	cat $< | $(PG) -c "copy $* (company,city,state) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";
	$(PG) -c "update $* f set qid=cx.qid from city cx where f.state=cx.state and lower(f.city)=lower(cx.name) and f.state in (select state from wga_states);";
	$(call redo_city_parameters,$*)
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2); update $* t set centroid=cx.centroid from city cx where t.qid=cx.qid"
	pgsql2shp -g centroid -f $@ $(db) 'select * from $* where centroid is not null'

#########################################################################
# Existing ethanol facilities from Antares
#########################################################################
ethanol_facilities.shp:%.shp:input/wga_etoh_fac.shp city_locate_only.shp
	@${PG} -c 'drop table $* CASCADE' || true;
	$(call check_or_make_table,wga_states,$(wga_states.sql))
	shp2pgsql -d -s 4326 -S -g nad83 -S -I $< public.$* | ${PG} > /dev/null;
	$(PG) -c "alter table $* add column qid varchar(8);";
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2);";
	${PG} -c "update $* set centroid=transform(nad83,${srid});";
	# Fixup the capacity
	${PG} -c "alter table $* rename column capacity to cap_str";
	${PG} -c "alter table $* add column capacity float";
	${PG} -c "update ethanol_facilities set capacity=cast(replace(cap_str,',','') as float)";
	# Erase duplicates
	${PG} -c "delete from ethanol_facilities where gid in (select max(gid) from ethanol_facilities group by bg_lat,bg_long having count(*) > 1)";
	# delete bad record;
	${PG} -c 'delete from $* where id is NULL'
	$(call add_fips_cmds,$*,gid,state,city,nad83)
	$(call redo_city_parameters,$*)
	pgsql2shp -g centroid -f $@ $(db) 'select * from $* where centroid is not null'


########################################################################
#
# UC Davis Data
########################################################################
archive-files+=petroleum_refineries.csv
petroleum_refinery_facility_table:=create table petroleum_refinery_facility (\
	p_id serial primary key,\
	company varchar(128),\
	state varchar(2),\
	state_name varchar(32),\
	city varchar(128),\
	size float,\
	qid char(8));

petroleum_refinery_facility.shp: %.shp: input/%.csv
	$(PG) -c 'drop table $*' || true
	$(call check_or_make_table,wga_states,$(wga_states.sql))
	${PG} -c '${petroleum_refinery_facility_table}'
	cat $< | $(PG) -c "copy $* (company,state_name,city,size) FROM STDIN WITH DELIMITER AS ',' CSV HEADER"
	# Add in state abbreviations
	${PG} -c "update petroleum_refinery_facility p set state=w.state from wga_states w where p.state_name=w.state_name;"
	${PG} -c "select AddGeometryColumn('public','petroleum_refinery_facility','nad83',4326,'POINT',2);"
	${PG} -c "select AddGeometryColumn('public','petroleum_refinery_facility','centroid',$(srid),'POINT',2);"
	# These are the missing towns
	${PG} -c "update petroleum_refinery_facility set nad83=GeomFromEWKT('SRID=4326;Point(-118.261667 33.78)') where state_name='California' and lower(city)='wilmington';"
	${PG} -c "update petroleum_refinery_facility set nad83=GeomFromEWKT('SRID=4326;Point(-115.294167 36.141575)') where state_name='Nevada' and lower(city)='eagle springs';"
	${PG} -c "update petroleum_refinery_facility set nad83=GeomFromEWKT('SRID=4326;Point(-158.081940 21.334250)') where state_name='Hawaii' and lower(city)='kapolei';"
	${PG} -c "update petroleum_refinery_facility set nad83=GeomFromEWKT('SRID=4326;Point(-148.916667 70.416667)') where state_name='Alaska' and lower(city)='kuparuk';"
	${PG} -c "update petroleum_refinery_facility set centroid=transform(nad83,${srid}) where nad83 is not null;"
	$(call add_fips_cmds,petroleum_refinery_facility,p_id,state,city,nad83)
	pgsql2shp -g centroid -f $@ $(db) $*

##############################################################################
#
# Municipal Supplies
###############################################################################

#define seed_network
#$1_network: $1_extraction_facilities.shp $1_feedstock_sources.shp
#$1_extraction_facilities.shp:%.shp:epa_facility.shp
#	pgsql2shp -g centroid -f $1_extraction_facilities.shp $(db) 'select distinct qid,cx.centroid from epa_facility e join city cx using (qid) where sic_code in ($3)'
#
#$1_feedstock_sources.shp:%.shp:input/$1_feedstock_sources.dbf
#	$(PG) -c 'drop table $$*' || true
#	$(PG) -c 'create table $$* (qid char(8),state_fips char(2),county_fips varchar(3),fips_code char(5),type varchar(255),proj2015 float);' 
#	dbview -b -d',' input/$$*.dbf | perl -F',' -a -n -e 'printf "%02d,%03d,%02d%03d,$1,%f\n",$$$$F[5],$$$$F[7],$$$$F[5],$$$$F[7],$$$$F[19]/$2' | $(PG) -c "copy $$* (state_fips,county_fips,fips_code,type,proj2015) FROM STDIN DELIMITER AS ',' CSV"
#	${PG} -c "update $$* set qid='S'||fips_code;";
#	pgsql2shp -g centroid -f $$*.shp $(db) 'select s.*,c.centroid from $$* s join county c using (qid);'
#endef

# seed,to tons,SIC
#$(eval $(call seed_network,canola,2000,2076))
#$(eval $(call seed_network,soybean,(2000/60),2075))

feedstock_seed.shp:%.shp:input/canola_co.csv input/soy_co.csv 
	${PG} -c 'drop table $*' || true;
	$(PG) -c 'create table $* (qid char(8),type varchar(32),state_fips char(2),fips55 char(5),cost float,amount float);'
	cat input/canola_co.csv | perl -n -a -F/,/ -e 'printf("canola,%2.2d,%2.2d%3.3d,%f,%f\n",$$F[2],$$F[2],$$F[3],$$F[7]*2000,$$F[6]/2000) if ($$F[3] and $$F[6]!=0)' | $(PG) -c "copy $* (type,state_fips,fips55,cost,amount) FROM STDIN CSV"
	cat input/soy_co.csv | perl -n -a -F/,/ -e 'printf("soybean,%2.2d,%2.2d%3.3d,%f,%f\n",$$F[2],$$F[2],$$F[3],$$F[8]*2000,$$F[7]/2000) if ($$F[3] and $$F[7]!=0)' | $(PG) -c "copy $* (type,state_fips,fips55,cost,amount) FROM STDIN CSV"
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2); update $* s set qid=c.qid,centroid=c.centroid from county c where 'S'||s.fips55=c.qid"
	pgsql2shp -g centroid -f $*.shp $(db) $*

seedoil_extraction_facilities.shp:%.shp:epa_facility.shp
	pgsql2shp -g centroid -f $*.shp $(db) "select distinct qid,'canola'::varchar(30),cx.centroid from epa_facility e join city cx using (qid) where sic_code in (2076) join select distinct qid,'soybean'::varchar(30),cx.centroid from epa_facility e join city cx using (qid) where sic_code in (2075)"

seedoil_feedstock.shp:%.shp: transportation_costs/canola_road_cost.shp transportation_costs/canola_min_cost.shp transportation_costs/soybean_road_cost.shp transportation_costs/soybean_min_cost.shp feedstock_seed.shp
	${PG} -c 'drop table $*' || true;
	# Get Transportation Costs
	for i in canola_road_cost canola_min_cost soybean_road_cost soybean_min_cost; do \
	  shp2pgsql -D -d -s $(srid) -S -I -g centroid transportation_costs/$$i.shp public.$$i | ${PG};\
	done;
	${PG} -c "create table $* as select 'M'||substr(name,position(' - ' in name)+4,100) as qid,'canola' as type,sum(f.amount) as total_wetton,sum(r.total_wet_*f.amount) as road_cost,sum(r.total_wet_*f.amount)/sum(f.amount) as avg_road_cost_wetton,sum(m.total_wet_*f.amount) as min_cost,sum(m.total_wet_*f.amount)/sum(f.amount) as avg_min_cost_wetton from canola_road_cost r full outer join canola_min_cost m using (name) join feedstock_seed f on (trim( both from substr(name,1,position(' - ' in name)))=f.qid and f.type='canola') group by substr(name,position(' - ' in name)+4,100) union select 'M'||substr(name,position(' - ' in name)+4,100) as source_id,'soybean' as type,sum(f.amount) as total_wetton,sum(r.total_wet_*f.amount) as road_cost,sum(r.total_wet_*f.amount)/sum(f.amount) as avg_road_cost_wetton,sum(m.total_wet_*f.amount) as min_cost,sum(m.total_wet_*f.amount)/sum(f.amount) as avg_min_cost_wetton from soybean_road_cost r full outer join soybean_min_cost m using (name) join feedstock_seed f on (trim(both from substr(name,1,position(' - ' in name)))=f.qid and f.type='soybean') group by substr(name,position(' - ' in name)+4,100);"
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2); update $* s set centroid=cx.centroid from city cx where s.qid='M'||substr(cx.qid,2,7)"
	for i in canola_road_cost canola_min_cost soybean_road_cost soybean_min_cost; do ${PG} -c "drop table $$i" || true; done
	pgsql2shp -g centroid -f $*.shp $(db) $*

municipal_source.shp:%.shp: feedstock.shp city_locate_only.shp
	$(call delete_city_parameters,municipal_source)
	${PG} -c "insert into city_parameters (qid,parameter) select distinct 'D'||substr(qid,2,7),'municipal_source' from feedstock f where f.type in ('msw','grease','canola_oil','soybean_oil')"
	pgsql2shp -g centroid -f $@ $(db) "select qid,centroid from city_parameters p join city cx using (qid) where p.parameter='municipal_source'"

########################################################################
# National Atlas Data
# citiesx020 Cities from this file are used as locations for
# landings,point sources, potential biorefineries, existing
# biorefineries, and more
########################################################################
# First stage, so we can locate other city_parameters
city_locate_only.shp:%.shp:
	$(call check_or_make_table,wga_states,$(wga_states.sql))
	${PG} -c "drop table city cascade;" || true
	[[ -f citiesx020.tar.gz ]] || wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/citiesx020.tar.gz
	#tar -xzf citiesx020.tar.gz
	shp2pgsql -D -d -s 4326 -g nad83 -S -I citiesx020.shp public.city | ${PG} > /dev/null
	${PG} -c "select AddGeometryColumn('public','city','centroid',$(srid),'POINT',2);"
	${PG} -c "update city set centroid=transform(nad83,${srid});"
	${PG} -c "alter table city add column qid char(8); update city set qid='D'||state_fips||fips55 where state in (select state from wga_states);"
	# Add the city_parameters
	$(call delete_city_parameters,population)
	${PG} -c "insert into city_parameters (qid,parameter) select qid,'population' from city cx where cx.pop_2000>10000 and cx.state_fips in (select state_fips from wga_states);"
	pgsql2shp -g centroid -f $@ $(db) city

# This is a way to redo connectors when you've made your Nulls by hand and just want to add a few.
redo_connector_commands:
	$(call make_connector_cmds,road,city,50000,qid)
#	$(call make_connector_cmds,railway,$*,5000,qid,rail_im)
#	$(call make_connector_cmds,marine,$*,15000,qid,feed_mar|fuel_mar)
#	$(call delete_city_parameters,with_road)
#	${PG} -c "insert into city_parameters (qid,parameter) select qid,'with_road' from city cx where cx.road_connector is not null"
#	$(call delete_city_parameters,with_railway)
#	${PG} -c "insert into city_parameters (qid,parameter) select qid,'with_railway' from city cx where cx.railway_connector is not null"
#	pgsql2shp -g centroid -f $@ $(db) city.shp

city.shp:%.shp: city_locate_only.shp rail_im.shp ports.shp terminals.shp epa_facility.shp municipal_source.shp ethanol_facilities.shp railway.shp road.shp marine.shp
	# Railway intermodal facilites
	${PG} -c "alter table $* add column rail_im boolean;" || true;
	${PG} -c "update $* cx set rail_im=TRUE from city_parameters f where cx.qid=f.qid and parameter='rail_im'";
	# Fuel Marine Intermodal Facilites
	${PG} -c "alter table $* add column fuel_mar boolean;" || true; 
	$(call delete_city_parameters,fuel_mar)
	${PG} -c "insert into city_parameters (qid,parameter) select distinct qid,'fuel_mar' from ports where (comm_cd1 in ('20','21','22','23','29') or comm_cd2 in ('20','21','22','23','29') or comm_cd3 in ('20','21','22','23','29') or comm_cd4 in ('20','21','22','23','29')) and state in (select state from wga_states);"
	${PG} -c "update $* cx set fuel_mar=TRUE from city_parameters f where cx.qid=f.qid and parameter='fuel_mar'";
	# dry marine Intermodal Facilities
	${PG} -c "alter table $* add column feed_mar boolean;" || true; 
	$(call delete_city_parameters,feed_mar)
	${PG} -c "insert into city_parameters (qid,parameter) select distinct qid,'feed_mar' from ports where (comm_cd1 in ('10','41','42','43','62','63','64','65','67') or comm_cd2 in ('10','41','42','43','62','63','64','65','67') or comm_cd3 in ('10','41','42','43','62','63','64','65','67') or comm_cd4 in ('10','41','42','43','62','63','64','65','67')) and state in (select state from wga_states);"
	${PG} -c "update $* cx set feed_mar=TRUE from city_parameters f where cx.qid=f.qid and parameter='feed_mar'";
	# Add in roads
	${PG} -c "select AddGeometryColumn('public','$*','road_connector',$(srid),'LINESTRING',2);" || true
	# We don't need connectors with pop_2000 < 10000;
	${PG} -c "update $* set road_connector=MakeLine(centroid,centroid) where pop_2000 < 10000 or state_fips not in (select state_fips from wga_states)"
	${PG} -c "update $* c set road_connector=Null from city_parameters p join city_parameter_definitions d using (parameter) where c.qid=p.qid and d.network is True;"
	$(call make_connector_cmds,road,$*,3000,qid)
	# Add in special msw connectors;
	${PG} -c "update city c set road_connector=Null from city_parameters p where c.qid=p.qid and p.parameter='cbc.msw' and length(road_connector)=0;"
	$(call make_connector_cmds,road,city,50000,qid)
	# Okay now we're done.
	${PG} -c "update city set road_connector=Null where length(road_connector)=0;"
	# Add in railways
	${PG} -c "select AddGeometryColumn('public','$*','railway_connector',$(srid),'LINESTRING',2);" || true
	# We don't need maybe we do connectors with pop_2000 < 10000;
	${PG} -c "update $* set railway_connector=MakeLine(centroid,centroid) where pop_2000 < 10000 or state_fips not in (select state_fips from wga_states)"
	# leave in epa-facilities and terminals
	${PG} -c "update $* c set railway_connector=Null from city_parameters p join city_parameter_definitions d using (parameter) where c.qid=p.qid and d.network is True;"
	$(call make_connector_cmds,railway,$*,5000,qid,rail_im)
	${PG} -c "update city set railway_connector=Null where length(railway_connector)=0;"
	# Add in marine
	${PG} -c "select AddGeometryColumn('public','$*','marine_connector',$(srid),'LINESTRING',2);" || true
	# We don't need connectors with pop < 10000 (leave in non-ports however)
	${PG} -c "update $* set marine_connector=MakeLine(centroid,centroid) where pop_2000 < 10000 or state_fips not in (select state_fips from wga_states)"
	# Leave in terminals
	${PG} -c "update $* c set marine_connector=Null from city_parameters p join city_parameter_definitions d using (parameter) where c.qid=p.qid and d.network is True;"
	$(call make_connector_cmds,marine,$*,15000,qid,feed_mar|fuel_mar)
	${PG} -c "update city set marine_connector=Null where length(marine_connector)=0;"
	# Add the city_parameters
	$(call delete_city_parameters,population)
	${PG} -c "insert into city_parameters (qid,parameter) select qid,'population' from city cx where cx.pop_2000>10000 and cx.state_fips in (select state_fips from wga_states);"
	$(call delete_city_parameters,with_road)
	${PG} -c "insert into city_parameters (qid,parameter) select qid,'with_road' from city cx where cx.road_connector is not null"
	$(call delete_city_parameters,with_railway)
	${PG} -c "insert into city_parameters (qid,parameter) select qid,'with_railway' from city cx where cx.railway_connector is not null"
	pgsql2shp -g centroid -f $@ $(db) $*

#length(connector)/1609.344 as miles
county.shp:%.shp: road.shp
	[[ -f countyp020.tar.gz ]] || wget http://edcftp.cr.usgs.gov/pub/data/nationalatlas/countyp020.tar.gz
	tar -xzf countyp020.tar.gz
	shp2pgsql -D -d -s 4326 -S -g nad83 -S countyp020.shp public.countyp020 | ${PG} > /dev/null
	${PG} -c "delete from countyp020 where state_fips not in (select state_fips from wga_states);"
	${PG} -c "delete from countyp020 where county is Null"
	# Make one entry
	${PG} -c "drop table $* cascade;" || true
	${PG} -c "create table $* as select 'S'||fips as qid,state_fips,fips,state,county,collect(transform(nad83,${srid})) as boundary from countyp020 group by 'S'||fips,state_fips,fips,state,county;"
	${PG} -c "drop table countyp020;"
	${PG} -c "select AddGeometryColumn('public','$*','aea',$(srid),'MULTIPOLYGON',2);"	
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2); update $* set centroid=centroid(boundary);"
	${PG} -c "alter table $* add perim_miles float; update $* set perim_miles=perimeter(boundary)/1609.334"
	${PG} -c "alter table $* add area_mi2 float; update $* set area_mi2=area(boundary)/1609.334/1609.334"
	${PG} -c "select AddGeometryColumn('public','$*','road_connector',$(srid),'LINESTRING',2);"
	$(call make_connector_cmds,road,$*,16000,qid,perim_miles)
	$(call make_connector_cmds,road,$*,50000,qid,perim_miles)
	$(call make_connector_cmds,road,$*,100000,qid,perim_miles)
	pgsql2shp -g centroid -f $@ $(db) $*

########################################################################
# BTS Data Railways, highways, intermodal_facilities, and ports all
# come from BTS.  There data is nicely enough organized that the
# defined function can import them all.  state_fips and fips55 are
# added in preparation for joins to city parameters
########################################################################
bts_url:=http://www.bts.gov/publications/national_transportation_atlas_database/2007/zip/

define bts_data
archive-files+=$2.zip
$1.shp:
	[[ -f $2.zip ]] || wget ${bts_url}/$2.zip;
	unzip $2.zip;
	shp2pgsql -d -s 4326 -S -g nad83 -S -I $1.shp public.$1 | ${PG} > /dev/null;
	$(PG) -c "alter table $1 add column qid varchar(8);";
	${PG} -c "select AddGeometryColumn('public','$1','centroid',$(srid),'$3',2);";
	${PG} -c "update $1 set centroid=transform(nad83,${srid});";
	$(call add_fips_cmds,$1,gid,state,$4,nad83)
	rm $1.*;
	pgsql2shp -g centroid -f $$@ $(db) $1
endef

define bts_line_data
archive-files+=$2.zip
$1.shp:
	[[ -f $2.zip ]] || wget ${bts_url}/$2.zip;
	unzip $2.zip;
	shp2pgsql -d -s 4326 -S -g nad83 -S -I $1.shp public.$1 | ${PG} > /dev/null;
	$(PG) -c "alter table $1 add column qid varchar(8);";
	${PG} -c "select AddGeometryColumn('public','$1','centerline',$(srid),'LINESTRING',2);";
	${PG} -c "update $1 set centerline=transform(nad83,${srid});";
	rm $1.*;
	pgsql2shp -g centerline -f $$@ $(db) $1
endef

#$(eval $(call bts_line_data,railway,railway_lin))
$(eval $(call bts_line_data,nhpnlin,nhpn_lin))
$(eval $(call bts_data,facility,terminal,POINT,city))
Commodi.dbf: facility.shp
$(eval $(call bts_data,ports,port,POINT,town))
#
# Landing Information
landing_commodity_table:=create table landing_commodity (\
	id float,\
	description varchar(50),\
	code varchar(50),\
	facility_id varchar(50),\
	name varchar(50));

rail_im.shp:%.shp: Commodi.dbf facility.shp;
	${PG} -c 'drop table landing_commodity cascade;' || true;
	$(PG) -c '${landing_commodity_table}';\
	dbview -b -d'|' -t $< | perl -p -e 's/\|$$//;' | $(PG) -c "copy landing_commodity (id,description,code,facility_id,name) FROM STDIN DELIMITER AS '|' CSV";\
	$(call delete_city_parameters,$*)
	${PG} -c "insert into city_parameters (qid,parameter) select distinct f.qid,'$*' from facility f join landing_commodity c on (f.id=c.facility_id) where f.qid is not null and c.code in ('03','04','06','25','26','27') and f.mode_type like '%RAIL%' and f.mode_type like '%TRUCK%'";
	pgsql2shp -g centroid -f $@ $(db) "select distinct f.qid,f.centroid from facility f join landing_commodity c on (f.id=c.facility_id) where f.qid is not null and c.code in ('03','04','06','25','26','27') and f.mode_type like '%RAIL%' and f.mode_type like '%TRUCK%'";

potential_location.shp:%.shp: city.shp
	${PG} -c 'drop table proximate_cities' || true;
	${PG} -c "create table proximate_cities as select distinct p1.qid as src_qid,p2.qid as proximate_qid from city_parameters p1 join city c1 using (qid),city_parameters p2 join city c2 on (p2.qid=c2.qid) where distance(c1.centroid,c2.centroid) < 50000 and (p1.qid <> p2.qid) and (c1.pop_2000 < c2.pop_2000 or (c1.pop_2000=c2.pop_2000 and c1.centroid < c2.centroid))"
	${PG} -c  "drop table $*; " || true
	$(PG) -c 'create table $* (qid char(8) primary key);'
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2);"
	${PG} -c "insert into $* (qid) select distinct qid from city_parameters p join city_parameters p2 using(qid) join city_parameters p3 using (qid) left join proximate_cities pc on (p.qid=src_qid) where p.parameter in ('biodiesel','biopower_facility','ethanol','population','epa_facility','terminals','ethanol_facilities') and (p2.parameter='with_railway' or p2.parameter='fuel_mar') and p3.parameter='with_road' and pc is null"
	${PG} -c "update $* c set centroid=cx.centroid from city cx where c.qid=cx.qid"
	pgsql2shp -g centroid -f $@ $(db) $*

#potential_location_poly_20000.shp:potential_location_poly_%.shp:
#	pgsql2shp -g buffer -f $@ $(db) "select qid,'M'||substr(qid,2,7) as mid,buffer(centroid,$*) as buffer from potential_location"

feedstock_poly_20000.shp:feedstock_poly_%.shp:
	pgsql2shp -g buffer -f $@ $(db) "select qid,buffer(centroid,$*) as buffer from feedstock"

###########################################################################
# Anelia's Data
###########################################################################
define anelia_data
archive-files+=$2.zip
$1:
	if ( ! ${PG} -c '\d $1' > /dev/null ); then\
	 [[ -f $2.zip ]] || wget ${bts_url}/$2.zip;\
	 unzip $2.zip;\
  	 shp2pgsql -D -d -s $(srid) -S -g centroid -S -I $1.shp public.$1 | ${PG} > /dev/null;\
	 $(PG) -c "alter table $1 add column qid varchar(8);";\
	 $(call add_fips_cmds,$1,gid,$3,$4,centroid)\
	 rm $1.*;\
	fi;
endef

# Analia's data falls under bts_data setup as well
$(eval $(call anelia_data,biodiesel,biorefineries,state,city))
$(eval $(call anelia_data,ethanol,biorefineries,st_abbrev,name))

########################################################################
# Antares

# US BioPower Facilities
########################################################################
archive-files+=US-Biopower-Facilities-planned.csv US-Biopower-Facilities-operational.csv

biopower_facility_table:=create table biopower_facility (\
plant varchar(128),\
company varchar(128),\
capacity float,\
year integer,\
fuel_type varchar(32),\
city varchar(128),\
state char(2),\
latitude float,\
longitude float,\
state_fips varchar(2),\
fips55 varchar(5),\
operational boolean);

biopower_facility.shp:%.shp:input/US-Biopower-Facilities-planned.csv input/US-Biopower-Facilities-operational.csv
	$(PG) -c 'drop table $* cascade' || true;	
	${PG} -c '${biopower_facility_table}';
	cat input/US-Biopower-Facilities-planned.csv | $(PG) -c "copy $* (plant,company,capacity,year,fuel_type,city,state,latitude,longitude) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";\
	${PG} -c "update $* set operational=False";
	cat input/US-Biopower-Facilities-operational.csv | $(PG) -c "copy $* (plant,company,capacity,year,fuel_type,city,state,latitude,longitude) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";\
	${PG} -c "update $* set operational=True where operational is Null";
	${PG} -c "alter table $* add column qid char(8)";\
	$(call add_fips_cmds,$*,plant,state,city,LL)\
	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from $* s join city c using (qid);'

###########################################################################
# EPA EnviroFacts Facility Registration System

# This is the SQL call to collect all the EPA facility types that use
# determining potential locations for sites.
#http://oaspub.epa.gov/enviro/user_entered_sql.user_sql?csv_output=Output+to+CSV&sqltext=Select++V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_ACRNM,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.FACILITY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.REGISTRY_ID,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.SIC_CODE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.CITY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.COUNTY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.STATE_CODE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.BVFLAG,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_LATITUDE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_LONGITUDE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.ACCURACY_VALUE+from+V_LRT_EF_COVERAGE_SRC_SIC_EZ++where+(V_LRT_EF_COVERAGE_SRC_SIC_EZ.SIC_CODE+in+('2421','2429','2431','2077','2011','2013','5147','2041','2046','2075','2076','2074','2611','2631'))+and+(V_LRT_EF_COVERAGE_SRC_SIC_EZ.STATE_CODE+in+('AK','AZ','CA','CO','HI','ID','KS','MT','NE','NV','NM','ND','OK','OR','SD','TX','UT','WA','WY'))

# For SIC codes
#http://www.osha.gov/pls/imis/sicsearch.html
#2421,2429,2431,2077,2011,2013,5147,2041,2046
#AK,AZ,CA,CO,HI,ID,KS,MT,NE,NV,NM,ND,OK,OR,SD,TX,UT,WA,WY
##########################################################################
archive_files+=input/epa_facility.csv
input/epa_facility.csv:
	echo Please go to the following URL in your browser, then download the output file to epa_facility.csv.
	echo "http://oaspub.epa.gov/enviro/user_entered_sql.user_sql?csv_output=Output+to+CSV&sqltext=Select++V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_ACRNM,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.FACILITY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.REGISTRY_ID,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.SIC_CODE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.CITY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.COUNTY_NAME,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.STATE_CODE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.BVFLAG,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_LATITUDE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.PGM_SYS_LONGITUDE,+V_LRT_EF_COVERAGE_SRC_SIC_EZ.ACCURACY_VALUE+from+V_LRT_EF_COVERAGE_SRC_SIC_EZ++where+(V_LRT_EF_COVERAGE_SRC_SIC_EZ.SIC_CODE+in+('2421','2429','2431','2077','2011','2013','5147','2041','2046','2075','2076','2074','2611','2631'))+and+(V_LRT_EF_COVERAGE_SRC_SIC_EZ.STATE_CODE+in+('AK','AZ','CA','CO','HI','ID','KS','MT','NE','NV','NM','ND','OK','OR','SD','TX','UT','WA','WY'))"


epa_facility_table:= create table epa_facility (\
	program_system_acronym varchar(32),\
	facility_name varchar(255),\
	registry_id int8,\
	sic_code int,\
	city_name varchar(48),\
	county_name varchar(32),\
	state_code varchar(2),\
	default_map_flag char(1),\
	latitude float,\
	longitude float,\
	accuracy_value int,\
	state_fips varchar(2),\
	fips55 varchar(5));

epa_facility.shp:%.shp:input/%.csv city_locate_only.shp
	$(PG) -c 'drop table $* cascade' || true;
	${PG} -c '${epa_facility_table}';
	cat input/$*.csv | $(PG) -c "copy epa_facility (program_system_acronym,facility_name,registry_id,sic_code,city_name,county_name,state_code,default_map_flag,latitude,longitude,accuracy_value) FROM STDIN WITH DELIMITER AS ',' QUOTE AS '\"' CSV HEADER";
	${PG} -c "alter table $* add column qid char(8)";
	$(call add_fips_cmds,epa_facility,registry_id,state_code,city_name,LL)
	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from $* s join city c using (qid);'


costs:=0 5 10 12_5 15 17_5 20 22_5 25 27_5 30 32_5 35 37_5 40 42_5 45 47_5 50 52_5 55 57_5 60 62_5 65 67_5 70 72_5 75 77_5 80 82_5 85 87_5 90 92_5 95 97_5 100

####################################################################
# Peter's cell csv files have numbers formatted as strings, but the
# county as a integer and they need to be fixed.
####################################################################
define fix_csv
	perl -p -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)(\.(\d*))?\"/$$2$$3$$4$$5/g;' -e 's/\$$//g;' -e's/\?//g;' -e 's/,+.$$//'  $2 > $1
endef

input/hecHI.csv input/canola_co.csv input/soy_co.csv input/biosolids_co.csv input/corn_co.csv input/tallow_lard_co.csv input/yellow_grease_municip.csv input/msw_municip.csv:input/%:../data/feedstock_supply/%
	$(call fix_csv,$@,$<)

input/ag_cellulosic_co.csv:../data/feedstock_supply/ag_cellulosic_co.csv
	perl -p -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)\"/$$2$$3$$4/g;' -e 's/([^,]*,[^,]*,)(\d*),(\d*)/sprintf("%s%2.2d,%3.3d",$$1,$$2,$$3)/e;' $< > $@

#input/low_forest_co.csv input/high_forest_co.csv:input/%.csv:../data/feedstock_supply/%.csv
#	perl -p -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)(\.(\d*))?\"/$$2$$3$$4$$5/g;' -e 's/\$$//g;' -e's/\?//g;' -e 's/,+.$$//' $< | perl -n -a -F',' -e 'if ($$n) {print join(",",$$F[0],$$F[1],$$F[2],"forest",$$F[3],map({$$F[$$_]-$$F[$$_-1]} (4..41))),"\n";} else {print $$_; $$n++;}' > $@

feedstock.shp:%.shp:city_locate_only.shp county.shp input/biosolids_co.csv input/corn_co.csv input/tallow_lard_co.csv input/low_forest_co.csv input/high_forest_co.csv input/ag_cellulosic_co.csv input/yellow_grease_municip.csv input/msw_municip.csv seedoil_feedstock.shp input/sd_ne_new.csv input/ok_corn_wheat_oats_rye.csv input/ok_hec.csv input/ok_ovw_new.csv input/wga_grease.csv input/wga_tallow.csv input/hecHI.csv
	${PG} -c  "drop table $*; " || true
	$(PG) -c 'create table $* (qid char(8),type varchar(32),state_fips char(2),fips55 char(5),cost float,amount float);'
	#  Biosolids
	cat input/biosolids_co.csv | perl -n -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)(\.(\d*))?\"/$$2$$3$$4.$$6/g;' -e '@F=split(",");' -e 'printf("biosolids,%2.2d,%2.2d%3.3d,%f,%f\n",$$F[2],$$F[2],$$F[3],$$F[5],$$F[4]) unless $$F[4]==0' | $(PG) -c "copy feedstock (type,state_fips,fips55,cost,amount) FROM STDIN CSV"
	# corngrain
	cat input/corn_co.csv | perl -n -e 's/\"((\d+),)?(\d?\d?\d),(\d\d\d)(\.(\d*))?\"/$$2$$3$$4.$$6/g;' -e '@F=split(",");' -e 'printf("corngrain,%2.2d,%2.2d%3.3d,%f,%f\n",$$F[2],$$F[2],$$F[3],$$F[8]*2000,$$F[7]/2000) unless $$F[7]==0 or $$F[3]==0' | $(PG) -c "copy feedstock (type,state_fips,fips55,cost,amount) FROM STDIN CSV"
	# OLD TALLOW
#	${PG} -c 'drop table $*_tt' || true
#	${PG} -c 'create table $*_tt (state char(2),county char(32),type char(32),total float,cost float);'
#	cat input/tallow_lard_co.csv | perl -n  -e '@F=split(",");' -e 'printf "%s,%s,%f,%f\n",$$F[0],$$F[1],$$F[4]/2000,$$F[5]*2000 unless $$F[4]==0' | $(PG) -c "copy $*_tt (state,county,total,cost) FROM STDIN CSV"
#	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'tallow',c.state_fips,c.fips,cost,total from $*_tt f join county c on (f.state=c.state and lower(f.county||' County')=lower(c.county))";
#	${PG} -c 'drop table $*_tt;';
	# Tallow - This new tallow from Richards' latest, though we need to get the prices from the old version.
	# First get tallow prices
	${PG} -c 'drop table tallow_old' || true
	${PG} -c 'create table tallow_old (state char(2),county char(32),tallow_lb float,lard_lb float,total_lb float,price_per_lb float,price_region varchar(10));'
	cat input/tallow_lard_co.csv | $(PG) -c "copy tallow_old (state,county,tallow_lb,lard_lb,total_lb,price_per_lb,price_region) FROM STDIN CSV HEADER"
	${PG} -c 'drop table tallow_region_price' || true
	${PG} -c 'create table tallow_region_price as select distinct price_region,price_per_lb from tallow_old';
	${PG} -c 'alter table tallow_region_price add primary key (price_region);'
	${PG} -c 'drop table tallow_region_state' || true
	${PG} -c 'create table tallow_region_state as select distinct price_region,state from tallow_old';
	${PG} -c 'alter table tallow_region_state add primary key (state);'
	# Now get the new data
	${PG} -c 'drop table tallow' || true
	${PG} -c 'create table tallow (state char(2),county char(32),type varchar(15),estimated_lbs float,Mgal_biodiesal float,price_region varchar(10));'
	cat input/wga_tallow.csv | $(PG) -c "copy tallow (state,county,type,estimated_lbs,Mgal_biodiesal,price_region) FROM STDIN CSV HEADER"
	# And now add to the feedstock, taking care to make it in tons
	${PG} -c "insert into feedstock(type,state_fips,fips55,cost,amount) select 'tallow' as type,c.state_fips,c.fips as fip55,price_per_lb*2000 as cost,total/2000 as amount from (select state,county,sum(estimated_lbs) as total from tallow group by state,county) as f join county c on (f.state=c.state and lower(f.county||' County')=lower(c.county)) join tallow_region_state r on (f.state=r.state) join tallow_region_price using (price_region);"
	# OLD GREASE
#	${PG} -c 'create table $*_tt(state char(2),city char(50),total float,cost float);'
#	cat input/yellow_grease_municip.csv | perl -n  -e '@F=split(",");' -e 'printf "%s,%s,%f,%f\n",$$F[0],$$F[1],$$F[4]/2000,$$F[5]*2000 unless $$F[4]==0' | $(PG) -c "copy $*_tt (city,state,total,cost) FROM STDIN CSV"
#	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'grease',c.state_fips,c.fips55,cost,total from $*_tt f join city c on (f.state=c.state and lower(f.city)=lower(c.name))"
#	${PG} -c 'drop table $*_tt';
	# First get grease prices
	${PG} -c 'drop table grease_old' || true
	${PG} -c 'create table grease_old (city varchar(50),state char(2),pop2000 integer,pop2015 integer,YG_lb_2015 float,price_per_lb float,price_region varchar(10));'
	cat input/yellow_grease_municip.csv | $(PG) -c "copy grease_old (city,state,pop2000,pop2015,YG_lb_2015,price_per_lb,price_region) FROM STDIN CSV HEADER"
	${PG} -c 'drop table grease_region_price' || true
	${PG} -c 'create table grease_region_price as select distinct price_region,price_per_lb from grease_old';
	${PG} -c 'alter table grease_region_price add primary key (price_region);'
	${PG} -c "insert into grease_region_price(price_region,price_per_lb) values ('?',0.18);"
#	${PG} -c 'drop table grease_region_state' || true
#	${PG} -c 'create table grease_region_state as select distinct price_region,state from grease_old';
#	${PG} -c 'alter table grease_region_state add primary key (state);'
	# Grease New dta, but use old tables for prices.
	${PG} -c 'drop table grease' || true
	${PG} -c 'create table grease (city varchar(50),state char(2),pop2000 integer,pop2015 integer,num_restaurants integer,YG_lbs float,BG_lbs float,YG_only_unknown float,MG_biodiesal float,price_region varchar(5));'
	cat input/wga_grease.csv | $(PG) -c "copy grease (city,state,pop2000,pop2015,num_restaurants,YG_lbs,BG_lbs,YG_only_unknown,MG_biodiesal,price_region) FROM STDIN CSV HEADER"
	# Now input grease into feedstock making sure to do lbs->tons
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'grease',c.state_fips,c.fips55,price_per_lb*2000 as cost,yg_lbs/2000 from grease f join city c on (f.state=c.state and lower(f.city)=lower(c.name)) join grease_region_price using (price_region)"
	# MSW
# Do this from calculations
# insert into feedstock select replace(c.qid,'D','M') as qid,'Generic Municipal' as type,c.state_fips,c.fips55 as fips55,0 as cost,0 as amount, c.centroid from city c  where c.state_fips='06' and pop_2000 > 10000;
	${PG} -c 'drop table $*_tt' || true;
	${PG} -c 'create table $*_tt (state char(2),city char(50),total float,cost float);'
	cat input/msw_municip.csv | perl -n  -e '@F=split(",");' -e 'printf "%s,%s,%f,%f\n",$$F[0],$$F[1],$$F[3],0 unless $$F[3]==0' | $(PG) -c "copy $*_tt (city,state,total,cost) FROM STDIN CSV"
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'msw_total',c.state_fips,c.fips55,cost,total from $*_tt f join city c on (f.state=c.state and lower(f.city)=lower(c.name))"
	${PG} -c 'drop table $*_tt';
	# Add functions to calculate msw breakdown from our table;
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'msw_yard',state_fips,fips55,10,amount*.13*0.75 from feedstock where type='msw_total'"
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'msw_wood',state_fips,fips55,27.5,amount*0.055*0.75 from feedstock where type='msw_total'"
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'msw_paper',state_fips,fips55,27.5,amount*.16*.5 from feedstock where type='msw_total'"
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select 'msw_dirty',a.state_fips,a.fips55,27.5,a.amount-b.amount-c.amount-d.amount from feedstock a join feedstock b on (a.type='msw_total' and b.type='msw_yard' and a.state_fips=b.state_fips and a.fips55=b.fips55) join feedstock c on (a.type='msw_total' and c.type='msw_wood' and a.state_fips=c.state_fips and a.fips55=c.fips55) join feedstock d on (a.type='msw_total' and d.type='msw_paper' and a.state_fips=d.state_fips and a.fips55=d.fips55)"
	# Soy and canola oils needs the seedoil_feedstock table
	${PG} -c "insert into feedstock (type,state_fips,fips55,cost,amount) select type||'_oil',substr(qid,2,2),substr(qid,4,5),case when type='canola' then 753.40 else 681.40 end, case when type='canola' then total_wetton*0.383 else total_wetton*11.28*33/2000 end from seedoil_feedstock;"
	# Cellulosic
	$(PG) -c 'drop table $*_tt' || true
	$(PG) -c 'create table $*_tt (state char(20),County varchar(255),StFIPS char(2),CoFIPS char(3),Type varchar(25),	mt0 float, mt5 float, mt10 float, mt12_5 float, mt15 float, mt17_5 float, mt20 float, mt22_5 float, mt25 float, mt27_5 float, mt30 float, mt32_5 float, mt35 float, mt37_5 float, mt40 float, mt42_5 float, mt45 float, mt47_5 float, mt50 float, mt52_5 float, mt55 float, mt57_5 float, mt60 float, mt62_5 float, mt65 float, mt67_5 float, mt70 float, mt72_5 float, mt75 float, mt77_5 float, mt80 float, mt82_5 float, mt85 float, mt87_5 float, mt90 float, mt92_5 float, mt95 float, mt97_5 float, mt100 float);' 
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/ag_cellulosic_co.csv
# Special input for SD
	${PG} -c "delete from $*_tt where State='SD' and Type in ('oats','rye','barley')";
	${PG} -c "delete from $*_tt where State='NE' and Type in ('oats')";
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/sd_ne_new.csv
	${PG} -c "update $*_tt set mt5=mt5-mt0,mt10=mt10-mt5,mt12_5=mt12_5-mt10,mt15=mt15-mt12_5,mt17_5=mt17_5-mt15,mt20=mt20-mt17_5,mt22_5=mt22_5-mt20,mt25=mt25-mt22_5,mt27_5=mt27_5-mt25,mt30=mt30-mt27_5,mt32_5=mt32_5-mt30,mt35=mt35-mt32_5,mt37_5=mt37_5-mt35,mt40=mt40-mt37_5,mt42_5=mt42_5-mt40,mt45=mt45-mt42_5,mt47_5=mt47_5-mt45,mt50=mt50-mt47_5,mt52_5=mt52_5-mt50,mt55=mt55-mt52_5,mt57_5=mt57_5-mt55,mt60=mt60-mt57_5,mt62_5=mt62_5-mt60,mt65=mt65-mt62_5,mt67_5=mt67_5-mt65,mt70=mt70-mt67_5,mt72_5=mt72_5-mt70,mt75=mt75-mt72_5,mt77_5=mt77_5-mt75,mt80=mt80-mt77_5,mt82_5=mt82_5-mt80,mt85=mt85-mt82_5,mt87_5=mt87_5-mt85,mt90=mt90-mt87_5,mt92_5=mt92_5-mt90,mt95=mt95-mt92_5,mt97_5=mt97_5-mt95,mt100=mt100-mt97_5 where State='SD' and Type in ('oats','rye','barley')"
	${PG} -c "update $*_tt set mt5=mt5-mt0,mt10=mt10-mt5,mt12_5=mt12_5-mt10,mt15=mt15-mt12_5,mt17_5=mt17_5-mt15,mt20=mt20-mt17_5,mt22_5=mt22_5-mt20,mt25=mt25-mt22_5,mt27_5=mt27_5-mt25,mt30=mt30-mt27_5,mt32_5=mt32_5-mt30,mt35=mt35-mt32_5,mt37_5=mt37_5-mt35,mt40=mt40-mt37_5,mt42_5=mt42_5-mt40,mt45=mt45-mt42_5,mt47_5=mt47_5-mt45,mt50=mt50-mt47_5,mt52_5=mt52_5-mt50,mt55=mt55-mt52_5,mt57_5=mt57_5-mt55,mt60=mt60-mt57_5,mt62_5=mt62_5-mt60,mt65=mt65-mt62_5,mt67_5=mt67_5-mt65,mt70=mt70-mt67_5,mt72_5=mt72_5-mt70,mt75=mt75-mt72_5,mt77_5=mt77_5-mt75,mt80=mt80-mt77_5,mt82_5=mt82_5-mt80,mt85=mt85-mt82_5,mt87_5=mt87_5-mt85,mt90=mt90-mt87_5,mt92_5=mt92_5-mt90,mt95=mt95-mt92_5,mt97_5=mt97_5-mt95,mt100=mt100-mt97_5 where State='NE' and Type in ('oats')"
# Special inputs for new OK as well.
	${PG} -c "delete from $*_tt where State='OK' and Type in ('HEC','OVW','cornstover','oats','rye','swheatstraw')";
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/ok_corn_wheat_oats_rye.csv
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/ok_hec.csv
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/ok_ovw_new.csv
	${PG} -c "update $*_tt set mt5=mt5-mt0,mt10=mt10-mt5,mt12_5=mt12_5-mt10,mt15=mt15-mt12_5,mt17_5=mt17_5-mt15,mt20=mt20-mt17_5,mt22_5=mt22_5-mt20,mt25=mt25-mt22_5,mt27_5=mt27_5-mt25,mt30=mt30-mt27_5,mt32_5=mt32_5-mt30,mt35=mt35-mt32_5,mt37_5=mt37_5-mt35,mt40=mt40-mt37_5,mt42_5=mt42_5-mt40,mt45=mt45-mt42_5,mt47_5=mt47_5-mt45,mt50=mt50-mt47_5,mt52_5=mt52_5-mt50,mt55=mt55-mt52_5,mt57_5=mt57_5-mt55,mt60=mt60-mt57_5,mt62_5=mt62_5-mt60,mt65=mt65-mt62_5,mt67_5=mt67_5-mt65,mt70=mt70-mt67_5,mt72_5=mt72_5-mt70,mt75=mt75-mt72_5,mt77_5=mt77_5-mt75,mt80=mt80-mt77_5,mt82_5=mt82_5-mt80,mt85=mt85-mt82_5,mt87_5=mt87_5-mt85,mt90=mt90-mt87_5,mt92_5=mt92_5-mt90,mt95=mt95-mt92_5,mt97_5=mt97_5-mt95,mt100=mt100-mt97_5 where upper(State)='OK' and Type in ('HEC','OVW','corngrain','oats','rye','swheatstraw')"
	# Copy in new HEC_h data as well.
	$(PG) -c "copy $*_tt (State,County,StFIPS,CoFIPS,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN CSV HEADER" < input/hecHI.csv
	# Fix the missing fips_st_cd. This works on the county name first
	# and fips code second.
	${PG} -c "update $*_tt f set stfips=s.state_fips from wga_states s where lower(trim(both ' ' from f.state))=lower(s.state_name);"
	${PG} -c "update $*_tt f set stfips=s.state_fips from wga_states s where lower(trim(both ' ' from f.state))=lower(s.state);"
	$(PG) -c "update $*_tt f set cofips=substr(c.fips,3,3) from county c where f.stfips=substr(c.fips,1,2) and trim(both ' ' from f.county)||' County'=c.county;"
	${PG} -c "update $*_tt set cofips='00'||cofips where length(cofips)=1;"
	${PG} -c "update $*_tt set cofips='0'||cofips where length(cofips)=2;"
# and cofips<>c.fips;"
	# Fix Yellowstone
	$(PG) -c "update $*_tt set cofips=111 where stfips=30 and county='Yellowstone National Park';"
	for C in ${costs}; do \
	  cost=`echo $$C | tr '_' '.'`;\
	  ${PG} -c "insert into feedstock (state_fips,fips55,type,cost,amount) select f.stfips,f.stfips||f.cofips,f.type,$$cost,f.mt$$C from $*_tt f where mt$$C != 0"; \
	done;
	# finally fix the OVW cost
	${PG} -c "update feedstock set cost=30 where cost=0 and type='OVW';"
	#HIGH / LOW FOREST
	$(PG) -c 'drop table $*_tt' || true
	$(PG) -c 'create table $*_tt (fips char(5),county varchar(255),state char(2),type varchar(32),mt0 float, mt5 float, mt10 float, mt12_5 float, mt15 float, mt17_5 float, mt20 float, mt22_5 float, mt25 float, mt27_5 float, mt30 float, mt32_5 float, mt35 float, mt37_5 float, mt40 float, mt42_5 float, mt45 float, mt47_5 float, mt50 float, mt52_5 float, mt55 float, mt57_5 float, mt60 float, mt62_5 float, mt65 float, mt67_5 float, mt70 float, mt72_5 float, mt75 float, mt77_5 float, mt80 float, mt82_5 float, mt85 float, mt87_5 float, mt90 float, mt92_5 float, mt95 float, mt97_5 float, mt100 float);'
	for forest in low high; do \
	cat input/$${forest}_forest_co.csv | sed -e 's/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//' | $(PG) -c "copy $*_tt (fips,county,state,Type,mt0,mt5,mt10,mt12_5,mt15,mt17_5,mt20,mt22_5,mt25,mt27_5,mt30,mt32_5,mt35,mt37_5,mt40,mt42_5,mt45,mt47_5,mt50,mt52_5,mt55,mt57_5,mt60,mt62_5,mt65,mt67_5,mt70,mt72_5,mt75,mt77_5,mt80,mt82_5,mt85,mt87_5,mt90,mt92_5,mt95,mt97_5,mt100) FROM STDIN WITH NULL AS 'nodata' CSV HEADER"; \
	for C in ${costs}; do \
	  cost=`echo $$C | tr '_' '.'`;\
	  ${PG} -c "insert into feedstock (state_fips,fips55,type,cost,amount) select substr(f.fips,1,2),f.fips,'$${forest}_'||f.type,$$cost,f.mt$$C from $*_tt f where mt$$C != 0"; \
	done; \
	done;
	${PG} -c 'drop table $*_tt';
	# Add in centroids
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2);"
	${PG} -c "update $* set qid='M'||state_fips||fips55 where type in ('msw_total','grease','canola_oil','soybean_oil','msw_clean','msw_dirty','msw_yard'); update $* t set centroid=cx.centroid from city cx where substr(t.qid,2,7)=substr(cx.qid,2,7)"
	${PG} -c "update $* set qid='S'||fips55 where qid is Null; update $* t set centroid=c.centroid from county c where t.qid=c.qid";
	pgsql2shp -g centroid -f $@ $(db) $*

feedstock_locations.shp: feedstock.shp
	pgsql2shp -g centroid -f $@ $(db) 'select distinct qid,centroid from feedstock order by qid asc'


############################################################################
# OUTPUT tables
#
############################################################################
#gams_tables:=gams_supply.csv gams_supply_seed_oil.csv gams_price.csv gams_src2refine_wetton.csv gams_src2refine_100gal.csv gams_source_list_wetton.csv gams_refine_list_wetton.csv gams_source_list_100gal.csv gams_refine_list_100gal.csv gams_terminal_transport.csv
gams_tables:=gams_supply.csv gams_supply_seed_oil.csv gams_price.csv gams_src2refine_wetton.csv gams_src2refine_100gal.csv gams_source_list_wetton.csv gams_refine_list_wetton.csv gams_terminal_transport.csv

clean-gams.zip:
	rm -f gams.zip ${gams_tables}

gams.zip: ${gams_tables}
	zip $@ $?

gams_supply.csv:%.csv: feedstock.shp feedstock_group.csv
	${PG} -c 'drop table $*' || true;
	${PG} -c "create table $* as select trim(both from qid) as source_id,fg.group_type as type,'PL'||replace(cost,'.','_') as price_id,sum(amount) as marginal_addition from feedstock f join feedstock_group fg using (type) group by source_id,fg.group_type,price_id order by source_id,type,price_id"
	${PG} -c "copy $* (source_id,type,price_id,marginal_addition) TO STDOUT DELIMITER ',' CSV HEADER" > $@;

gams_supply_seed_oil.csv:%.csv: seedoil_feedstock.shp
	${PG} -c "copy seedoil_feedstock (qid,type,total_wetton,road_cost,avg_road_cost_wetton,min_cost,avg_min_cost_wetton) TO STDOUT DELIMITER ',' CSV HEADER" > $@;

gams_price.csv:%.csv: feedstock.shp
	${PG} -c "drop table $*" || true;
	${PG} -c "create table $* as select distinct 'PL'||replace(cost,'.','_') as price_id,cost as price from feedstock;"
	${PG} -c "copy $* (price_id,price) TO STDOUT DELIMITER ',' CSV HEADER" > $@

define gams_src2refine
gams_src2refine_$1.csv:%.csv: transportation_costs/feedstock_potential_location_$1_road_odcost.shp transportation_costs/feedstock_potential_location_$1_min_odcost.shp
# Read in Transportation Costs
	shp2pgsql -D -d -s $(srid) -S -I transportation_costs/feedstock_potential_location_$1_road_odcost.shp public.feedstock_potential_location_$1_road_odcost | ${PG} > /dev/null;
	shp2pgsql -N skip -D -d -s $(srid) -S -I transportation_costs/feedstock_potential_location_$1_min_odcost.shp public.feedstock_potential_location_$1_min_odcost | ${PG} > /dev/null;
	${PG} -c 'drop table $$*' || true;
#	${PG} -c "create table $$* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id,r.$2 as road_only_cost, r.total_road as road_only_road_miles, r.total_mari as road_only_marine_miles,r.total_rail as road_only_rail_miles, r.total_allm as road_only_all_miles, r.total_ro_1 as road_only_road_hours,m.$2 as min_cost, m.total_road as min_road_miles, m.total_mari as min_marine_miles,m.total_rail as min_rail_miles, m.total_allm as min_all_miles, m.total_ro_1 as min_road_hours from feedstock_potential_location_$1_road_odcost r full outer join feedstock_potential_location_$1_min_odcost m using (name) order by source_id,min_cost;"
	${PG} -c "create table $$* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id,r.$2 as road_only_cost, r.total_road as road_only_road_miles, r.total_mari as road_only_marine_miles,r.total_rail as road_only_rail_miles, r.total_allm as road_only_all_miles, r.total_ro_1 as road_only_road_hours,m.$2 as min_cost, m.total_road as min_road_miles, m.total_mari as min_marine_miles,m.total_rail as min_rail_miles, m.total_mile as min_all_miles, m.total_hour as min_road_hours from feedstock_potential_location_$1_road_odcost r full outer join feedstock_potential_location_$1_min_odcost m using (name) order by source_id,min_cost;"
	${PG} -c "copy $$* (source_id,dest_id,road_only_cost,road_only_road_miles,road_only_marine_miles,road_only_rail_miles,road_only_all_miles,road_only_road_hours,min_cost,min_road_miles,min_marine_miles,min_rail_miles,min_all_miles,min_road_hours) TO STDOUT DELIMITER ',' CSV HEADER" > $$@

gams_source_list_$1.csv:%.csv: gams_src2refine_$1.csv
	${PG} -A -F',' --pset footer -c "select distinct source_id from gams_src2refine_$1" > $$@

#gams_refine_list_$1.csv:%.csv: gams_src2refine_$1.csv petroleum_refinery_facility.shp
#	${PG} -A -F',' --pset footer -c "select distinct dest_id,case when p is null then 0 else 1 end as petroleum from gams_src2refine_$1 left join (select distinct 'D'||state_fips||fips55 as dest_id from petroleum_refinery_facility) as p using (dest_id);" > $$@

gams_refine_list_$1.csv:%.csv: gams_src2refine_$1.csv petroleum_refinery_facility.shp
	${PG} -A -F',' --pset footer -c "select qid,case when term is Null then 0 else 1 end as petroleum,term.real_qid as petroleum_qid,eth.real_qid as ethanol_qid,eth.status as ethanol_status,eth.capacity as ethanol_capacity,eth.capital_in as capital_investment from potential_location p left join (select case when p is null then e.qid else p.proximate_qid end as qid,e.qid as real_qid,e.capacity,e.status,e.capital_in from ethanol_facilities e left join proximate_cities p on (e.qid=p.src_qid)) as eth using (qid) left join (select distinct case when p is null then t.qid else p.proximate_qid end as qid,t.qid as real_qid from petroleum_refinery_facility t left join proximate_cities p on (t.qid=p.src_qid)) as term using (qid);" > $$@
endef 

$(eval $(call gams_src2refine,wetton,total_wet_))
$(eval $(call gams_src2refine,100gal,total_100g))

define gams_seed_src2refine
gams_seed_src2refine_$1.csv:%.csv: seedoil_potential_location_$1_road_odcost seedoil_potential_location_$1_min_odcost
	${PG} -c 'drop table $$*' || true;
	${PG} -c "create table $$* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id,r.$2 as road, m.$2 as min from seedoil_potential_location_$1_road_odcost r full outer join seedoil_potential_location_$1_min_odcost m using (name);"
	${PG} -c "copy $$* (source_id,dest_id,road,min) TO STDOUT DELIMITER ',' CSV HEADER" > $$@

gams_seed_source_list_$1.csv:%.csv:
	${PG} -A -F',' --pset footer -c "select distinct source_id from gams_seed_src2refine_$1" > $$@

gams_seed_refine_list_$1.csv:%.csv: 
	${PG} -A -F',' --pset footer -c "select distinct dest_id,case when p is null then 0 else 1 end as petroleum from gams_seed_src2refine_$1 left join (select distinct 'D'||state_fips||fips55 as dest_id from petroleum_refinery_facility) as p using (dest_id);" > $$@
endef 

$(eval $(call gams_seed_src2refine,100gal,total_100g))

gams_terminal_transport.csv:%.csv:transportation_costs/potential_location_terminal_fuel_min_cost.shp
	shp2pgsql -D -d -s $(srid) -S -I -g the_geom $< public.potential_location_terminal_fuel_min_cost | ${PG} > /dev/null;
	${PG} -c 'drop table $*' || true;
	${PG} -c "create table $* as select trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id, trim(both from substr(name,1,position(' - ' in name))) as terminal_id,total_fuel as cost,total_road, total_rail,total_mari as total_marine from potential_location_terminal_fuel_min_cost";
	${PG} -c "copy $* (dest_id,cost,terminal_id,total_road,total_rail,total_marine) TO STDOUT DELIMITER ',' CSV HEADER" > $@

#gams_terminal_transport.csv: potential_location_terminal_fuel_min_cost
#	${PG} -A -F',' --pset footer -c "select distinct dest_id as dest_id, (5+27.32)+total_mile*0.023 as cost from potential_location_terminal_rail_distance join (select distinct dest_id from gams_src2refine_wetton) as f on (substr(dest_id,4,5)=substr(name,1,5))" > $@

#############################################################################
# output shapefiles
#############################################################################
define target_price_brfn.sql
CREATE TABLE target_price_brfn (\
qid varchar(12),\
tech_type varchar(32),\
quant_MGY float,\
avg_cost float,\
procurement float,\
transport float,\
conversion float,\
distribution float);
endef

output/target_price_brfn.shp:output/%.shp:output/%.csv
	${PG} -c "drop table if exists $*";
	$(call check_or_make_table,$*,$($*.sql))
	cat $< | $(PG) -c "copy $* (qid,tech_type,quant_MGY,avg_cost,procurement,transport,conversion,distribution) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";
	pgsql2shp -g centroid -f $@ $(db) 'select qid,tech_type,quant_MGY,avg_cost,procurement,transport,conversion,distribution,cx.centroid from $* e left join city cx using (qid);'

define target_price_links.sql
CREATE TABLE target_price_links (\
qid varchar(12),\
dest_qid varchar(12),\
type varchar(32),\
quant_tons float);
endef

output/target_price_links.shp:output/%.shp:output/%.csv
	${PG} -c "drop table if exists $*";
	$(call check_or_make_table,$*,$($*.sql))
	cat $< | $(PG) -c "copy $* (qid,dest_qid,type,quant_tons) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";
	pgsql2shp -g line -f $@ $(db) 'select e.qid,dest_qid,e.type,quant_tons,makeline(f.centroid,cx.centroid) as line from $* e join (select distinct qid, centroid from feedstock) as f using (qid) join city cx on (cx.qid=e.dest_qid);'

output/target_price_links_src.shp:output/%_src.shp:output/%.shp
	pgsql2shp -g centroid -f $@ $(db) 'select e.qid,dest_qid,e.type,quant_tons,f.centroid as centroid from $* e join (select distinct qid,centroid from  feedstock) as f using (qid) join city cx on (cx.qid=e.dest_qid);'

#############################################################################
# Feedstock outputs
#############################################################################
feedstock_cost_by_ton.shp:%.shp:feedstock.shp feedstock_group.csv county.shp
	${PG} -c "drop table feedstock_group_ton" || true;
	${PG} -c  "create table feedstock_group_ton as select qid,cf as cost,group_type,sum(amount) as ton from feedstock f join feedstock_group fg using (type),generate_series(0,120,10) as cf where f.cost < cf  group by qid,group_type,cf union select qid,cf as cost,group_type,sum(amount) as tons from feedstock f join feedstock_group fg using (type),generate_series(200,800,100) as cf where f.cost < cf  group by qid,group_type,cf;"
	${PG} -c "drop table $*" || true;
	${PG} -c "create table $* as select qid,cost,f1.ton as HEC,f2.ton as OVW,f3.ton as canola_oil,f4.ton as corn,f5.ton as soybean_oil,f6.ton as grease,f7.ton as high_forest,f8.ton as lce,f9.ton as forest,fa.ton as msw_dirty,fb.ton as msw_paper,fc.ton as msw_wood,fd.ton as msw_yard,fe.ton as oils,ff.ton as stover,fg.ton as straw,fh.ton as tallow from (select qid,cost,ton from feedstock_group_ton where group_type='HEC') as f1 full outer join (select qid,cost,ton from feedstock_group_ton where group_type='OVW') as f2 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='canola_oil') as f3 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='corn') as f4 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='soybean_oil') as f5 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='grease') as f6 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='high_forest') as f7 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='lce') as f8 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='forest') as f9 using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='msw_dirty') as fa using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='msw_paper') as fb using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='msw_wood') as fc using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='msw_yard') as fd using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='oils') as fe using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='stover') as ff using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='straw') as fg using (qid,cost) full outer join (select qid,cost,ton from feedstock_group_ton where group_type='tallow') as fh using (qid,cost);"
	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2);"
	${PG} -c "update $* t set centroid=c.centroid from feedstock c where t.qid=c.qid";
	${PG} -c "select AddGeometryColumn('public','$*','boundary',$(srid),'MULTIPOLYGON',2);"
	${PG} -c "update $* t set boundary=c.boundary from county c where t.qid=c.qid";
	${PG} -c "alter table $* add column acres float; update $* t set acres=area(boundary)/4046.8726";
	pgsql2shp -g boundary -f feedstock_cost_by_ton_county.shp $(db) 'select * from $* where boundary is not null';
	pgsql2shp -g centroid -f $@ $(db) $*

feedstock_cost_ton.csv:%.csv:feedstock_cost_by_ton.shp
	${PG} -A -F',' --pset footer -c "select cost,sum(HEC) as HEC,sum(OVW) as OVW,sum(corn) as corn,sum(grease) as grease,sum(high_forest) as high_forest,sum(lce) as lce, sum(forest) as forest,sum(msw_dirty) as msw_dirty,sum(msw_paper) as msw_paper,sum(msw_wood) as msw_wood,sum(msw_yard) as msw_yard,sum(canola_oil) as canola, sum(soybean_oil) as soybean,sum(oils) as oils,sum(stover) as stover,sum(straw) as straw,sum(tallow) as tallow from feedstock_cost_by_ton group by cost order by cost;" > $@

# feedstock_cost_by_gge.shp:%.shp:feedstock.shp
# 	${PG} -c "drop table feedstock_group_gge" || true;
# 	${PG} -c  "create table feedstock_group_gge as select qid,cf/100.0::decimal(5,2) as cost,group_type,sum(amount*fg.yield) as gge from feedstock f join feedstock_group fg using (type),generate_series(0,200,10) as cf where f.cost/fg.yield < cf/100.0  group by qid,group_type,cf union select qid,cf::decimal(5,2) as cost,group_type,sum(amount*fg.yield) as gge from feedstock f join feedstock_group fg using (type),generate_series(3,15,1) as cf where f.cost/fg.yield < cf  group by qid,group_type,cf;"
# 	${PG} -c "drop table $*" || true;
# 	${PG} -c "create table $* as select qid,cost,f1.gge as HEC,f2.gge as OVW,f3.gge as ag,f4.gge as bio,f5.gge as corn,f6.gge as forest,f7.gge as grease,f8.gge as msw,f9.gge as muni,fa.gge as seed,fb.gge as stover,fc.gge as straw,fd.gge as tallow,fe.gge as canola,ff.gge as soy from (select qid,cost,gge from feedstock_group_gge where group_type='HEC') as f1 full outer join (select qid,cost,gge from feedstock_group_gge where group_type='OVW') as f2 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='ag') as f3 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='biosolids') as f4 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='corn') as f5 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='forest') as f6 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='grease') as f7 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='msw_total') as f8 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='muni') as f9 using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='seed') as fa using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='stover') as fb using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='straw') as fc using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='tallow') as fd using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='canola') as fe using (qid,cost) full outer join (select qid,cost,gge from feedstock_group_gge where group_type='soy') as ff using (qid,cost);"
# 	${PG} -c "select AddGeometryColumn('public','$*','centroid',$(srid),'POINT',2);"
# 	${PG} -c "update $* t set centroid=c.centroid from feedstock c where t.qid=c.qid";
# 	${PG} -c "select AddGeometryColumn('public','$*','boundary',$(srid),'MULTIPOLYGON',2);"
# 	${PG} -c "update $* t set boundary=c.boundary from county c where t.qid=c.qid";
# 	${PG} -c "alter table $* add column acres float; update $* t set acres=area(boundary)/4046.8726";
# 	pgsql2shp -g boundary -f feedstock_cost_by_gge_county.shp $(db) 'select * from $* where boundary is not null';
# 	pgsql2shp -g centroid -f $@ $(db) $*

# feedstock_cost_gge.csv:%.csv: feedstock_cost_by_gge.shp
# 	${PG} -A -F',' --pset footer -c "select cost,sum(HEC) as HEC,sum(OVW) as OVW,sum(ag) as ag,sum(bio) as bio,sum(corn) as corn,sum(forest) as forest,sum(grease) as grease,sum(msw) as msw,sum(muni) as muni,sum(seed) as seed,sum(stover) as stover,sum(straw) as straw,sum(tallow) as tallow,sum(canola) as canola,sum(soy) as soy from feedstock_cost_by_gge group by cost order by cost;" > $@

#############################################################################
# Special tables for CBC report
############################################################################
cbc.swis.sql:=\
CREATE TABLE cbc.swis (\n\
swisno varchar(12),\n\
unitno varchar(2),\n\
sitename varchar(256),\n\
countyid integer,\n\
county varchar(32),\n\
operator varchar(256),\n\
location varchar(256),\n\
placename varchar(256),\n\
zip varchar(10),\n\
enforangent varchar(256),\n\
owner varchar(256),\n\
category varchar(128),\n\
activity varchar(128),\n\
regstatus varchar(128),\n\
opstatus varchar(32),\n\
latitude float,\n\
longitude float,\n\
siteid integer,\n\
unitid integer\n\
);\n\

cbc/swis.shp:cbc/%.shp:
	[[ -f cbc/$*.txt ]] || wget -O cbc/$*.txt http://www.ciwmb.ca.gov/SWIS/Downloads/SwisGIS.txt
	$(call check_or_make_table,cbc.$*,${cbc.swis.sql})
	cat cbc/$*.txt | ${PG} -c "copy cbc.swis from STDIN WITH CSV HEADER"
	$(PG) -c "alter table cbc.$* add column id varchar(15);";
	$(PG) -c "alter table cbc.$* add column qid varchar(8);";
	$(PG) -c "alter table cbc.$* add column state char(2);";
	$(PG) -c "update cbc.$* set state='CA';";
	$(PG) -c "update cbc.$* set placename=trim(both from placename);";
	$(call add_fips_cmds,cbc.$*,swisno,state,placename,LL)
	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from cbc.$* s join city c using (qid);'

cbc/msw.shp:cbc/%.shp:
	# Right now the cbc.msw_by_facility comes from q.cstars perl file
	${PG} -c "delete from city_parameters where parameter='cbc.msw'";
	${PG} -c "insert into city_parameters select distinct s.qid,'cbc.msw' from cbc.msw_by_facility join cbc.swis s using (swisno)"
	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from cbc.$* s join city c using (qid);'

cbc/sewage.shp:cbc/%.shp: input/sewage.shp
	shp2pgsql -d -s 3310 -g the_geom -S $< cbc.$* | ${PG}
	$(PG) -c "alter table cbc.$* add column state char(2);";
	${PG} -c "alter table cbc.$* rename column lat to latitude";
	${PG} -c "alter table cbc.$* rename column long to longitude";
	$(PG) -c "alter table cbc.$* add column qid varchar(8);";
	$(PG) -c "update cbc.$* set state='CA';";
	# Make the fips_cmds using the LL
	$(call add_fips_cmds,cbc.$*,gid,state,facname,LL)\
	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from cbc.$* s join city c using (qid);'

# This is a less good version of the bdircomb05_83
#cbc/biomass_plant.shp:cbc/%.shp: input/%.shp
#	shp2pgsql -d -s 3310 -g the_geom -S $< cbc.$* | ${PG}
#	$(PG) -c "alter table cbc.$* add column state char(2);";
#	# Fix weird lat,long
#	${PG} -c "alter table cbc.$* drop column latitude";
#	${PG} -c "alter table cbc.$* drop column longitude";
#	${PG} -c "alter table cbc.$* rename column lat_dd to latitude";
#	${PG} -c "alter table cbc.$* rename column lon_dd to longitude";
#	${PG} -c "update cbc.$* set longitude=-longitude";
#	$(PG) -c "alter table cbc.$* add column qid varchar(8);";
#	$(PG) -c "update cbc.$* set state='CA';";
#	# Make the fips_cmds using the LL
#	$(call add_fips_cmds,cbc.$*,gid,state,city,LL)
#	pgsql2shp -g centroid -f $@ $(db) 'select s.*,c.centroid from cbc.$* s join city c using (qid);'


cbc/bdircomb05_83.shp:cbc/%.shp: input/%.shp
	shp2pgsql -d -s 3310 -g the_geom -S $< cbc.$* | ${PG}
	$(PG) -c "alter table cbc.$* add column state char(2);";
	$(PG) -c "update cbc.$* set state='CA';";
	$(PG) -c "alter table cbc.$* add column qid varchar(8);";
	${PG} -c "select AddGeometryColumn('cbc','$*','centroid',${srid},'POINT',2);"
	${PG} -c "update cbc.$* set centroid=transform(the_geom,${srid});"
	# Make the fips_cmds using the LL
	$(call add_fips_cmds,cbc.$*,gid,state,city,centroid)
	pgsql2shp -g centroid -f $@ $(db) cbc.$*

cbc/ethanol.shp:cbc/%.shp: input/%.shp
	shp2pgsql -d -s 3310 -g the_geom -S $< cbc.$* | ${PG}
	$(PG) -c "alter table cbc.$* add column state char(2);";
	$(PG) -c "update cbc.$* set state='CA';";
	$(PG) -c "alter table cbc.$* add column qid varchar(8);";
	${PG} -c "select AddGeometryColumn('cbc','$*','centroid',${srid},'POINT',2);"
	${PG} -c "update cbc.$* set centroid=transform(the_geom,${srid});"
	# Make the fips_cmds using the LL
	$(call add_fips_cmds,cbc.$*,gid,state,location,centroid)
	pgsql2shp -g centroid -f $@ $(db) cbc.$*

cbc/potential_location.shp:cbc/%.shp: city.shp
	${PG} -c  "drop table cbc.$*; " || true
	${PG} -c "create table cbc.$* as select qid,connected,population,similar_facility,biomass_refinery,sewage from (select distinct qid, True as connected from city_parameters p join city c using (qid) where (p.parameter='with_railway' or p.parameter='fuel_mar') and c.state='CA') as con join (select qid,population,similar_facility,biomass_refinery from (select distinct qid, True as population from city_parameters p where (p.parameter='population')) as p full outer join (select distinct qid, True as similar_facility from city_parameters p join city_parameter_definitions d using (parameter) where d.similar_facility is True) as f using (qid) full outer join (select distinct qid, True as biomass_refinery from city_parameters p join city_parameter_definitions d using (parameter) where d.biomass_refinery is True) as biof using (qid)) as pfb using (qid) left join (select qid, True as sewage from city_parameters p  where p.parameter='cbc.sewage') as sew using (qid);"
	for i in connected population similar_facility biomass_refinery sewage; do\
	  ${PG} -c "update cbc.$* set $$i=False where $$i is Null;";\
	done;
#	${PG} -c "select AddGeometryColumn('cbc','$*','centroid',3310,'POINT',2);"
#	${PG} -c "update cbc.$* c set centroid=transform(cx.centroid,3310) from city cx where c.qid=cx.qid"
	${PG} -c "select AddGeometryColumn('cbc','$*','centroid',${srid},'POINT',2);"
	${PG} -c "update cbc.$* c set centroid=cx.centroid from city cx where c.qid=cx.qid"
	pgsql2shp -g centroid -f cbc/$*.shp $(db) cbc.$*

cbc/proxy_location.shp:cbc/%.shp:cbc/potential_location.shp
	${PG} -c 'drop table cbc.proxy_location' || true;
	# Include network link so they are attached
#	${PG} -c "create table cbc.proxy_location as select distinct p1.qid as src_qid,p2.qid as proxy_qid,c2.pop_2000-c1.pop_2000 as pop_diff,connected,population,similar_facility,sewage, p1.biomass_refinery from cbc.potential_location p1 join city c1 using (qid) join cbc.potential_location p2 using(connected,population,similar_facility,sewage) join city c2 on (p2.qid=c2.qid) where (p1.biomass_refinery is False and distance(c1.centroid,c2.centroid) < 20000 and (c1.pop_2000 < c2.pop_2000 or (c1.pop_2000=c2.pop_2000 and c1.centroid < c2.centroid))) or p1.qid=p2.qid;"
	${PG} -c "create table cbc.proxy_location as select distinct p1.qid as src_qid,p2.qid as proxy_qid,c2.pop_2000-c1.pop_2000 as pop_diff,sewage, p1.biomass_refinery from cbc.potential_location p1 join city c1 using (qid) join cbc.potential_location p2 using(sewage) join city c2 on (p2.qid=c2.qid) where (p1.biomass_refinery is False and distance(c1.centroid,c2.centroid) < 20000 and (c1.pop_2000 < c2.pop_2000 or (c1.pop_2000=c2.pop_2000 and c1.centroid < c2.centroid))) or p1.qid=p2.qid;"
	${PG} -c "delete from cbc.proxy_location c where pop_diff != (select max(pop_diff) from cbc.proxy_location where src_qid=c.src_qid)";
	${PG} -c "delete from cbc.proxy_location c where pop_diff = 0 and src_qid <> proxy_qid;"
	pgsql2shp -g centroid -f $@ ${db} "select p.*,centroid from (select distinct proxy_qid as qid,sewage,bool_or(biomass_refinery) as biomass_refinery from cbc.proxy_location group by proxy_qid,sewage) as p join city c using (qid)"

cbc/feedstock.shp:cbc/%.shp:
	${PG} -c "drop table cbc.$*" || true;
	${PG} -f input/cbc.feedstock.sql
	${PG} -c "insert into cbc.$* (qid,type,state_fips,fips55,cost,amount,centroid) select qid,type,state_fips,fips55,cost,amount,centroid from feedstock where state_fips='06' and centroid is not Null;"
	${PG} -c "insert into cbc.$* (qid,type,state_fips,fips55,cost,amount,centroid) select replace(s.qid,'D','M') as qid,trim(both from 'MSW '||type) as type,x.state_fips,x.fips55,0 as cost,amount*pow(exp(ln(pop2020/pop2010)/10),5) as amount,x.centroid from (select distinct swisno,qid from cbc.swis) as s join cbc.msw_by_facility m using (swisno) join city x using(qid) join cbc.population p on ('S'||x.fips=p.qid);"
	${PG} -c "update cbc.feedstock set cost=10 where type in ('MSW Leaves & Grass','MSW Branches & Stumps','MSW Prunings, Trimmings');"
	${PG} -c "update cbc.feedstock set cost=27.5 where type in ('MSW Paper/ Cardboard','MSW Other Biomass/ Composite''MSW C&D Lumber');"
# Adding costs to the cbc is a tricky business.  We use this.
	${PG} -c "update cbc.feedstock f set cost=c.default_cost from feedstock_group g join cbc.group_type_cost c using (group_type) where f.type=g.type and f.cost is Null;"
# which is equivalent to 
#update feedstock f set cost=c.default_cost from feedstock_group g join group_type_cost c using (group_type) where f.type=g.group_type;
	# And even trickier we use this to match the WGA costs
	${PG} -c "insert into cbc.$* select f.qid,f.type,f.state_fips,f.fips55,c.cost,f.amount*c.fraction as amount from cbc.feedstock f join (select qid,group_type,cost,(sum/total)::decimal(4,2) as fraction from (select f.qid,g.group_type,f.cost,sum(amount) as sum from feedstock f join feedstock_group g using (type) where group_type in ('straw','stover') group by f.qid,g.group_type,f.cost) as sum join ( select f.qid,g.group_type,sum(amount) as total from feedstock f join feedstock_group g using (type) where group_type in ('straw','stover') group by qid,group_type having sum(amount) <> 0 ) as tot using (qid,group_type) where (sum/total) >0) as c on (f.qid=c.qid and f.type='cbc_'||c.group_type) order by qid,type,cost;"
	${PG} -c "delete from cbc.$* where type in ('cbc_straw','cbc_stover') and cost is Null;"
#	${PG} -c "select AddGeometryColumn('cbc','$*','ca_centroid',3310,'POINT',2);"
#	${PG} -c "update cbc.$* c set ca_centroid=transform(centroid,3310)"
	${PG} -c "update cbc.$* c set centroid=cx.centroid from county cx where c.qid=cx.qid"
	pgsql2shp -g centroid -f $@ $(db) cbc.$*


cbc/feedstock_locations.shp:cbc/%.shp:cbc/feedstock.shp
	pgsql2shp -g centroid -f $@ $(db) "select distinct qid,centroid from cbc.feedstock;"

cbc/population.csv:
	[[ -f input/p-1_Tables.xls ]] || wget -O input/P-1_Tables.xls http://www.dof.ca.gov/HTML/DEMOGRAP/ReportsPapers/Projections/P1/documents/P-1_Tables.xls

# Output
cbc_gams_tables:=cbc/gams_supply.csv cbc/gams_price.csv cbc/gams_src2refine_wetton.csv cbc/gams_src2refine_100gal.csv cbc/gams_source_list.csv cbc/gams_complete_refine_list.csv cbc/gams_refine_list.csv cbc/gams_terminal_transport.csv cbc/gams_ethanol_list.csv cbc/gams_biomass_list.csv

cbc/gams.zip: ${cbc_gams_tables}
	zip $@ $?

cbc/gams_supply.csv:cbc/%.csv: cbc/feedstock.shp feedstock_group.csv
	${PG} -c 'drop table cbc.$*' || true;
	${PG} -c "create table cbc.$* as select trim(both from qid) as source_id,fg.group_type as type,'PL'||replace(cost,'.','_') as price_id,sum(amount) as marginal_addition from cbc.feedstock f join feedstock_group fg using (type) group by source_id,fg.group_type,price_id order by source_id,type,price_id"
	${PG} -c "copy cbc.$* (source_id,type,price_id,marginal_addition) TO STDOUT DELIMITER ',' CSV HEADER" > $@;

cbc/gams_price.csv:cbc/%.csv: cbc/feedstock.shp
	${PG} -c "drop table cbc.$*" || true;
	${PG} -c "create table cbc.$* as select distinct 'PL'||replace(cost,'.','_') as price_id,cost as price from cbc.feedstock;"
	${PG} -c "copy cbc.$* (price_id,price) TO STDOUT DELIMITER ',' CSV HEADER" > $@

define cbc_gams_src2refine
cbc/gams_src2refine_$1.csv:cbc/%.csv: cbc/transportation_costs/feedstock_potential_location_$1_road_odcost.shp cbc/transportation_costs/feedstock_potential_location_$1_min_odcost.shp
# Read in Transportation Costs
	shp2pgsql -D -d -s $(srid) -S -I cbc/transportation_costs/feedstock_potential_location_$1_road_odcost.shp cbc.feedstock_potential_location_$1_road_odcost | ${PG} > /dev/null;
	shp2pgsql -N skip -D -d -s $(srid) -S -I cbc/transportation_costs/feedstock_potential_location_$1_min_odcost.shp cbc.feedstock_potential_location_$1_min_odcost | ${PG} > /dev/null;
	${PG} -c 'drop table cbc.$$*' || true;
	${PG} -c "create table cbc.$$* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id,r.$2 as road_only_cost, r.total_road as road_only_road_miles, r.total_mari as road_only_marine_miles,r.total_rail as road_only_rail_miles, r.total_mile as road_only_all_miles, r.total_road as road_only_road_hours,m.$2 as min_cost, m.total_road as min_road_miles, m.total_mari as min_marine_miles,m.total_rail as min_rail_miles, m.total_mile as min_all_miles, m.total_road as min_road_hours from cbc.feedstock_potential_location_$1_road_odcost r full outer join cbc.feedstock_potential_location_$1_min_odcost m using (name) order by source_id,min_cost;"
	${PG} -c "copy cbc.$$* (source_id,dest_id,road_only_cost,road_only_road_miles,road_only_marine_miles,road_only_rail_miles,road_only_all_miles,road_only_road_hours,min_cost,min_road_miles,min_marine_miles,min_rail_miles,min_all_miles,min_road_hours) TO STDOUT DELIMITER ',' CSV HEADER" > $$@
endef 

$(eval $(call cbc_gams_src2refine,wetton,total_wet_))
$(eval $(call cbc_gams_src2refine,100gal,total_100g))


cbc/gams_source_list.csv:%.csv: cbc/feedstock.shp
	${PG} -A -F',' --pset footer -c "select distinct qid as source_id from cbc.feedstock" > $@

cbc/gams_complete_refine_list.csv:%.csv: cbc/potential_location.shp
	${PG} -A -F',' --pset footer -c "select qid as dest_id,connected,population,similar_facility,biomass_refinery,sewage from cbc.potential_location" > $@ 

#	${PG} -A -F',' --pset footer -c "select distinct proxy_qid as qid,connected,population,similar_facility,bool_or(biomass_refinery) as biomass_refinery,sewage from cbc.proxy_location group by proxy_qid,connected,population,similar_facility,sewage" > $@;
cbc/gams_refine_list.csv:%.csv: cbc/proxy_location.shp
	${PG} -A -F',' --pset footer -c "select distinct proxy_qid as qid,bool_or(biomass_refinery) as biomass_refinery,sewage from cbc.proxy_location group by proxy_qid,sewage" > $@;

cbc/gams_ethanol_list.csv:%csv:cbc/potential_location.shp
	${PG} -A -F',' --pset footer -c "select qid as dest_id,capacity_m,start_year,feedstock,status from cbc.ethanol where state='CA'" > $@ 

cbc/gams_biomass_list.csv:%csv:cbc/potential_location.shp
	${PG} -A -F',' --pset footer -c "select qid as dest_id,planttype,plantname,gross_mw,net_mw,status from cbc.bdircomb05_83 where state='CA'" > $@ 

cbc/gams_terminal_transport.csv:cbc/%.csv:transportation_costs/potential_location_terminal_fuel_min_cost.shp
	shp2pgsql -D -d -s $(srid) -S -I -g the_geom $< public.potential_location_terminal_fuel_min_cost | ${PG} > /dev/null;
	${PG} -c 'drop table cbc.$*' || true;
	${PG} -c "create table cbc.$* as select trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id, trim(both from substr(name,1,position(' - ' in name))) as terminal_id,total_fuel as cost,total_road, total_rail,total_mari as total_marine from potential_location_terminal_fuel_min_cost";
	${PG} -c "copy cbc.$* (dest_id,cost,terminal_id,total_road,total_rail,total_marine) TO STDOUT DELIMITER ',' CSV HEADER" > $@

cbc/feedstock_cost_by_ton.shp:cbc/%.shp:cbc/feedstock.shp feedstock_group.csv county.shp
	${PG} -c "drop table cbc.feedstock_group_ton" || true;
	${PG} -c  "create table cbc.feedstock_group_ton as select qid,cf as cost,group_type,sum(amount) as ton from cbc.feedstock f join feedstock_group fg using (type),generate_series(0,120,10) as cf where f.cost < cf  group by qid,group_type,cf union select qid,cf as cost,group_type,sum(amount) as tons from cbc.feedstock f join feedstock_group fg using (type),generate_series(200,800,100) as cf where f.cost < cf  group by qid,group_type,cf;"
	${PG} -c "drop table cbc.$*" || true;
	${PG} -c "create table cbc.$* as select qid,cost,f1.ton as HEC,f2.ton as OVW,f3.ton as canola_oil,f4.ton as corn,f5.ton as soybean_oil,f6.ton as grease,f7.ton as high_forest,f8.ton as lce,f9.ton as forest,fa.ton as cbc_msw_lc,fb.ton as msw_paper,fc.ton as msw_wood,fd.ton as msw_yard,fe.ton as oils,ff.ton as stover,fg.ton as straw,fh.ton as tallow from (select qid,cost,ton from cbc.feedstock_group_ton where group_type='HEC') as f1 full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='OVW') as f2 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='canola_oil') as f3 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='corn') as f4 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='soybean_oil') as f5 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='grease') as f6 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='high_forest') as f7 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='lce') as f8 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='forest') as f9 using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='cbc_msw_lc') as fa using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='msw_paper') as fb using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='msw_wood') as fc using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='msw_yard') as fd using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='oils') as fe using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='stover') as ff using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='straw') as fg using (qid,cost) full outer join (select qid,cost,ton from cbc.feedstock_group_ton where group_type='tallow') as fh using (qid,cost);"
	${PG} -c "select AddGeometryColumn('cbc','$*','centroid',3310,'POINT',2);"
	${PG} -c "update cbc.$* t set centroid=transform(c.centroid,3310) from cbc.feedstock c where t.qid=c.qid";
	${PG} -c "select AddGeometryColumn('cbc','$*','boundary',3310,'MULTIPOLYGON',2);"
	${PG} -c "update cbc.$* t set boundary=transform(c.boundary,3310) from county c where t.qid=c.qid";
	${PG} -c "alter table cbc.$* add column acres float; update $* t set acres=area(boundary)/4046.8726";
	pgsql2shp -g boundary -f cbc/feedstock_cost_by_ton_county.shp $(db) 'select * from cbc.$* where boundary is not null';
	pgsql2shp -g centroid -f $@ $(db) cbc.$*

cbc/feedstock_cost_ton.csv:cbc/%.csv:cbc/feedstock_cost_by_ton.shp
	${PG} -A -F',' --pset footer -c "select cost,sum(HEC) as HEC,sum(OVW) as OVW,sum(corn) as corn,sum(grease) as grease,sum(high_forest) as high_forest,sum(lce) as lce, sum(forest) as forest,sum(msw_dirty) as msw_dirty,sum(msw_paper) as msw_paper,sum(msw_wood) as msw_wood,sum(msw_yard) as msw_yard,sum(canola_oil) as canola, sum(soybean_oil) as soybean,sum(oils) as oils,sum(stover) as stover,sum(straw) as straw,sum(tallow) as tallow from cbc.feedstock_cost_by_ton group by cost order by cost;" > $@

#############################################################################
# Special Methods for Nathan
#############################################################################

greg_transportation.csv:%.csv:transportation_costs/feedstock_potential_location_wetton_min_odcost.shp
	# Read in Transportation Costs
	shp2pgsql -D -d -s $(srid) -S -I transportation_costs/feedstock_potential_location_wetton_min_odcost.shp public.feedstock_potential_location_wetton_min_odcost | ${PG} > /dev/null;
	${PG} -c 'drop table $*' || true;
	${PG} -c "create table $* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id, n.total_wet_ as wetton,n.total_allm as mile, n.total_road as road,n.total_rail as rail, n.total_mari as marine from feedstock_potential_location_wetton_min_odcost n"
	${PG} -c "copy $* (source_id,dest_id,wetton,road,rail,marine) TO STDOUT DELIMITER ',' CSV HEADER" > $@

greg_tonnage.csv:%.csv:
	${PG} -A -F',' --pset footer -c "select type,sum(quant_tons*road) as roadton, sum(quant_tons*rail) as railton,sum(quant_tons*marine) as marineton from target_price_links join greg_transportation using (source_id,dest_id) group by type order by type" > $@;

greg_grease.csv:%.csv:
	${PG} -A -F',' --pset footer -c "select type,source_id,dest_id,quant_tons,road,rail,marine,quant_tons*road as roadton, quant_tons*rail as railton,quant_tons*marine as marineton from target_price_links join greg_transportation using (source_id,dest_id) where type='grease' order by rail desc" > $@;

#target_price_links.shp:%.shp:gams/%.csv
#	@${PG} -c 'drop table $*' || true;
#	@${PG} -c 'create table $* (run char(8),source_id char(8), dest_id char(8), type varchar(50),quant_tons float);'
#	cat $< | $(PG) -c "copy $* (run,source_id,dest_id,type,quant_tons) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";

target_price_links.shp:%.shp:gams/target_price_lce_links.csv
	@${PG} -c 'drop table $*' || true;
	@${PG} -c 'create table $* (source_id char(8), dest_id char(8), type varchar(50),quant_tons float);'
	cat $< | $(PG) -c "copy $* (source_id,dest_id,type,quant_tons) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";

greg_states.csv: 
	${PG} -A -F',' --pset footer -c "select state,type,sum(quant_tons) as total from target_price_links join wga_states s on (substr(source_id,2,2)=s.state_fips) group by state,type order by state,type;" > $@
#	$(PG) -c "update $* f set qid=cx.qid from city cx where f.state=cx.state and lower(f.city)=lower(cx.name) and f.state in (select state from wga_states);";

greg_terminal_transport.csv:%.csv:transportation_costs/potential_location_terminal_fuel_min_cost.shp
	shp2pgsql -D -d -s $(srid) -S -I -g the_geom $< public.potential_location_terminal_fuel_min_cost | ${PG} > /dev/null;
	${PG} -c 'drop table $*' || true;
	${PG} -c "create table $* as select trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id, total_fuel as cost from potential_location_terminal_fuel_min_cost";
	${PG} -c "copy $* (dest_id,cost) TO STDOUT DELIMITER ',' CSV HEADER" > $@


grease_transportation.csv:%.csv:transportation_costs/grease_only_feedstock_potential_location_wetton_min_odcost.shp
	# Read in Transportation Costs
	shp2pgsql -D -d -s $(srid) -S -I transportation_costs/grease_only_feedstock_potential_location_wetton_min_odcost.shp public.grease_only_feedstock_potential_location_wetton_min_odcost | ${PG} > /dev/null;
	${PG} -c 'drop table $*' || true;
	${PG} -c "create table $* as select trim(both from substr(name,1,position(' - ' in name))) as source_id, trim(both from substr(name,position(' - ' in name)+3,100)) as dest_id, n.total_wet_ as wetton,n.total_mile as mile, n.total_road as road,n.total_rail as rail, n.total_mari as marine from grease_only_feedstock_potential_location_wetton_min_odcost n"
	${PG} -c "copy $* (source_id,dest_id,wetton,mile,road,rail,marine) TO STDOUT DELIMITER ',' CSV HEADER" > $@

target_price_grease_tallow_links.shp:%.shp:gams/%.csv
	@${PG} -c 'drop table $*' || true;
	@${PG} -c 'create table $* (run char(8),source_id char(8), dest_id char(8), type varchar(50),quant_tons float);'
	cat $< | $(PG) -c "copy $* (run,source_id,dest_id,type,quant_tons) FROM STDIN WITH DELIMITER AS ',' CSV HEADER";

grease_tonnage.csv:%.csv:
	${PG} -A -F',' --pset footer -c "select type,sum(quant_tons*road) as roadton, sum(quant_tons*rail) as railton,sum(quant_tons*marine) as marineton from target_price_grease_tallow_links join greg_transportation using (source_id,dest_id) group by type" > $@;

grease_states.csv:
	${PG} -A -F',' --pset footer -c "select state,type,sum(quant_tons) as total from target_price_grease_tallow_links join wga_states s on (substr(source_id,2,2)=s.state_fips) group by state,type order by state,type;" > $@
#	$(PG) -c "update $* f set qid=cx.qid from city cx where f.state=cx.state and lower(f.city)=lower(cx.name) and f.state in (select state from wga_states);";
