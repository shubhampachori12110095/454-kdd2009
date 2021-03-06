# this model is a random forest model to predict churn

library(randomForest)
library(dplyr)

dirs <- c('c:/Users/jay/Dropbox/pred_454_team',
          'c:/Users/uduak/Dropbox/pred_454_team',
          'C:/Users/Sandra/Dropbox/pred_454_team',
          '~/Manjari/Northwestern/R/Workspace/Predict454/KDDCup2009/Dropbox',
          'C:/Users/JoeD/Dropbox/pred_454_team'
          )

for (d in dirs){
  if(dir.exists(d)){
    setwd(d)
  }
}


# choose a script to load and transform the data
source('data_transformations/impute_0.r')

# the data needs to be in matrix form, so I'm using make_mat()
# from kdd_tools.r
source('kdd_tools.r')
df_mat <- make_mat(df)

# Model 1 : with all variables , ntree= 50 , nodesize=10, samplesize =(10,30).
#Samplesize helps in controlling the sselection of observations at each node , it will be 10 from appetency =0 and 30 from appetency=1
#with replacement
set.seed(512356)
train_colnames <- colnames(select(train,-churn, -upsell, -appetency))
appetency_rf_full_manjari <- randomForest(x=train[,train_colnames], y=factor(train$appetency) ,
                                     ntree = 50, nodesize = 10, importance = TRUE, samplesize= c(10,30))
plot(appetency_rf_full_manjari)
appetency.varImp <- importance(appetency_rf_full_manjari)
#appetency.varImp
varImpPlot(appetency_rf_full_manjari, type=1)
# make predictions

appetency_rf_full_manjari_predictions <- predict(appetency_rf_full_manjari, newdata=test,s = 'lambda.min')
# Confusion Matrix
#Confusion Matrix
table(test$appetency, appetency_rf_full_manjari_predictions)
#Accuracy = 0.9816 , The full model did not catch any of the appetency cases in test.

#Model 2: Creating Random forest with top 50 variables based on variable importance
appetency.selVars <- names(sort(appetency.varImp[,1],decreasing=T))[1:50]

appetency_rf_top_50_manjari <- randomForest(x=train[,appetency.selVars], y=factor(train$appetency) ,
                                        ntree = 50, nodesize =2, importance = TRUE, samplesize= c(10,30))

appetency_rf_top_50_manjari_predictions_train <-  predict(appetency_rf_top_50_manjari,
                                                          newdata = train,
                                                          type = 'prob')[,2]
# Confusion Matri#Confusion Matrix
table(train$appetency, appetency_rf_top_50_manjari_predictions_train)

appetency_rf_top_50_manjari_predictions <-  predict(appetency_rf_top_50_manjari,
                                                    newdata = test,
                                                    type = 'prob')[,2]
# Confusion Matri#Confusion Matrix
table(test$appetency, appetency_rf_top_50_manjari_predictions)
#Accuracy = 0.9816 , The model did not catch any of the appetency cases

### Determining AUC in train data set

library('ROCR')

PredTrain = predict(appetency_rf_top_50_manjari,newdata=train, type="prob")[, 2]

ROCR = prediction(PredTrain, train$appetency)
#performance in terms of true and false positive rates
d.rf.perf = performance(ROCR,"tpr","fpr")

#plot the curve
plot(d.rf.perf,main="ROC Curve for Random Forest for Appetency in train",col=2,lwd=2)
abline(a=0,b=1,lwd=2,lty=2,col="gray")

as.numeric(performance(ROCR , "auc")@y.values)
# AUC = 0.9997

### Determining AUC in test data set

PredTrain_test = predict(appetency_rf_top_50_manjari ,newdata=test, type="prob")[, 2]

ROCR = prediction(PredTrain_test, test$appetency)
#performance in terms of true and false positive rates
d.rf.perf = performance(ROCR,"tpr","fpr")

#plot the curve
plot(d.rf.perf,main="ROC Curve for Random Forest Appetency in test data",col=2,lwd=2)
abline(a=0,b=1,lwd=2,lty=2,col="gray")

as.numeric(performance(ROCR , "auc")@y.values)
# AUC = 0.6262

## Using the reduced model as it shows the same accuracy as full model
appetency_rf_manjari <- appetency_rf_top_50_manjari
appetency_rf_manjari_predictions <- appetency_rf_top_50_manjari_predictions

# save the output
save(list = c('appetency_rf_manjari', 'appetency_rf_manjari_predictions'),
     file = 'models/appetency/appetency_rf_manjari.RData')
