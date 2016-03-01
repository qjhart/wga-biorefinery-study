library(RPostgreSQL)

con <- dbConnect("PostgreSQL", user = "nathan", password="p4rk3r", db="biomass_pt")
grab <- dbSendQuery(con, "select city from all_biomass_SC group by city")
sites <- fetch(grab)
dbClearResult(grab)
sites <- sites[!sites=='city']

cost <- c(0,150)
biomass <- c(0,28)


for (city in sites) {
	pdf(paste(city,"SC.pdf", sep=" "))

	grab2 <- dbSendQuery(con, paste("select sum, cost from all_biomass_SC where city = '",city,"' and cost < 150 order by cost", sep=""))
	A <- fetch(grab2) 
	dbClearResult(grab2)

	plot(biomass, cost, type="n", ylab="Delivered Cost ($/BDT)",xlab="Biomass Available (million BDT)")
	title(paste(city, "Biomass Supply Curve"), font.main=1)	

	lines(A, col="black",lwd=2)
#	legend("bottomright",inset= 0.005, resources, col= ramp, lty = pen, ncol=2, cex=0.7, bty="n")
	
 	dev.off()}
dbDisconnect(con)

