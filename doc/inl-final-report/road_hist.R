I<-read.csv("farm_cost.csv",header=TRUE)
options(digits=1) 

out <- hist(I$total-I$"total_farmgate",plot=TRUE,main="Variable travel costs",xlab="Cost [$]")




