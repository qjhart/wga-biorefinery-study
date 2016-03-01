library(RPostgreSQL)

con <- dbConnect("PostgreSQL", user = "nathan", password="p4rk3r", db="biomass_pt")
cost <- c(0,150)
biomass <- c(0,28)


	pdf("CA EISA comparison.pdf")

	grab2 <- dbSendQuery(con, "select sum, cost from CA_all_SC where cost <=150")
	A <- fetch(grab2) 
	dbClearResult(grab2)

	plot(A, type="l", col="black",lwd=2, ylab="Delivered Cost ($/BDT)",xlab="Biomass Available (million BDT)")
	title("Change in California's Biomass Supply under EISA 2007 Constraints", font.main=1)	
	
	grab <- dbSendQuery(con, "select sum, cost from CA_all_SC_EISA where cost <=150")
	A <- fetch(grab)
	dbClearResult(grab)

	lines(A, col="black", lwd=2, lty=4)

	legend("bottomright",inset= 0.005, c("baseline","EISA constrained"), col= c("black","black"), lty = c(1,4), bty="n")
	
 	dev.off()
dbDisconnect(con)

