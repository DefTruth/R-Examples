#' Prediction of Testing Samples for single tree
#' 
#' Predicts the output responses of testing samples based on the input regression tree
#'  
#' @param Single_Model Random Forest or Multivariate Random Forest Model of a particular tree
#' @param X_test Testing samples of size Q x N, Q is the number of testing samples and N is the number of features(same order and
#' size used as training) 
#' @param Variable_number Number of Output Features 
#' @return Prediction result of the Testing samples for a particular tree
#' @details 
#' A regression tree model contains splitting criteria for all the splits in the tree and output responses of training 
#' samples in the leaf nodes. A testing sample using these criteria will reach a leaf node and the average of the 
#' Output response vectors in the leaf node is considered as the prediction of the testing sample.
#' @export
single_tree_prediction <- function(Single_Model,X_test,Variable_number){
  
  
  Y_pred=matrix(  0*(1:nrow(X_test)*Variable_number)  ,nrow=nrow(X_test),  ncol=Variable_number)
  
  for (k in 1:nrow(X_test)){
    xt=X_test[k, ]
    i=1
    Y_pred[k,]=predicting(Single_Model,i,xt,Variable_number)
    
  }
  #Y_pred1=unlist(Y_pred, recursive = TRUE)
  #Y_pred1=matrix(Y_pred1,nrow=nrow(X_test))
  return(Y_pred)
}