# Analysis-of-Brazilian-Ecommerce-Dataset
This project is based on the dataset which was provided by Olist and was released by Kaggle. Olist is the largest department store in Brazilian marketplaces. This dataset contains information of 100k orders made at Olist from 2016 to 2018. Please refer to [here](https://www.kaggle.com/olistbr/brazilian-ecommerce) for the details of the original dataset. There could be lots of possible work from this dataset, including sales forecasting, customer review analysis, delivery time analysis, etc. 

## Objective
The objective of this project is to analyze the delivery time of each order, using visualization and some statistical techniques (particularly regression analysis). I am interested in the impact of the following features on the delivery time:
* the location of customer / seller
* distance between customer and seller
* product information
* the prosperity effect of the customer / seller city

## Description of Dataset
The RawDataset contained in this project was adopted from the [original dataset](https://www.kaggle.com/olistbr/brazilian-ecommerce) downloadable from Kaggle. The CleanDataset folder contains the cleaned dataset, together with some GDP information of each Brazilian city and state for further analysis.

## Library Installation
I used R and WinBUGS (for Bayesian Modelling) in this project. The followings are some necessary R packages for implementing my project:
* dplyr
* readr
* lme4
* R2WinBUGS

## Methodology
I perform regression analysis on the dataset. Particularly, I model the delivery time using Generalized Linear Mixed Effect Model (GLMM) with Gamma distribution, 

## Conclusion


## Credit
Thanks to Olist for releasing this dataset.



