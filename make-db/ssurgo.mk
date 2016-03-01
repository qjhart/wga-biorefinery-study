#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.

ssurgo.mk:=1

ifndef db
include configure.mk
endif

#SELECT DISTINCT c.compname,c.comppct_r,mu.musym,mu.mukey,
#l.areasymbol, l.areaname, l.lkey
#FROM sacatalog sac
#INNER JOIN legend l ON sac.areasymbol = l.areasymbol
#INNER JOIN mapunit mu ON mu.lkey=l.lkey
#INNER JOIN component c ON mu.mukey=c.mukey
#WHERE sac.areasymbol IN ('IA011')

#survey_areas:= \
#az649  ca604  ca647  ca677  ca703\
#az656  ca605  ca648  ca678  ca707\
#ca011  ca606  ca649  ca679  ca708\
#ca013  ca607  ca651  ca680  ca713\
#ca021  ca608  ca653  ca681  ca719\
#ca031  ca609  ca654  ca682  ca724\
#ca033  ca610  ca659  ca683  ca729\
#ca041  ca612  ca660  ca684  ca731\
#ca053  ca614  ca664  ca685  ca732\
#ca055  ca618  ca665  ca687  ca740\
#ca067  ca619  ca666  ca688  ca750\
#ca069  ca620  ca667  ca689  ca760\
#ca077  ca624  ca668  ca692  ca763\
#ca087  ca628  ca669  ca693  ca777\
#ca095  ca632  ca670  ca694  ca790\
#ca097  ca637  ca671  ca695  ca795\
#ca101  ca638  ca672  ca697  ca802\
#ca113  ca642  ca673  ca698  ca803\
#ca600  ca644  ca674  ca699  ca805\
#ca602  ca645  ca675  ca701  ca603\
#ca646  ca676  ca702 \
#ks155 ks079 \
#ia013  ia031  ia065  ia113 ia011 ia019 ia055 ia105

survey_areas:=ks155 ks079 ks173 ks095 ks191 ks077 \
ia013  ia031  ia065  ia113 ia011 ia019 ia055 ia105

#biomass=# select distinct areasymbol from tmp.counties m join county c using (county_gid) join survey_area s  on(intersects(s.boundary,c.boundary)) where (100*area(intersection(c.boundary,s.boundary))/area(c.boundary)) > 1 order by areasymbol;
#map_unit_areas:= ca031 ca653 ca654 ca659 ca660 ca666 ca668 ca669 ca670 ca675 ca682 ca740 ca750 ca760 ks155 ks079
map_unit_areas:=ks155 ks079 ks173 ks095 ks191 ks077 \
ia013  ia031  ia065  ia113 ia011 ia019 ia055 ia105

INFO::
	@echo SSURGO Data
	@echo   from Soil Data Mart 
	@echo survey_units=${survey_units}

########################################################################
# SSURGO data is downloaded manually
# You can go directly to the survey area with this.
# http://soildatamart.nrcs.usda.gov/Download.aspx?Survey=KS191&UseState=KS
########################################################################
pfarm-db:: db/ssurgo db/ssurgo.survey_area db/ssurgo.map_unit db/ssurgo.map_unit_poly

${db}/ssurgo:
	${PG} -f make-db/ssurgo/schema.sql
	${PG} -f make-db/ssurgo/domains.sql
	touch $@

${db}/ssurgo.survey_area: ${db}/ssurgo
	${PG} -f make-db/ssurgo/survey_area.sql
	for s in ${survey_areas}; do \
	  [[ -f ${down}/ssurgo/soilsa_a_$$s.shp ]] || unzip -j -d ${down}/ssurgo ${down}/ssurgo/soil_$$s.zip soil_$$s/spatial/soilsa_a_$$s.*; \
	  srid=`cat ${down}/ssurgo/soilsa_a_$$s.prj | sed -e 's/.*Zone_\([0-9][0-9]\)N.*/269\1/'`; \
	  ${shp2pgsql} -a -s $$srid -S ${down}/ssurgo/soilsa_a_$$s.shp ssurgo.tmp_survey_area | ${PG}; \
	done;
	${PG} -c 'insert into ssurgo.survey_area (areasymbol,spatialver,lkey,boundary) select areasymbol,spatialver,lkey,transform(collect(the_geom),${srid}) from ssurgo.tmp_survey_area group by areasymbol,spatialver,lkey order by areasymbol,lkey,spatialver';
	${PG} -c 'truncate ssurgo.tmp_survey_area;';
	touch $@

db/ssurgo.map_unit db/ssurgo.map_unit_poly: db/ssurgo
	${PG} -f make-db/ssurgo/map_unit.sql
	for s in ${map_unit_areas}; do \
	  [[ -f ${down}/ssurgo/soilmu_a_$$s.shp ]] || unzip -j -d ${down}/ssurgo ${down}/ssurgo/soil_$$s.zip soil_$$s/spatial/soilmu_a_$$s*; \
	  srid=`cat ${down}/ssurgo/soilmu_a_$$s.prj | sed -e 's/.*Zone_\([0-9][0-9]\)N.*/269\1/'`; \
	  ${shp2pgsql} -a -s $$srid -S ${down}/ssurgo/soilmu_a_$$s.shp ssurgo.tmp_map_unit | ${PG} > /dev/null; \
	done;
	${PG} -c 'insert into ssurgo.map_unit_poly (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(the_geom,${srid}) from ssurgo.tmp_map_unit';
	${PG} -c 'insert into ssurgo.map_unit (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(collect(the_geom),${srid}) from ssurgo.tmp_map_unit group by areasymbol,spatialver,musym,mukey';
	${PG} -c 'truncate ssurgo.tmp_map_unit;';
	touch db/ssurgo.map_unit db/ssurgo.map_unit_poly

.PHONY:${db}/ssurgo.map_unit+ db/ssurgo.map_unit_poly+
${db}/ssurgo.map_unit+ db/ssurgo.map_unit_poly+:${db}/%:${db}/ssurgo db/ssurgo.map_unit db/ssurgo.map_unit_poly
	${PG} -c 'truncate ssurgo.tmp_map_unit;'; \
	for s in ${map_unit_areas}; do \
	  [[ -f ${down}/ssurgo/soilmu_a_$$s.shp ]] || unzip -j -d ${down}/ssurgo ${down}/ssurgo/soil_$$s.zip soil_$$s/spatial/soilmu_a_$$s*; \
	  srid=`cat ${down}/ssurgo/soilmu_a_$$s.prj | sed -e 's/.*Zone_\([0-9][0-9]\)N.*/269\1/'`; \
	  ${shp2pgsql} -a -s $$srid -S ${down}/ssurgo/soilmu_a_$$s.shp ssurgo.tmp_map_unit | ${PG} > /dev/null; \
	done;
	${PG} -c 'insert into ssurgo.map_unit_poly (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(the_geom,${srid}) from ssurgo.tmp_map_unit';
	${PG} -c 'insert into ssurgo.map_unit (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(collect(the_geom),${srid}) from ssurgo.tmp_map_unit group by areasymbol,spatialver,musym,mukey';
	${PG} -c 'truncate ssurgo.tmp_map_unit;';

${db}/ssurgo.mapunit ${db}/ssurgo.mucropyld:${db}/ssurgo.%:
	${PG} -f make-db/ssurgo/$*.sql
	touch $@

.PHONY:${db}/ssurgo.mucropyld+
${db}/ssurgo.mucropyld+:${db}/%+:${db}/ssurgo
	for s in ${map_unit_areas}; do \
	  unzip -p ${down}/ssurgo/soil_$$s.zip soil_$$s/tabular/mucrpyd.txt |\
	  ${PG} -c "COPY $* (cropname,yldunits,nonirryield_l,nonirryield_r,nonirryield_h,irryield_l,irryield_r,irryield_h,mukey,mucrpyldkey) FROM STDIN DELIMITER AS '|' CSV QUOTE AS '\"'"; \
	done;

.PHONY:${db}/ssurgo.mapunit+
${db}/ssurgo.mapunit+:${db}/%+:${db}/ssurgo
	for s in ${map_unit_areas}; do \
	  unzip -p ${down}/ssurgo/soil_$$s.zip soil_$$s/tabular/mapunit.txt |\
	  ${PG} -c "COPY $* (musym,muname,mukind,mustatus,muacres,mapunitlfw_l,mapunitlfw_r,mapunitlfw_h,mapunitpfa_l,mapunitpfa_r,mapunitpfa_h,farmlndcl,muhelcl,muwathelcl,muwndhelcl,interpfocus,invesintens,iacornsr,nhiforsoigrp,nhspiagr,vtsepticsyscl,mucertstat,lkey,mukey) FROM STDIN DELIMITER AS '|' CSV QUOTE AS '\"'"; \
	done;

${db}/ssurgo.component:${db}/ssurgo.%:
	${PG} -f make-db/ssurgo/$*.sql
	touch $@

.PHONY:${db}/ssurgo.component+
${db}/ssurgo.component+:${db}/%+:${db}/ssurgo
	for s in ${map_unit_areas}; do \
	  unzip -p ${down}/ssurgo/soil_$$s.zip soil_$$s/tabular/comp.txt |\
	  ${PG} -c "COPY $* (comppct_l,comppct_r,comppct_h,compname,compkind,majcompflag,otherph,localphase,slope_l,slope_r,slope_h,slopelenusle_l,slopelenusle_r,slopelenusle_h,runoff,tfact,wei,weg,erocl,earthcovkind1,earthcovkind2,hydricon,hydricrating,drainagecl,elev_l,elev_r,elev_h,aspectccwise,aspectrep,aspectcwise,geomdesc,albedodry_l,albedodry_r,albedodry_h,airtempa_l,airtempa_r,airtempa_h,map_l,map_r,map_h,reannualprecip_l,reannualprecip_r,reannualprecip_h,ffd_l,ffd_r,ffd_h,nirrcapcl,nirrcapscl,nirrcapunit,irrcapcl,irrcapscl,irrcapunit,cropprodindex,constreeshrubgrp,wndbrksuitgrp,rsprod_l,rsprod_r,rsprod_h,foragesuitgrpid,wlgrain,wlgrass,wlherbaceous,wlshrub,wlconiferous,wlhardwood,wlwetplant,wlshallowwat,wlrangeland,wlopenland,wlwoodland,wlwetland,soilslippot,frostact,initsub_l,initsub_r,initsub_h,totalsub_l,totalsub_r,totalsub_h,hydgrp,corcon,corsteel,taxclname,taxorder,taxsuborder,taxgrtgroup,taxsubgrp,taxpartsize,taxpartsizemod,taxceactcl,taxreaction,taxtempcl,taxmoistscl,taxtempregime,soiltaxedition,castorieindex,flecolcomnum,flhe,flphe,flsoilleachpot,flsoirunoffpot,fltemik2use,fltriumph2use,indraingrp,innitrateleachi,misoimgmtgrp,vasoimgtgrp,mukey,cokey) FROM STDIN DELIMITER AS '|' CSV QUOTE AS '\"'"; \
	done;




