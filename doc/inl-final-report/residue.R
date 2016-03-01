I<-read.table("residue.dat",header=TRUE)
options(digits=1) 

out <- hist(I$residue,plot=TRUE,main='',xlab="required residue tons / acre")




