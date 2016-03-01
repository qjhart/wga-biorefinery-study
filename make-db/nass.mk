#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
nass.mk:=1

ifndef db
include configure.mk
endif

#data_tables:=County18232 County910
data_tables:=County17525

INFO::
	@echo NASS Data from www.nass.usda.gov
	@echo NASS ASDS http://www.nass.usda.gov/Charts_and_Maps/Crops_County/boundary_maps/asds.zip

${db}/nass ${db}/nass.commcode_growth_2007_2015:
	${PG} -f ${src}/nass/schema.sql
	touch ${db}/nass ${db}/nass.commcode_biomass_yield ${db}/nass.commcode_growth_2007_2015

${db}/nass.commcode_biomass_yield:g:=http://spreadsheets.google.com/pub?key=t0mqxYK9DC6iuHOhP24pFWA&single=true&gid=0&output=csv
${db}/nass.commcode_biomass_yield:${db}/nass
	wget -O - '${g}' | ${PG} -c 'COPY nass.commcode_biomass_yield (commcode,praccode,biomassunit,biopercrop,biohareff,bioavail,productionunit,yieldunit) FROM STDIN WITH CSV HEADER;'
	touch $@

#######################################################################
#
# Yearly NASS dumps are now available
#######################################################################
years:=2000 2001 2002 2003 2004 2005 2006 2007 2008
year-url:=http://www.nass.usda.gov/Data_and_Statistics/Pre-Extracted_Data/Year

${db}/nass.nass:$(patsubst %,db/nass.nass+%,${years})
	touch $@

${db}/nass.feedstock:${db}/network.county ${db}/nass.nass ${db}/nass.commcode_biomass_yield
	${PG} -f nass/feedstock.sql
	touch $@

$(patsubst %,${down}/CCROP_%.csv,${years}):${down}/CCROP_%.csv:
	[[ -f ${down}/CCROP_$*.zip ]] || wget -O ${down}/CCROP_$*.zip ${year-url}/CCROP_$*.zip
	unzip -p ${down}/CCROP_$*.zip | tr -d '\r' > $@

$(patsubst %,db/nass.nass+%,${years}):db/nass.nass+%:${down}/CCROP_%.csv
	sed -e "s|@FILE@|`pwd`/${down}/CCROP_$*.csv|" make-db/nass/year.sql.template | ${PG} -f -
#	rm -f ${down}/CCROP_$*.zip ${down}/CCROP_$*.csv
	touch $@

${out}/nathan.csv:
	${PG-CSV} -c "select commcode,praccode,'BDT' as biomassUnit,'x*(ProductionUnit)' as bioPerCrop,0.50 as bioHarEff,0.5 as bioAvail, commodity_description,practice,n.production,n.productionUnit,n.planted,n.pltdHarv,pltdYield,yield,yieldUnit from (select commcode,praccode,sum(planted)/8 as planted,(sum(pltdHarv)/8)::decimal(10,2) as pltdHarv,avg(pltdYield)::decimal(10,2) as pltdYield,avg(yield)::decimal(10,2) as yield,yieldUnit,(sum(production)/8)::bigint as production,productionUnit from nass.nass group by commcode,praccode,yieldUnit,productionUnit) as n join nass.commodity c using (commcode) join nass.practice p using (praccode);" > $@

########################################################################
# For 2007, we can also get a complete data zipefile.
########################################################################
nass-db-zip:=dataquery.zip
nass-url:=http://www.agcensus.usda.gov/Publications/2007/Online_Highlights/Desktop_Application/${nass-db-zip}

db/nass.foo:
	[[ -f ${down}/${nass-db-zip} ]] || ( cd ${down}; wget ${nass-url} )


${db}/nass.stubs2:${down}/dataquery/stubs2.dbf
	${ogr_dbf} -select chapter,centable,drow,stub,forlist $< -nln $(notdir $@)
	touch $@


${db}/nass.ch2table8:${down}/dataquery/Ch2Table8.DBF
	${ogr_dbf} -select state,county,row,centable,data $< -nln $(notdir $@)
	${PG} -c "set search_path=nass,public; alter table ch2table8 add column qid varchar(8); update ch2table8 set qid='S'||state||county; create index ch2table8_qid on ch2table8(qid);create index ch2table8_row on ch2table8(row);"
	touch $@


########################################################################
# NASS data is downloaded into zip files manually.  The data comes from 
########################################################################
#
#.PHONY:${db}/tmp.nass_input+
#${db}/tmp.nass_input+:${db}/%+:${db}/nass
#	${PG} -f ${src}/nass/nass_input.sql;
#	for i in ${data_tables}; do \
#	  unzip -p ${down}/$$i | perl -a -F',' -n -e 'print if $$#F==21' |\
#	  ${PG} -c "COPY $* (commodity,practice,year,state,county,stfips,district,cofips,commcode,praccode,plantedallpurpose,plantedallpurposeunit,harvested,harvestedunit,yield,yieldunit,production,productionunit,yieldpernetseededacre,yieldpernetseededacreunit,netseeded,netseededunit) FROM STDIN DELIMITER AS ',' CSV HEADER"; \
#	done;
#	${PG} -c "update tmp.nass_input set fips=case WHEN (stfips<10) then '0'||stfips::varchar(1) ELSE stfips::varchar(2) END|| case WHEN (cofips<10) THEN '00'||cofips::varchar(1) WHEN (cofips<100) THEN '0'||cofips::varchar(2) ELSE cofips::varchar(3) END"


########################################################################
# Spatial data
#
########################################################################
${db}/nass.asds:s:=nass
${db}/nass.asds:t:=asds
${db}/nass.asds:url:=http://www.nass.usda.gov/Charts_and_Maps/Crops_County/boundary_maps/
${db}/nass.asds:down:=${down}/nass
${db}/nass.asds:zip:=asds.zip
${db}/nass.asds:${db}/%:
	[[ -f ${down}/${zip} ]] || ( [[ -d ${down} ]] || mkdir -p ${down}; cd ${down}; wget ${url}/${zip}; unzip ${zip} )
	${shp2pgsql} -d -s 4326 -g nad83 ${down}/$(word 1,$(subst ., ,${zip})).shp tmp.$t | ${PG} > /dev/null
	${shp2pgsql} -D -d -s 4326 -n -g nad83 -S ${down}/AsdandCountyName.dbf tmp.AsdandCountyName | ${PG} > /dev/null
	${PG} -c "drop table if exists $s.$t cascade;"
	${PG} -c "create table $s.$t (asd_gid serial primary key,asd varchar(2),stasd varchar(4));"
	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'MULTIPOLYGON',2);"
	${PG} -c "insert into $s.$t (asd_gid,asd,stasd,boundary) select gid,asd,stasd,transform(nad83,${srid}) as boundary from tmp.$t;"
	${PG} -c "create index $t_boundary_gist on $* using gist(boundary gist_geometry_ops)"
	${PG} -c "drop table tmp.$t;"
	touch $@;

${db}/nass.cropland:s:=nass
${db}/nass.cropland:t:=cropland
${db}/nass.cropland:down:=${down}/nass
${db}/nass.cropland:${db}/%:${down}/nass/cdl_ca_2007.shp
	${shp2pgsql} -d -s 26911 ${down}/cdl_ca_2007.shp tmp.$t | ${PG} > /dev/null
#	${PG} -c "drop table if exists $s.$t cascade;"
#	${PG} -c "create table $s.$t (asd_gid serial primary key,asd varchar(2),stasd varchar(4));"
#	${PG} -c "select AddGeometryColumn('$s','$t','boundary',$(srid),'MULTIPOLYGON',2);"
#	${PG} -c "insert into $s.$t (asd_gid,asd,stasd,boundary) select gid,asd,stasd,transform(nad83,${srid}) as boundary from tmp.$t;"
#	${PG} -c "create index $t_boundary_gist on $* using gist(boundary gist_geometry_ops)"
#	${PG} -c "drop table tmp.$t;"
	touch $@;


${db}/tmp.scp:s:=tmp
${db}/tmp.scp:t:=scp
${db}/tmp.scp:shp:=pt_working/cdl_ssurgo_pfarm_int.shp
${db}/tmp.scp:${db}/%:pt_working/cdl_ssurgo_pfarm_int.shp
	${shp2pgsql} -d -s ${srid} ${shp} $s.$t | ${PG} > /dev/null

