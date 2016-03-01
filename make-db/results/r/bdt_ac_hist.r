library(RPostgreSQL)

con <- dbConnect("PostgreSQL", user = "nathan", password="p4rk3r", db="biomass_pt")
grab <- dbSendQuery(con, "select chftt2km/2.47 as num from src_all_m where src_type = 3 and chftt2km >0")
bdtac <- fetch(grab)
dbClearResult(grab)

hist(bdtac$num, xlab ="bdt/ac",main="BDT/AC histogram for 2.47 ac technically\n feasible forested areas in California")
summary(bdtac$num)
dbDisconnect(con)