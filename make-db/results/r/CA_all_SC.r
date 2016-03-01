library(RPostgreSQL)

con <- dbConnect("PostgreSQL", user = "nathan", password="p4rk3r", db="biomass_pt")
cost <- c(0,150)
biomass <- c(0,28)


	pdf("CA SC.pdf")

	grab2 <- dbSendQuery(con, "select sum, cost from CA_all_SC where cost <=150")
	A <- fetch(grab2) 
	dbClearResult(grab2)

	plot(A, type="l", col="black",lwd=2, ylab="Delivered Cost ($/BDT)",xlab="Biomass Available (million BDT)")
	title("California Biomass Supply Curve", font.main=1)	

#	legend("bottomright",inset= 0.005, resources, col= ramp, lty = pen, ncol=2, cex=0.7, bty="n")
	
 	dev.off()
dbDisconnect(con)

