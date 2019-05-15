# Analysis-of-Brazilian-Ecommerce-Dataset
This project is based on the dataset which was provided by Olist and was released by Kaggle. Olist is the largest department store in Brazilian marketplaces. This dataset contains information of 100k orders made at Olist from 2016 to 2018. Please refer to [here](https://www.kaggle.com/olistbr/brazilian-ecommerce) for the details of the original dataset. There could be lots of possible work from this dataset, including sales forecasting, customer review analysis, delivery time analysis, etc. The objective of this project is to analyze the delivery time of each order, using visualization and some statistical techniques (particularly regression analysis).

## Description of Dataset
The RawDataset contained in this project was adopted from the [original dataset](https://www.kaggle.com/olistbr/brazilian-ecommerce) downloadable from Kaggle. Since this project only aims to analyze the delivery time, I only include the relevant tables in the RawDataset. The following shows some brief information about each included table:
* olist_public_dataset_v2: contains the order information
* geolocation_olist_public_dataset: contains the geolocation information of each Brazilian city. Particularly, each rows represents a simulated location together with the corresponding city
* product_measures_olist_public_dataset_: contains the product information
* sellers_olist_public_dataset_: contains the seller information of each ordered item

## Data Cleaning
However, there are some problematic entries at the geolocation table. First, there are some simulated locations that are actually outside the boundary of Brazil and should be removed. Second, there are some mistaked data inputs which will lead to high variance of the estimated location of each city (i.e. some simulated locations are associated with a wrong city). Thus, I also remove those wrong entries by cross-checking with the actual location of a city from some online sources. 

The CleanDataset folder contains the dataset after the above cleaning procedure, together with some GDP information of each Brazilian city and state for further analysis.

## Feature Engineering
The next step is to extract useful features from the raw dataset.



## Credit
Thanks to Olist for releasing this dataset.



