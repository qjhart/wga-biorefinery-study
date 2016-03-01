#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
inl:=1

ifndef db
include configure.mk
endif

ifndef pfarm
include pfarm.mk
endif

ifndef national_atlas
include national_atlas.mk
endif

INFO::
	@echo Make INL project completion
	@echo '${.VARIABLES}'
	@echo '${MAKEFILE_LIST}'

########################################################################
# NASS data is downloaded into zip files manually.  The data comes from 
########################################################################
db::${db}/inl.model

${db}/inl.model:
	${PG} -f ${src}/inl/model.sql
	touch $@

${db}/inl.edge:db/network.vertex db/network.edge ${db}/inl.model
	${PG} -f make-db/inl/pfarm-model.sql
	touch ${db}/inl.edges


${db}/inl.odcost:s:=inl
${db}/inl.odcost:t:=odcost
${db}/inl.odcost:shp:=inlpfarmsource_dest_odcost.shp
${db}/inl.odcost:${db}/%:
	${shp2pgsql} -D -d -s ${srid} -g line -S downloads/${shp} $s.$t | ${PG} > /dev/null
	touch $@;


inl.pfarm_dest-g:=point
inl.pfarm_source-g:=point
inl.edge-g:=route

${out}/inl.pfarm_dest.shp ${out}/inl.pfarm_source.shp ${out}/inl.edge.shp:${out}/%.shp:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	${pgsql2shp} -f $@ ${database} -g ${$*-g} $(notdir $*)
	echo '${srid-prj}' > $*.prj

${out}/pfarm.m_pfarm_nonirr_harvest_cost.dbf:${out}/%.dbf:
	[[ -d $(dir $@) ]] || mkdir -p $(dir $@)
	${pgsql2shp} -f $@ ${database} 'select * from $(notdir $*) where year=2007'

#${db}/pfarm.complete_costs:${db}/pfarm.pfarm_county ${db}/pfarm.m_pfarm_nonirr_harvest_cost ${db}/inl.odcost;
${db}/pfarm.complete_costs:${db}/pfarm.pfarm_county
	${PG} -c "create table pfarm.complete_costs as select hc.pfarm_gid,hc.fips,p.qid as facility,hc.arable_acres,hc.actual_nonirr_yield,hc.residue,hc.windrowing,hc.baling,hc.roadsiding,hc.wrapping,hc.rent,hc.insurance,(inl.loading_cost('bale',hc.fips,2007)).loading as bale_loading,o.total_mile,o.total_hour,o.total_trav,(inl.preprocessing(p.fips,2007,1900000)).* from inl.m_pfarm_source s join inl.odcost o on (s.id=o.src_id) join inl.m_pfarm_dest d on (o.dest_id=d.id) join network.place p on (d.point=p.centroid) join pfarm.pfarm_county pc on (s.point=centroid(pc.boundary)) join pfarm.m_pfarm_nonirr_harvest_cost hc using (pfarm_gid) where hc.year=2007;"
	touch $@;

${out}/pfarm.complete_costs.csv:${db}/pfarm.complete_costs
	${PG-CSV} -c 'select * from pfarm.complete_costs c join ( select pfarm_gid,min(total_trav) as total_trav from pfarm.complete_costs group by pfarm_gid ) as min using (pfarm_gid,total_trav);' > $@



