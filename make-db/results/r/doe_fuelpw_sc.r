library(Rdbi)
library(RdbiPgSQL)

#

conn <- dbConnect(PgSQL(), host="", dbname="bioenergy", user="ptittmann", password="")

#dbListTables(conn)
#r_baseline results
query <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_baseline.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_baseline.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_lce float, grease_fame float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_lce float, seed_oils_fame float);")

r_baseline <- dbGetResult(query)
dbClearResult(query)
#r_baseline



# r_badlce results
pquery <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_badlce.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_badlce.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float,  ag_res_ft_diesel float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_ft_diesel float, forest_lce float, grease_fame float, hec_ft_diesel float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_ft_diesel float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_ft_diesel float, ovw_lce float, pulpwood_ft_diesel float, pulpwood_lce float, seed_oils_fame float);")
r_badlce <- dbGetResult(pquery)
dbClearResult(pquery)
#r_badlce



#r_cblend           
query <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_cblend.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_cblend.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float,  ag_res_ft_diesel float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_ft_diesel float, forest_lce float, grease_fame float, hec_ft_diesel float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_ft_diesel float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_ft_diesel float, ovw_lce float, pulpwood_ft_diesel float, pulpwood_lce float, seed_oils_fame float);")
r_cblend <- dbGetResult(query)
dbClearResult(query)

#r_cblend



#r_fedforest        
query <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_fedforest.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_fedforest.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_lce float, grease_fame float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_lce float, seed_oils_fame float);")
r_fedforest<- dbGetResult(query)
dbClearResult(query)
#r_fedforest



#r_ffv              
query<- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_ffv.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_ffv.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float, ag_res_ft_diesel float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_ft_diesel float, forest_lce float, grease_fame float, hec_ft_diesel float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_ft_diesel float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_ft_diesel float, pulpwood_lce float, seed_oils_fame float);")
r_ffv <- dbGetResult(query)
dbClearResult(query)

#r_ffv



#r_hiencrop         
query<- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_hiencrop.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_hiencrop.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_lce float, grease_fame float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_lce float, seed_oils_fame float);")
r_hiencrop <- dbGetResult(query)

dbClearResult(query)



#results r_loencrop
query <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_loencrop.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_loencrop.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float, ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_lce float, grease_fame float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_lce float, seed_oils_fame float);")
r_loencrop <- dbGetResult(query)

dbClearResult(query)



# results r_maxfeed
query <- dbSendQuery(conn, "select * from crosstab('select price_point, fstk_type||f_type as pathway , sum(quant_mgy*c.gal_per_bdt*d.energy_density_gge_per_gal)/1000 as Mgge from r_maxfeed.brfn join model.runs using (run) join model.conversion_efficiency c on (f_type=c.tech and fstk_type=c.type) join model.technology d on (f_type=d.tech) where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' group by price_point, pathway order by 1;','select distinct fstk_type||f_type from r_maxfeed.brfn where fstk_type NOT like ''%cost'' and fstk_type NOT like ''production'' and fstk_type not like ''credit'' order by 1;') as ct ( price_point float,  ag_res_lce float, animal_fats_fame float, corngrain_dry_mill float, corngrain_wet_mill float, forest_lce float, grease_fame float, hec_lce float, msw_dirty_ft_diesel float, msw_food_lce float, msw_paper_ft_diesel float, msw_paper_lce float, msw_wood_lce float, msw_yard_ft_diesel float, msw_yard_lce float, ovw_lce float, pulpwood_lce float, seed_oils_fame float);")
r_maxfeed <- dbGetResult(query)

dbClearResult(query)


#create a list of results tables
matrixlist <- list(r_baseline, r_badlce, r_cblend, r_fedforest, r_ffv, r_hiencrop, r_loencrop, r_maxfeed)  
#par(mfcol= c(5,5))
for (i in matrixlist){
                                         
  ptable<-i[,-1]#create plot matrix w/o price point column

  ptable [is.na(ptable)] <- 0 #convert NA values to 0
                                 
  maxval<-max(ptable) #create volume axis
  interval<-ceiling(maxval)/27
  mgy<- seq(0,ceiling(maxval), by=interval)                                      
  fprice <- c(i$price_point)#create price point axis
  #pdf(paste(i,"fuel_pw.pdf", sep=""), bg="white")
  matplot(ptable, fprice, type="l", col= rainbow(length(names(i))))
  rm(i,ptable, fprice, maxval, interval, mgy)
  dev.off()
}

#legend(x=-1, y=.25, names(i), col = rainbow(length(names(i))),  lty=1,  ncol=3)
