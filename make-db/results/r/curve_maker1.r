library(RPostgreSQL)

con <- dbConnect("PostgreSQL", user = "nathan", password="p4rk3r", db="biomass_pt")
grab <- dbSendQuery(con, "select city from supply_curve group by city")
sites <- fetch(grab)
dbClearResult(grab)
sites <- sites[!sites=='city']

grab <- dbSendQuery(con, "select resource_type from supply_curve group by resource_type order by resource_type")
resources <- fetch(grab)
dbClearResult(grab)
resources <- resources[!resources=='resource_type']

cost <- c(0,150)
biomass <- c(0,9)

ramp <- c("hotpink","palegreen2","mediumblue","grey17","red1","grey17","grey17","red1","red1","palegreen2","mediumblue","mediumblue","hotpink","palegreen2")
pen <- c(1,1,1,1,1,2,4,2,4,2,2,4,2,4)

for (city in sites) {
	pdf(paste(city,"SupplyCurve.pdf", sep=""))
	plot(biomass,cost, type="n", ylab="Delivered Cost ($/BDT)",xlab="Biomass Available (million BDT)")
	title(paste(city, "Biomass Supply Curve"), font.main=1)	
	iter <- 1
	
	for (type in resources) {
	grab2 <- dbSendQuery(con, paste("select sum, cost from supply_curve where city = '",city,"' and resource_type = '", type,"' order by cost", sep=""))
	A <- fetch(grab2) 
	dbClearResult(grab2)

	lines(A, col=ramp[iter], lty=pen[iter], lwd=1.5)

	iter <- iter + 1
}

	legend("bottomright",inset= 0.005, resources, col= ramp, lty = pen, ncol=2, cex=0.7, bty="n")
	
 	dev.off()}
dbDisconnect(con)

