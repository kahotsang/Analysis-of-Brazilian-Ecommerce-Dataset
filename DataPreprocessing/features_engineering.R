library(dplyr)
library(plot3D)
library(readr)

setwd("C:/Users/s1155063404/Desktop/Projects/brazilian-ecommerce-dataset/DataPreprocessing")

#Load dataset
raw_geolocation = read_csv("../CleanedDataset/corrected_geolocation.csv")
raw_order = read_csv("../CleanedDataset/order.csv")
raw_product_measure = read_csv("../CleanedDataset/product_measure.csv")
raw_seller = read_csv("../CleanedDataset/seller.csv")

order = raw_order %>%
  select(order_id, product_id, order_products_value, order_freight_value, product_category_name, 
         customer_city, customer_state, customer_zip_code_prefix,
         order_purchase_timestamp, order_aproved_at, order_delivered_customer_date)

#Convert the raw data into useful features:
#Delivery time
order = order %>%
  mutate(delivery_time = as.numeric(order_delivered_customer_date - order_purchase_timestamp, units="days"),
         order_purchase_timestamp = NULL,
         order_aproved_at = NULL,
         order_delivered_customer_date = NULL) %>%
  filter(! is.na(delivery_time))

#product_size & weights
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

#Convert location to distance on Earth
#Using Spherical Law of Cosines to compute distance
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

