library(R2WinBUGS)

#Scaling
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
min_max <- function(x){
  min = min(x)
  max = max(x)
  if (max > min){
    return((x-min)/(max-min))
  }
  else{
    return(x)
  }
}

#Form the cluster index: for each customer_city:customer_state
cluster = order %>% 
  group_by(customer_city, customer_state) %>%
  summarize(cluster = n())

cluster$cluster = seq(1, nrow(cluster))

tmp = order %>%
  left_join(cluster, by=c("customer_city", "customer_state"))

#Standardize the observations for modeling; Also used for Bayesian analysis
order_model = data.frame(
  size = standardize(tmp$size),
  order_products_value = standardize(tmp$order_products_value),
  order_freight_value = standardize(tmp$order_freight_value),
  distance = standardize(tmp$distance),
  cluster = tmp$cluster,
  delivery_time = tmp$delivery_time
)

#Generate data for model: base
K = nrow(order)
n_clust = nrow(cluster)
Y = order_model$delivery_time
X = as.matrix(order_model[,c(1,2,3)])
Z = order_model$distance
i = order_model$cluster

mu_b = rep(0, 3)
tau_b = diag(rep(0.0001, 3))

data = list(K=K, n_clust=n_clust, Y=Y, X=X, Z=Z, mu_b=mu_b, tau_b=tau_b, i=i)
bugs.data(data, dir="./model/", data.file = "data_base.txt")

init = list(beta=rep(0,3), m1=0, m2=0, tau_a=10, tau_u=10, b=0.5)
para = c("m1", "beta", "m2", "sig_u", "sig_a", "b")

sim = bugs(data="data_base.txt", inits=list(init),
           parameters.to.save=para,
           model.file="base.txt",
           n.chains=1, n.iter=800,
           bugs.directory="C:/Users/Ka Ho/Desktop/WinBUGS14/",
           working.directory="./model/")

#Proposed model:---------------------------------------------------------------------
#GDP_rank for each state
GDP_state = raw_GDP_state %>%
  mutate(customer_state = Abbreviation) %>%
  select(customer_state, GDP_per_capita) %>%
  arrange(-GDP_per_capita)
GDP_state$rank = 1:nrow(GDP_state)

#geolocation of each city, state
geolocation = raw_geolocation %>%
  group_by(city, state) %>%
  summarize(lat = mean(lat),
            lng = mean(lng)) %>%
  ungroup() %>%
  mutate(customer_city = city,
         customer_state = toupper(state))

#Compute distance to closest wealthy cities (Sao paulo, Rio de Janeiro, brasilia)
#location of each wealthy cities
location = raw_geolocation %>%
  group_by(city, state) %>%
  filter(city == "brasilia" & state == "df" |
           city == "sao paulo" & state == "sp" |
           city == "rio de janeiro" & state == "rj") %>%
  summarize(lat = mean(lat),
            lng = mean(lng))

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

#Compute distance to capital
#location of each capital
location_capital = raw_GDP_state %>%
  mutate(state = tolower(Abbreviation),
         city = tolower(Capital_in_data)) %>%
  select(city, state) %>%
  left_join(geolocation %>%
              select(state, city, lat, lng), by=c("state", "city")) %>%
  mutate(capital_lat = lat,
         capital_lng = lng) %>%
  select(state, capital_lat, capital_lng)

geolocation = geolocation %>%
  left_join(location_capital, by="state") %>%
  mutate(distance2capital = distance(ang2rad(lat), ang2rad(lng),
                                     ang2rad(capital_lat), ang2rad(capital_lng)))

#Form the cluster index: for each customer_city:customer_state;
#Work on the cluster_level:
cluster = order %>%
  group_by(customer_city, customer_state) %>%
  summarize(cluster = n()) %>%
  left_join(GDP_state, by=c("customer_state")) %>%
  left_join(geolocation %>% 
              select(customer_city, customer_state, lat, distance2wealthy, distance2capital),
            by=c("customer_city", "customer_state"))
  
cluster$cluster = seq(1, nrow(cluster))

tmp = order %>%
  left_join(cluster %>%
              select(customer_city, customer_state, cluster), by=c("customer_city", "customer_state"))

order_model = data.frame(
  size = standardize(tmp$size),
  order_products_value = standardize(tmp$order_products_value),
  order_freight_value = standardize(tmp$order_freight_value),
  distance = standardize(tmp$distance),
  cluster = tmp$cluster,
  delivery_time = tmp$delivery_time,
  state = as.numeric(as.factor(tmp$customer_state))
)

#Generate data for model: proposed
K = nrow(order)
n_clust = nrow(cluster)
Y = order_model$delivery_time
X = as.matrix(order_model[,c(1,2,3)])
Z = order_model$distance
i = order_model$cluster

#Cluster_level: standardization
W1 = standardize(cluster$rank)
W2 = standardize(cluster$lat)
W3 = standardize(cluster$distance2wealthy)
#W4 = standardize(cluster$distance2capital)

mu_b = rep(0, 3)
tau_b = diag(rep(0.0001, 3))
mu_nu = rep(0, 4)
tau_nu = diag(rep(0.0001, 4))

# data = list(K=K, n_clust=n_clust, Y=Y, X=X, Z=Z, mu_b=mu_b, tau_b=tau_b, mu_nu=mu_nu, tau_nu=tau_nu,
#             i=i, W1=W1, W2=W2, W3=W3, W4=W4)
data = list(K=K, n_clust=n_clust, Y=Y, X=X, Z=Z, mu_b=mu_b, tau_b=tau_b, mu_nu=mu_nu, tau_nu=tau_nu,
            i=i, W1=W1, W2=W2, W3=W3)
bugs.data(data, dir="./model/", data.file = "data1.txt")

init = list(beta=rep(0,3), nu1=rep(0,4), nu2=rep(0,4), tau_a=10, tau_u=10, b=0.5)
para = c("beta", "nu1", "nu2", "sig_u", "sig_a", "b")

sim = bugs(data="data1.txt", inits=list(init),
           parameters.to.save=para,
           model.file="model3.txt",
           n.chains=1, n.iter=1000,
           bugs.directory="C:/Users/s1155063404/Downloads/WinBUGS14/",
           working.directory="C:/Users/s1155063404/Desktop/STAT 5060/Final Project/model/")
save(sim, file="./sim_model3.RData")

