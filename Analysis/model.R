#--------------------------------------------------------------------------
#Hypothesis: There is correlation for observations for the customers within same city
#Modelling: GLM vs GLMM (which assumes correlation for observations within city)
#Conclusion: GLMM is statistically more appropriate based on AIC score
#--------------------------------------------------------------------------
library(lme4)

#Form the cluster index: for each customer_city:customer_state
cluster = order %>% 
  group_by(customer_city, customer_state) %>%
  summarize(cluster = n())

cluster$cluster = seq(1, nrow(cluster))

tmp = order %>%
  left_join(cluster, by=c("customer_city", "customer_state"))

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

order_model = data.frame(
  size = standardize(tmp$size),
  order_products_value = standardize(tmp$order_products_value),
  order_freight_value = standardize(tmp$order_freight_value),
  distance = standardize(tmp$distance),
  cluster = as.factor(tmp$cluster),
  delivery_time = tmp$delivery_time
)

fit = glmer(delivery_time ~ size + order_products_value + order_freight_value +
              distance + (1 + distance | cluster), 
            data = order_model, family=Gamma(link="log"))

base = glm(delivery_time ~ size + order_products_value + order_freight_value + distance,
           data = order_model, family=Gamma(link="log"))

summary(fit)
summary(base)

#Insample score
#Naive estimate:
mean(abs(order_model$delivery_time - median(order_model$delivery_time)))
#Fitted result:
mean(abs(exp(predict(fit)) - order_model$delivery_time))

