# this model is a regularized logisitc regression model to predict upsell
# the regularization parameter is selected automatically using cross validation

library(glmnet)
library(ROCR)

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

# squared numeric variables
new_names <- paste(colnames(select(df, 1:174)), '_squared', sep ='')
df2 <- select(df, 1:174)**2
colnames(df2) <- new_names

df <- cbind(df,df2)

# make some interaction varaibles
df$Var126_28 <- df$Var126 * df$Var28
df$Var28_153 <- df$Var28 * df$Var153
df$Var125_81 <- df$Var125 * df$Var81
# create a matrix
df_mat <- make_mat(df)

upsell_lreg_jay <- cv.glmnet(df_mat[train_ind,],
                           factor(train$upsell), family = "binomial",
                           nfolds = 4, type.measure = 'auc')

# coef.glmnet(upsell_lreg_jay, s ='lambda.min')

plot(upsell_lreg_jay)

# make predictions
upsell_lreg_jay_predictions <- predict(upsell_lreg_jay, df_mat[test_ind,],
                                      type = 'response', s = 'lambda.min')[,1]

upsell_ens_lreg_jay_predictions <- predict(upsell_lreg_jay, df_mat[ens_ind,],
                                       type = 'response', s = 'lambda.min')[,1]

pred <- prediction(upsell_lreg_jay_predictions, test$upsell)
perf <- performance(pred,'auc')
perf@y.values

# save the output
save(list = c('upsell_lreg_jay', 'upsell_lreg_jay_predictions',
              'upsell_ens_lreg_jay_predictions'),
     file = 'models/upsell/upsell_lreg_jay.RData')

