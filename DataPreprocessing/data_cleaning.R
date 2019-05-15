library(dplyr)
library(readr)

setwd("C:/Users/s1155063404/Desktop/Projects/brazilian-ecommerce-dataset/DataPreprocessing")

raw_geolocation = read_csv("../RawDataset/geolocation_olist_public_dataset.csv")

#Remove the simulated points that are outside of the Brazil boundary
geolocation = raw_geolocation %>%
  filter(lat <= 5.27438888, lat >= -33.75116944, lng >= -73.98283055, lng <= -34.79314722)

#We want to use the centroid of the simulated samples to estimate the location of a city, however, it gives a volatile estimate
tmp = geolocation %>%
  group_by(state, city) %>%
  summarize(var_lat = var(lat),
            var_lng = var(lng),
            lat = mean(lat),
            lng = mean(lng)) %>%
  arrange(-var_lng, -var_lat) %>%
  filter (var_lng > 0.5, var_lat > 0.5)

#The reason is probably due to some problematic data input, which should be corrected / removed.
geolocation %>%
  filter(state == "rj", city == "santa maria")

geolocation %>%
  filter(lat >= -22.7, lat <= 42.4, lng >= -43.4, lng <= 13.8)

geolocation %>%
  filter(state == "sp", city == "ibitiuva")

geolocation %>%
  filter(lat >= -21.0, lat <= -12.6, lng >= -48.3, lng <= -38.7)

#The mistaked input are removed by cross-checking with the actual location of each city from some online sources.
#The following is the corrected result
corrected_geolocation = read_csv("../CleanedDataset/corrected_geolocation.csv")

corrected_geolocation %>%
  group_by(state, city) %>%
  summarize(var_lat = var(lat),
            var_lng = var(lng),
            lat = mean(lat),
            lng = mean(lng)) %>%
  arrange(-var_lng, -var_lat) %>%
  filter (var_lng > 0.5, var_lat > 0.5)
