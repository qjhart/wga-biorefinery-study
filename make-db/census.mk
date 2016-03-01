#! /usr/bin/make -f
census.mk:=1

ifndef db
include configure.mk
endif

states:=01 02 04 05 06 08 09 10 12 13 15 16 17 18 19 \
 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 \
 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56

#select 'S'||state_fips||':='||state_fips||'_'||upper(replace(state,' ','_')) from network.state 
#where state_fips::integer < 60 and state_fips::integer != 11 order by state_fips;

 S01:=01_ALABAMA
 S02:=02_ALASKA
 S04:=04_ARIZONA
 S05:=05_ARKANSAS
 S06:=06_CALIFORNIA
 S08:=08_COLORADO
 S09:=09_CONNECTICUT
 S10:=10_DELAWARE
 S12:=12_FLORIDA
 S13:=13_GEORGIA
 S15:=15_HAWAII
 S16:=16_IDAHO
 S17:=17_ILLINOIS
 S18:=18_INDIANA
 S19:=19_IOWA
 S20:=20_KANSAS
 S21:=21_KENTUCKY
 S22:=22_LOUISIANA
 S23:=23_MAINE
 S24:=24_MARYLAND
 S25:=25_MASSACHUSETTS
 S26:=26_MICHIGAN
 S27:=27_MINNESOTA
 S28:=28_MISSISSIPPI
 S29:=29_MISSOURI
 S30:=30_MONTANA
 S31:=31_NEBRASKA
 S32:=32_NEVADA
 S33:=33_NEW_HAMPSHIRE
 S34:=34_NEW_JERSEY
 S35:=35_NEW_MEXICO
 S36:=36_NEW_YORK
 S37:=37_NORTH_CAROLINA
 S38:=38_NORTH_DAKOTA
 S39:=39_OHIO
 S40:=40_OKLAHOMA
 S41:=41_OREGON
 S42:=42_PENNSYLVANIA
 S44:=44_RHODE_ISLAND
 S45:=45_SOUTH_CAROLINA
 S46:=46_SOUTH_DAKOTA
 S47:=47_TENNESSEE
 S48:=48_TEXAS
 S49:=49_UTAH
 S50:=50_VERMONT
 S51:=51_VIRGINIA
 S53:=53_WASHINGTON
 S54:=54_WEST_VIRGINIA
 S55:=55_WISCONSIN
 S56:=56_WYOMING

ftp:=ftp://ftp2.census.gov/geo/tiger/TIGER2008/

INFO::
	@echo Census data
	@echo from ${zips}

.PHONY:db
db::${db}/census
${db}/census:
	${PG} -f census/schema.sql
	touch $@

.PHONY:tract00
define census

${down}/census/${S$1}/tl_2008_$1_tract00.shp:
	[[ -d $$(dir $$@) ]] || mkdir -p $$(dir $$@)
	[[ -f ${down}/census/${S$1}/tl_2008_$1_tract00.zip ]] || wget -O $$@ ${ftp}/${S$1}/tl_2008_$1_tract00.zip
	cd $$(dir $$@); \
	unzip tl_2008_$1_tract00.zip

db::${db}/census.tract00
${db}/census.tract00::${db}/census.tract00.$1
	touch $@

${db}/census.tract00.$1:${down}/census/${S$1}/tl_2008_$1_tract00.shp ${db}/census
	${shp2pgsql} -a -s 4269 $$< census.tract00 | ${PG} > /dev/null
	${PG} -c 'update census.tract00 set boundary=transform(the_geom,${srid}) where boundary is Null;'
	${PG} -c 'update census.tract00 set centroid=centroid(boundary) where centroid is Null;'
	touch $$@

endef

$(foreach s,${states},$(eval $(call census,$s)))



