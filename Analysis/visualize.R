library(plot3D)

# raw_GDP_state = read_csv("./CleanedDataset/GDP_by_state_2015.csv")
raw_GDP_city = read_csv("./CleanedDataset/GDP_by_city_2010.csv")

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

GDP_city$rank = seq(1, nrow(GDP_city)) #Ordered by GDP level

GDP_city = GDP_city %>%
  left_join(geolocation, by=c("state", "city"))

# GDP_state = raw_GDP_state %>%
#   mutate(state = tolower(Abbreviation),
#          city = tolower(Capital_in_data)) %>%
#   select(city, state, GDP_per_capita) %>%
#   arrange(-GDP_per_capita)
# 
# GDP_state$rank = seq(1, nrow(GDP_state))
# 
# GDP_state = GDP_state %>%
#   left_join(geolocation, by=c("state", "city"))

#Visualization----------------------------------------------------------------------------
#Seller_level
# geolocation = raw_geolocation %>%
#   group_by(state) %>%
#   summarize(lat = mean(lat),
#             lng = mean(lng))
# 
# colvar = colvar %>% left_join(geolocation, by=c("state"))
# 
# colvar = order %>%
#   mutate(state = tolower(seller_state)) %>%
#   group_by(state) %>%
#   summarize(mean_delivery = mean(delivery_time)) %>%
#   arrange(-mean_delivery)
# 
# scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
#           pch = 19, cex = 0.5)

#Buyer_level
colvar = order %>%
  mutate(city = tolower(customer_city),
         state = tolower(customer_state)) %>%
  group_by(city, state) %>%
  summarize(mean_delivery = mean(delivery_time)) %>%
  arrange(-mean_delivery) %>%
  left_join(geolocation, by=c("city", "state")) %>%
  filter(mean_delivery < 90)

scatter2D(colvar$lng, colvar$lat, colvar=colvar$mean_delivery,
          pch = 19, cex = 0.5, main = "Geographical distribution and wealthy cities",
          xlab = "lng", ylab = "lat")
points(GDP_city$lng, GDP_city$lat, pch = 18, cex = 40/(25+GDP_city$rank))


#Buyer level: locality: distance against major cities
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
points(center$lng, center$lat, pch = 18, cex = 2)


