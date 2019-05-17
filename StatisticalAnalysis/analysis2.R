#-----------------------------------------------------------------------------
#Objective: To analyze the second-level effect, on how the location of customer city affects the delivery time
#Modelling: GLMM
#This model performs the best when compared with the model in analysis1,
#which supports my observation that the location of customer city affects delivery time
#-----------------------------------------------------------------------------
library(R2WinBUGS)
library(dplyr)
library(readr)

#The directory of the WinBUGS
WinBUGS_path = "C:/Users/Ka Ho/Desktop/WinBUGS14/"

#Working directory
working_dir = "C:/Users/Ka Ho/Desktop/Projects/Analysis-of-Brazilian-Ecommerce-Dataset/StatisticalAnalysis"

setwd(working_dir)
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

#Base model: Prepare the data, initial parameter for WinBUGS
K = nrow(dataset)
n_clust = length(unique(dataset$cluster))
Y = dataset$delivery_time
X = cbind(dataset$size, dataset$order_products_value, dataset$order_freight_value)
Z = dataset$distance
i = dataset$cluster

mu_b = rep(0, 3)
tau_b = diag(rep(0.0001, 3))

data = list(K=K, n_clust=n_clust, Y=Y, X=X, Z=Z, mu_b=mu_b, tau_b=tau_b, i=i)
bugs.data(data, dir="../WinBUGS_code/", data.file = "data_base.txt")

init = list(beta=rep(0,3), m1=0, m2=0, tau_a=10, tau_u=10, b=0.5)
para = c("m1", "beta", "m2", "sig_u", "sig_a", "b")

#Run WinBUGS for Bayesian Inference
sim = bugs(data="data_base.txt", inits=list(init),
           parameters.to.save=para,
           model.file="base.txt",
           n.chains=1, n.iter=1000,
           bugs.directory = WinBUGS_path,
           working.directory="../WinBUGS_code/")

#Create features for explaining the second-level effect:
#Return the cluster label for each (state, city); Create the second-level features in this table.
cluster = dataset %>%
  group_by(customer_state, customer_city, cluster) %>%
  summarize(n = n()) %>%
  arrange(cluster)

#1. GDP rank of each underlying state
raw_GDP_state = read_csv("../CleanedDataset/GDP_by_state_2015.csv")

GDP_state = raw_GDP_state %>%
  mutate(customer_state = Abbreviation) %>%
  select(customer_state, GDP_per_capita) %>%
  arrange(-GDP_per_capita)
GDP_state$rank = 1:nrow(GDP_state)

cluster = cluster %>%
  left_join(GDP_state, by="customer_state")

#2. Geolocation features
raw_geolocation = read_csv("../CleanedDataset/corrected_geolocation.csv")

#geolocation of each city, state
geolocation = raw_geolocation %>%
  group_by(city, state) %>%
  summarize(lat = mean(lat),
            lng = mean(lng)) %>%
  ungroup() %>%
  mutate(customer_city = city,
         customer_state = toupper(state))

#Compute the distance to closest 3 wealthy cities
distance <- function(lat1, lng1, lat2, lng2){
  R = 6371 #Radius of Earth in km
  dang = sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lng2 - lng1)
  return(R * acos(pmax(pmin(dang, 1), -1)))
}
ang2rad <- function(ang){
  return(ang * pi / 180)
}

#Location of the 3 wealthy cities
location = geolocation %>%
  filter(city == "brasilia" & state == "df" |
           city == "sao paulo" & state == "sp" |
           city == "rio de janeiro" & state == "rj")

geolocation = geolocation %>%
  mutate(distance1 = distance(ang2rad(lat), ang2rad(lng),
                              ang2rad(as.numeric(location[1,3])), ang2rad(as.numeric(location[1,4]))),
         distance2 = distance(ang2rad(lat), ang2rad(lng),
                              ang2rad(as.numeric(location[2,3])), ang2rad(as.numeric(location[2,4]))),
         distance3 = distance(ang2rad(lat), ang2rad(lng),
                              ang2rad(as.numeric(location[3,3])), ang2rad(as.numeric(location[3,4])))) %>%
  mutate(distance2wealthy = pmin(distance1, distance2, distance3),
         distance1 = NULL,
         distance2 = NULL,
         distance3 = NULL)

#Add the geolocation features to the cluster table
cluster = cluster %>%
  left_join(geolocation %>%
              select(customer_state, customer_city, distance2wealthy, lat), by=c("customer_state", "customer_city"))

#Generate data for model: proposed
K = nrow(dataset)
n_clust = nrow(cluster)
Y = dataset$delivery_time
X = cbind(dataset$size, dataset$order_products_value, dataset$order_freight_value)
Z = dataset$distance
i = dataset$cluster

#Cluster_level features
W1 = standardize(cluster$rank)
W2 = standardize(cluster$lat)
W3 = standardize(cluster$distance2wealthy)

mu_b = rep(0, 3)
tau_b = diag(rep(0.0001, 3))
mu_nu = rep(0, 4)
tau_nu = diag(rep(0.0001, 4))

data = list(K=K, n_clust=n_clust, Y=Y, X=X, Z=Z, mu_b=mu_b, tau_b=tau_b, mu_nu=mu_nu, tau_nu=tau_nu,
            i=i, W1=W1, W2=W2, W3=W3)
bugs.data(data, dir="../WinBUGS_code/", data.file = "data.txt")

init = list(beta=rep(0,3), nu1=rep(0,4), nu2=rep(0,4), tau_a=10, tau_u=10, b=0.5)
para = c("beta", "nu1", "nu2", "sig_u", "sig_a", "b")

sim = bugs(data="data.txt", inits=list(init),
           parameters.to.save=para,
           model.file="model.txt",
           n.chains=1, n.iter=1000,
           bugs.directory=WinBUGS_path,
           working.directory="../WinBUGS_code/")
