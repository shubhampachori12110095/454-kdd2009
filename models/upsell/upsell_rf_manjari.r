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


set.seed(512356)
train_colnames <- colnames(select(train,-churn, -upsell, -appetency))
upsell_rf_full_manjari <- randomForest(x=train[,train_colnames], y=factor(train$upsell) ,
                                     ntree = 50, nodesize = 10, importance = TRUE)
plot(upsell_rf_full_manjari)
upsell.varImp <- importance(upsell_rf_full_manjari)
#upsell.varImp
varImpPlot(upsell_rf_full_manjari, type=1)
# make predictions

upsell_rf_full_manjari_predictions <- predict(upsell_rf_full_manjari, newdata=test,s = 'lambda.min')
# Confusion Matrix
#Confusion Matrix
table(test$upsell, upsell_rf_full_manjari_predictions)
#Accuracy = 0.9392

#Creating Random forest with top 25 variables based on variable importance reduced accuracy of the
# model . So we will be using the full model itself.
set.seed(512356)
upsell.selVars <- names(sort(upsell.varImp[,1],decreasing=T))[1:25]

upsell_rf_top_25_manjari <- randomForest(x=train[,upsell.selVars], y=factor(train$upsell) ,
                                        ntree = 50, nodesize = 10, importance = TRUE)

# train predictions
upsell_rf_top_25_manjari_predictions_train <- predict(upsell_rf_top_25_manjari, newdata=train,s = 'lambda.min')
# Confusion Matrix
table(train$upsell, upsell_rf_top_25_manjari_predictions_train)
#Accuracy = 0.96498

# test predictions
upsell_rf_top_25_manjari_predictions <- predict(upsell_rf_top_25_manjari,
                                                newdata = test,
                                                type = 'prob')[,2]
# Confusion Matrix
table(test$upsell, upsell_rf_top_25_manjari_predictions)
#Accuracy = 0.95136

#upsell.selVars <- names(sort(upsell.varImp[,1],decreasing=T))[1:50]
#upsell_rf_top_50_manjari <- randomForest(x=train[,upsell.selVars], y=factor(train$upsell) ,
#                                         ntree = 10, nodesize = 10, importance = TRUE)
# AUC
#upsell_rf_top_50_manjari_predictions <- predict(upsell_rf_top_50_manjari, newdata=test,s = 'lambda.min')
# Confusion Matri#Confusion Matrix
#table(test$upsell, upsell_rf_top_50_manjari_predictions)
#Accuracy = 0.95144

### Determining AUC in train data set

library('ROCR')

PredTrain = predict(upsell_rf_top_25_manjari,newdata=train, type="prob")[, 2]

ROCR = prediction(PredTrain, train$upsell)
#performance in terms of true and false positive rates
d.rf.perf = performance(ROCR,"tpr","fpr")

#plot the curve
plot(d.rf.perf,main="ROC Curve for Random Forest",col=2,lwd=2)
abline(a=0,b=1,lwd=2,lty=2,col="gray")

as.numeric(performance(ROCR , "auc")@y.values)
# AUC = 0.9951623

### Determining AUC in test data set

PredTrain_test = predict(upsell_rf_top_25_manjari,newdata=test, type="prob")[, 2]

ROCR = prediction(PredTrain_test, test$upsell)
#performance in terms of true and false positive rates
d.rf.perf = performance(ROCR,"tpr","fpr")

#plot the curve
plot(d.rf.perf,main="ROC Curve for Random Forest Upsell in test",col=2,lwd=2)
abline(a=0,b=1,lwd=2,lty=2,col="gray")

as.numeric(performance(ROCR , "auc")@y.values)
# AUC = 0.8334478

# Choosing the model with top 25 variables as the accuracy of this model is almost same as that of 50 vars. Reduced model is simpler.
upsell_rf_manjari <- upsell_rf_top_25_manjari
upsell_rf_manjari_predictions <- upsell_rf_top_25_manjari_predictions

# save the output
save(list = c('upsell_rf_manjari', 'upsell_rf_manjari_predictions'),
     file = 'models/upsell/upsell_rf_manjari.RData')
