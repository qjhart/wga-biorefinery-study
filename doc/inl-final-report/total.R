I<-read.csv("farm_cost.csv",header=TRUE)
options(digits=1) 

out <- hist(I$total,plot=TRUE,main="Total cost variability",xlab="Cost [$]")




