library(hydroGOF)
library(MESS)

#read input args and assign them to variables
args <- commandArgs(trailingOnly = TRUE)
ground_truth<-read.table(args[1], header=T)
salmon<-read.table(args[2], header=T)
cell_number<-args[3]
read_coverage<-args[4]
simulation_num<-args[5]
cell_of_total<-args[6]

#order rows and columns in ground_truth and salmon
ground_truth<-ground_truth[order(rownames(ground_truth)), , drop=FALSE]

salmon<-salmon[order(rownames(salmon)), , drop=FALSE]

#Function which returns the mean value of spearmans
correlation<-function(x,y){
  return(mean(cor(y,x,method="spearman")))
}

#Function which returns the mean NRMSE
NRMSE<-function(ground_truth, salmon){
  return(nrmse(log2(salmon+1), log2(ground_truth+1)))
}

MSE_log<-function(ground_truth, salmon){
  return(mse(log2(salmon+1),log2(ground_truth+1)))
}

MSE<-function(ground_truth, salmon) {
  return(mse(salmon,ground_truth))
}

#function to return a confusion matrix
make_confusion<-function(ground_truth, tool_estimates, threshold_unexpr){
  TP<-length(ground_truth[ground_truth>threshold_unexpr & tool_estimates>threshold_unexpr])
  FP<-length(ground_truth[ground_truth<=threshold_unexpr & tool_estimates>threshold_unexpr])
  TN<-length(ground_truth[ground_truth<=threshold_unexpr & tool_estimates<=threshold_unexpr])
  FN<-length(ground_truth[ground_truth>threshold_unexpr & tool_estimates<=threshold_unexpr])
  return(c(TP,FP,TN,FN))
}

all_iso_confusion<-make_confusion(ground_truth,salmon,0)

#To do: So far these are producing stats for ROC based on value threshold of 'not expressed' - need to produce stats for ROC based on drop-outs. Function?

threshold<-seq(0,10,0.1)
library(plyr)
TPR<-vector()
FPR<-vector()

for (i in 1:101){
  new_list<-list()
  new_list<-make_confusion(ground_truth, salmon, threshold[i])
  TPR[i]<-new_list[1] / (new_list[1] + new_list[4])
  FPR[i]<-new_list[2] / (new_list[2] + new_list[3])
}

#remove NA and NaN values from TPR and FPR as these mess up auc.
NaN_TPR<-is.nan(TPR)
na_TPR<-is.na(TPR)
NaN_FPR<-is.nan(FPR)
na_FPR<-is.na(FPR)

FPR<-FPR[!NaN_TPR & !NaN_FPR & !na_TPR & !na_FPR]
TPR<-TPR[!NaN_TPR & !NaN_FPR & !na_TPR & !na_FPR]

#Calculate area and pAUROC
area<-auc(FPR,TPR,from=min(FPR), to=max(FPR))
pAUROC<-(area/(max(FPR)-min(FPR))*100)


output<-cbind(cell_number, read_coverage, simulation_num, cell_of_total, correlation(ground_truth, salmon), NRMSE(ground_truth,salmon), MSE(ground_truth, salmon), MSE_log(ground_truth, salmon), all_iso_confusion[1], all_iso_confusion[2], all_iso_confusion[3], all_iso_confusion[4],pAUROC)
filename<-paste("coverage",cell_number, read_coverage, simulation_num, cell_of_total, sep="_")
write.table(output, file=filename)
