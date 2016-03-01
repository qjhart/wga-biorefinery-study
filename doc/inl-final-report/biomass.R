I<-read.table("biomass.dat",header=TRUE)
options(digits=1) 

out <- hist(I$"actual_nonirr_biomass",plot=TRUE,main='',xlab="biomass amounts [bdt/acre]")




