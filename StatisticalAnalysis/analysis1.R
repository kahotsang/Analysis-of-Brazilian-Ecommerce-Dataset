#--------------------------------------------------------------------------
#Hypothesis: There is correlation for delivery time of the customers within same city
#Modeling: GLM vs GLMM (which assumes correlation for observations within city)
#Conclusion: GLMM is statistically more appropriate based on AIC score, which support my Hypothesis
#--------------------------------------------------------------------------
library(lme4)
library(readr)

setwd("C:/Users/s1155063404/Desktop/Projects/brazilian-ecommerce-dataset/StatisticalAnalysis")

dataset = read_csv("./dataset.csv")

#Standardize the observations for modeling
standardize <- function(x){
  mean_x = mean(x)
  sig_x = sqrt(var(x))
  if (sig_x > 0){
    return((x - mean_x) / sig_x)
  }
  else {
    return(x)
  }
}

dataset$size = standardize(dataset$size)
dataset$order_products_value = standardize(dataset$order_products_value)
dataset$order_freight_value = standardize(dataset$order_freight_value)
dataset$distance = standardize(dataset$distance)

#GLMM
fit = glmer(delivery_time ~ size + order_products_value + order_freight_value +
              distance + (1 + distance | cluster), 
            data = dataset, family=Gamma(link="log"))
summary(fit)

#GLM
base = glm(delivery_time ~ size + order_products_value + order_freight_value + distance,
           data = dataset, family=Gamma(link="log"))

summary(base)

#Insample score, as a naive measure of how the fitting performance is
#Naive estimate:
mean(abs(dataset$delivery_time - median(dataset$delivery_time)))
#Fitted result:
mean(abs(exp(predict(fit)) - dataset$delivery_time))