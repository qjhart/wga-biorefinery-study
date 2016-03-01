I<-read.table("residue-all.dat",header=TRUE)
options(digits=1) 

out <- hist(I$residue,plot=TRUE,main='All pseudo farms',xlab="required residue tons / acre")




