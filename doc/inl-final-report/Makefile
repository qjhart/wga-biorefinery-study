#! /usr/bin/make -f

#include ../make-db/configure.mk
# These came from the above
database:= usda
user:=${USER}
PG:=psql --cluster 8.3/main -d $(database)

PSQL := ${PG} -P footer=off -P fieldsep=" " -A

# TransFig makefile
#
slides:=inl-report

#figs:=spatial_re spatial_re2
figs:=

xfig:
	xfig -specialtext -latexfonts -startlatexFont default &

#
# Here's a common way to build tex files from fig documents
#
.PHONY: pdf figs
define xfig
pdf:: $(1).pdf.tex
$(1).pdf.tex: $(1)_fig.pdf
	fig2dev -L pdftex_t -p $(1)_fig.pdf $(1).fig $(1).pdf.tex
$(1)_fig.pdf: $(1).fig


	fig2dev -L pdftex $(1).fig $(1)_fig.pdf
clean::
	rm -f $(1).pdf.tex $(1)_fig.pdf
endef

$(foreach f,$(figs),$(eval $(call xfig,$(f))))

define R
pdf:: $(1).pdf
png:: $(1).png

$(1).pdf: $(1).R $(1).dat
	(echo 'pdf("$$@",onefile=FALSE,height=2.5,width=4,pointsize=8)'; cat $$<; echo 'dev.off()') | R --vanilla

$(1).png: $(1).R $(1).dat
	(echo 'png(filename="$$@",units="in",res=200,height=2.5,width=4,pointsize=8)'; cat $$<; echo 'dev.off()') | R --vanilla

endef

#$(foreach f,road_hist residue residue-all biomass,$(eval $(call R,$(f))))

farm_cost_R:=road_hist farmgate total

.PHONY:pdf
pdf::$(patsubst %,%.pdf,${farm_cost_R})

$(patsubst %,%.pdf,${farm_cost_R}):%.pdf: %.R farm_cost.csv
	(echo 'pdf("$@",onefile=FALSE,height=2.5,width=4,pointsize=8)'; cat $<; echo 'dev.off()') | R --vanilla

$(patsubst %,%.png,${farm_cost_R}):%.png: %.R farm_cost.csv
	(echo 'png(filename="$$@",units="in",res=200,height=2.5,width=4,pointsize=8)'; cat $$<; echo 'dev.off()') | R --vanilla


#road_hist.dat:
#	${PSQL} -c "select src,dest,sum(cost) from tmp.inl_shortest_paths group by src,dest;" > $@

residue.dat:
	${PSQL} -c "select residue from pfarm.pfarm_crop_residue join pfarm.m_pfarm_actual_biomass using (pfarm_gid) where year=2007" >$@;

residue-all.dat:
	${PSQL} -c "select residue from pfarm.pfarm_crop_residue" >$@;

biomass.dat:
	${PSQL} -c "select actual_nonirr_biomass from pfarm.m_pfarm_actual_biomass where year=2007" >$@;



pdf::${slides}.pdf
$(slides).pdf: $(slides).tex
	pdflatex $(slides)
	pdflatex $(slides)


farm_cost.csv:
	${PSQL} -c "create temp table farm_costs as select pfarm_gid,dest_id,fips,actual_nonirr_yield,bdt,arable_acres,windrowing/0.88/0.95 as windrowing,baling/0.88/0.95 as baling,roadsiding/0.88/0.95 as roadsiding,wrapping/0.88/0.95 as wrapping,rent/0.88/0.95 as rent,insurance/0.88/0.95 as insurance,total/0.88/0.95 as total_farmgate,total_trav/0.88 as travel,(inl.loading_cost('bale',fips,2007)).loading/0.88 as loading,(inl.loading_cost('bale',fips,2007)).unloading/0.88 as unloading,total/0.88/0.95+total_trav+2*(inl.loading_cost('bale',fips,2007)).loading/0.88 as total from pfarm.m_pfarm_nonirr_cost where year=2007; copy farm_costs to stdout csv header" > $@


refinery_cost_curves.csv:
	${PSQL} -c "create temp table ref_cost_curves as select dest_id,l.cost,sum(f.total_bdt) as total_bdt from (select generate_series(28,50) as cost) as l,(select pfarm_gid,dest_id,actual_nonirr_yield*bdt*arable_acres as total_bdt,total/0.88/0.95 as total_farmgate,total/0.88/0.95+total_trav+2*(inl.loading_cost('bale',fips,2007)).loading/0.88 as total from pfarm.m_pfarm_nonirr_cost where year=2007) as f where l.cost > f.total group by dest_id,l.cost order by dest_id,l.cost; create temp table ref_cost_curves_per as select cc.*,cc.total_bdt/s.max from ref_cost_curves cc join (select dest_id,max(total_bdt) as max from ref_cost_curves group by dest_id) as s using (dest_id) ; copy ref_cost_curves_per to stdout with csv header;" > $@





