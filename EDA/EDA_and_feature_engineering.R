library(dplyr)
library(readr)

#Load dataset
raw_geolocation = read_csv("../CleanedDataset/corrected_geolocation.csv")
raw_order = read_csv("../CleanedDataset/order.csv")
raw_product_measure = read_csv("../CleanedDataset/product_measure.csv")
raw_seller = read_csv("../CleanedDataset/seller.csv")

order = raw_order %>%
  select(order_id, product_id, order_products_value, order_freight_value, product_category_name, 
         customer_city, customer_state, customer_zip_code_prefix,
         order_purchase_timestamp, order_aproved_at, order_delivered_customer_date)

#Compute delivery time
order = order %>%
  mutate(delivery_time = as.numeric(order_delivered_customer_date - order_purchase_timestamp, units="days"),
         order_purchase_timestamp = NULL,
         order_aproved_at = NULL,
         order_delivered_customer_date = NULL) %>%
  filter(! is.na(delivery_time))

#Add product_size & weights
product = raw_product_measure %>%
  mutate(size = product_length_cm * product_height_cm * product_width_cm,
         weight = product_weight_g) %>%
  select(product_id, size, weight)

order = order %>% 
  left_join(product, by="product_id") %>%
  filter(! is.na(size)) %>%
  mutate(product_category_name = NULL)

#------------------------------------------------------------------------------------------------------
#Compute distance between seller and customer based on (zip_code, city)
#------------------------------------------------------------------------------------------------------
#Compute the geographical center of each (zip_code, city)
geolocation = raw_geolocation %>%
  group_by(zip_code_prefix, city) %>%
  summarize(lat = mean(lat),
            lng = mean(lng))

#Incorporate the location information
order = order %>%
  mutate(customer_city = tolower(customer_city),
         customer_zip_code_prefix = as.integer(customer_zip_code_prefix)) %>%
  left_join(geolocation %>%
              ungroup() %>%
              mutate(customer_city = tolower(city),
                     customer_zip_code_prefix = zip_code_prefix,
                     customer_lat = lat,
                     customer_lng = lng) %>%
              select(starts_with("customer")), by=c("customer_zip_code_prefix", "customer_city")) %>%
  filter(!is.na(customer_lat))

order = order %>%
  left_join(raw_seller, by=c("order_id", "product_id")) %>%
  mutate(seller_city = tolower(seller_city),
         seller_zip_code_prefix = as.integer(seller_zip_code_prefix)) %>%
  left_join(geolocation %>%
              ungroup() %>%
              mutate(seller_city = tolower(city),
                     seller_zip_code_prefix = zip_code_prefix,
                     seller_lat = lat,
                     seller_lng = lng) %>%
              select(starts_with("seller")), by=c("seller_zip_code_prefix", "seller_city")) %>%
  filter(!is.na(seller_lat))

#Convert location to distance on Earth; Using Spherical Law of Cosines to compute distance
distance <- function(lat1, lng1, lat2, lng2){
  R = 6371 #Radius of Earth in km
  dang = sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lng2 - lng1)
  return(R * acos(pmax(pmin(dang, 1), -1)))
}
ang2rad <- function(ang){
  return(ang * pi / 180)
}
order = order %>% 
  mutate(distance = distance(ang2rad(customer_lat), ang2rad(customer_lng),
                             ang2rad(seller_lat), ang2rad(seller_lng)),
         customer_lat = NULL,
         customer_lng = NULL,
         seller_lat = NULL,
         seller_lng = NULL)

#Add cluster label for each (customer_city, customer_state)
cluster = order %>% 
  group_by(customer_city, customer_state) %>%
  summarize(cluster = n())

cluster$cluster = seq(1, nrow(cluster))

order = order %>%
  left_join(cluster, by=c("customer_city", "customer_state"))

#EDA---------------------------------------------------------------------------------------
#Delivery time
summary(order$delivery_time)
hist(order$delivery_time, breaks=100)

#Distance
summary(order$distance)
hist(order$distance, breaks=100)

#Visualization on delivery time over different cities, jointly with the GDP figure of each city
raw_GDP_city = read_csv("../CleanedDataset/GDP_by_city_2010.csv")

#Preprocess the GDP_city table:
#Compute the geographical center of each (state, city)
geolocation = raw_geolocation %>%
  group_by(city, state) %>%
  summarize(lat = mean(lat),
            lng = mean(lng))

GDP_city = raw_GDP_city %>%
  mutate(city = tolower(city_by_data),
         state = tolower(state)) %>%
  filter(! is.na(city_by_data)) %>%
  select(city, state, GDP) %>%
  arrange(-GDP)

#Ordered by GDP level
GDP_city$rank = seq(1, nrow(GDP_city))

#Join the two table
GDP_city = GDP_city %>%
  left_join(geolocation, by=c("state", "city"))

#1. Delivery time distribution over the seller cities
library(plot3D)
colvar = order %>%
  mutate(city = tolower(seller_city),
         state = tolower(seller_state)) %>%
  group_by(city, state) %>%
  summarize(mean_delivery = mean(delivery_time)) %>%
  arrange(-mean_delivery) %>%
  left_join(geolocation, by=c("city", "state"))

summary(colvar$mean_delivery)

#remove the outlier, and to make a stronger color constrast over different region
colvar = colvar %>%
  filter(mean_delivery < 60)

scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
          pch = 19, cex = 0.5, main = "Geographical distribution and wealthy cities, on seller level",
          xlab = "lng", ylab = "lat")

#Constrast with the GDP level over cities
scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
          pch = 19, cex = 0.5, main = "Geographical distribution and wealthy cities, on seller level",
          xlab = "lng", ylab = "lat")
points(GDP_city$lng, GDP_city$lat, col='orange', pch = 18, cex = 40/(25+GDP_city$rank))

#2. Delivery time distribution over the customer cities
colvar = order %>%
  mutate(city = tolower(customer_city),
         state = tolower(customer_state)) %>%
  group_by(city, state) %>%
  summarize(mean_delivery = mean(delivery_time)) %>%
  arrange(-mean_delivery) %>%
  left_join(geolocation, by=c("city", "state"))

summary(colvar$mean_delivery)

#remove the outlier, and to make a stronger color constrast over different region
colvar = colvar %>%
  filter(mean_delivery < 90)

scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
          pch = 19, cex = 0.5, main = "Geographical distribution and wealthy cities, on customer level",
          xlab = "lng", ylab = "lat")

#Constrast with the GDP level over cities
scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
          pch = 19, cex = 0.5, main = "Geographical distribution and wealthy cities, on customer level",
          xlab = "lng", ylab = "lat")
points(GDP_city$lng, GDP_city$lat, col='orange', pch = 18, cex = 40/(25+GDP_city$rank))

#3. Delivery time distribution over the local region around the 3 major cities
center = geolocation %>%
  filter(city == "brasilia" & state == "df" |
           city == "sao paulo" & state == "sp" |
           city == "rio de janeiro" & state == "rj")

local = order %>%
  mutate(city = tolower(customer_city),
         state = tolower(customer_state)) %>%
  group_by(city, state) %>%
  summarize(mean_delivery = mean(delivery_time)) %>%
  arrange(-mean_delivery) %>%
  left_join(geolocation, by=c("city", "state")) %>%
  filter(lat <= -12, lat >= -28,
         lng <= -40, lng >= -52)

scatter2D(local$lng, local$lat, colvar = local$mean_delivery,
          pch = 19, cex = 0.5, main="Neighbourhood of three wealthy cities",
          xlab = "lng", ylab = "lat")
points(center$lng, center$lat, col='orange', pch = 18, cex = 2)

# Prepare the dataset for statistical modelling
dataset = order %>%
  select(size, order_products_value, order_freight_value, distance, cluster, customer_state, customer_city, delivery_time)

write_csv(dataset, "../StatisticalAnalysis/dataset.csv")
