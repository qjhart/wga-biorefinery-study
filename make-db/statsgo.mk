#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.

ifndef db
include configure.mk
endif

INFO::
	@echo STATSGO Data
	@echo   from Soil Data Mart 


########################################################################
# STATSGO data is downloaded manually from soildata mart
# http://soildatamart.nrcs.usda.gov/USDGSM.aspx
########################################################################
zip:=${down}/gsmsoil_us.zip
tab:=gsmsoil_us/tabular

${db}/statsgo:
	${PG} -f make-db/statsgo/schema.sql
	${PG} -f make-db/statsgo/domains.sql
	touch $@

db/statsgo.map_unit db/statsgo.map_unit_poly: shp:=${down}/gsmsoil_us/spatial/gsmsoilmu_a_us.shp
db/statsgo.map_unit db/statsgo.map_unit_poly: db/statsgo
	${PG} -f make-db/statsgo/map_unit.sql
	[[ -f ${shp} ]] || unzip -j -d ${down} ${zip};
	${shp2pgsql} -a -s 4269 -S ${shp} statsgo.tmp_map_unit | ${PG} > /dev/null;
	${PG} -c 'insert into statsgo.map_unit_poly (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(the_geom,${srid}) from statsgo.tmp_map_unit';
	${PG} -c 'insert into statsgo.map_unit (areasymbol,spatialver,musym,mukey,boundary) select areasymbol,spatialver,musym,mukey,transform(collect(the_geom),${srid}) from statsgo.tmp_map_unit group by areasymbol,spatialver,musym,mukey';
	${PG} -c 'drop table statsgo.tmp_map_unit;';
	touch db/statsgo.map_unit db/statsgo.map_unit_poly

.PHONY:${db}/statsgo.mapunit
${db}/statsgo.mapunit:${db}/statsgo.%:${db}/statsgo
	${PG} -f make-db/statsgo/$*.sql
	unzip -p ${zip} ${tab}/$*.txt |\
	${PG} -c "COPY statsgo.$* (musym,muname,mukind,mustatus,muacres,mapunitlfw_l,mapunitlfw_r,mapunitlfw_h,mapunitpfa_l,mapunitpfa_r,mapunitpfa_h,farmlndcl,muhelcl,muwathelcl,muwndhelcl,interpfocus,invesintens,iacornsr,nhiforsoigrp,nhspiagr,vtsepticsyscl,mucertstat,lkey,mukey) FROM STDIN DELIMITER AS '|' CSV QUOTE AS '\"'";

${db}/statsgo.component:${db}/statsgo.%:${db}/statsgo
	${PG} -f make-db/statsgo/$*.sql
	  unzip -p ${zip} ${tab}/comp.txt |\
	  ${PG} -c "COPY statsgo.$* (comppct_l,comppct_r,comppct_h,compname,compkind,majcompflag,otherph,localphase,slope_l,slope_r,slope_h,slopelenusle_l,slopelenusle_r,slopelenusle_h,runoff,tfact,wei,weg,erocl,earthcovkind1,earthcovkind2,hydricon,hydricrating,drainagecl,elev_l,elev_r,elev_h,aspectccwise,aspectrep,aspectcwise,geomdesc,albedodry_l,albedodry_r,albedodry_h,airtempa_l,airtempa_r,airtempa_h,map_l,map_r,map_h,reannualprecip_l,reannualprecip_r,reannualprecip_h,ffd_l,ffd_r,ffd_h,nirrcapcl,nirrcapscl,nirrcapunit,irrcapcl,irrcapscl,irrcapunit,cropprodindex,constreeshrubgrp,wndbrksuitgrp,rsprod_l,rsprod_r,rsprod_h,foragesuitgrpid,wlgrain,wlgrass,wlherbaceous,wlshrub,wlconiferous,wlhardwood,wlwetplant,wlshallowwat,wlrangeland,wlopenland,wlwoodland,wlwetland,soilslippot,frostact,initsub_l,initsub_r,initsub_h,totalsub_l,totalsub_r,totalsub_h,hydgrp,corcon,corsteel,taxclname,taxorder,taxsuborder,taxgrtgroup,taxsubgrp,taxpartsize,taxpartsizemod,taxceactcl,taxreaction,taxtempcl,taxmoistscl,taxtempregime,soiltaxedition,castorieindex,flecolcomnum,flhe,flphe,flsoilleachpot,flsoirunoffpot,fltemik2use,fltriumph2use,indraingrp,innitrateleachi,misoimgmtgrp,vasoimgtgrp,mukey,cokey) FROM STDIN DELIMITER AS '|' CSV QUOTE AS '\"'";
	touch $@

# Goes blazing fast when you don't compose the polys.  Have to be
# careful when you run this, since it does depend on pfarm_county and
# ssurgo.map_unit_poly (The single one)
${db}/statsgo.county_map_unit_poly:${db}/%:${db}/network.county ${db}/ssurgo.map_unit_poly
	${PG} -f '$(subst .,/,$*).sql'
	touch $@


