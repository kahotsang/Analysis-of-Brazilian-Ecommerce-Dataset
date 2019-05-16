# Analysis-of-Brazilian-Ecommerce-Dataset
This project is based on the dataset which was provided by Olist and was released by Kaggle. Olist is the largest department store in Brazilian marketplaces. This dataset contains information of 100k orders made at Olist from 2016 to 2018. Please refer to [here](https://www.kaggle.com/olistbr/brazilian-ecommerce) for the details of the original dataset. There could be lots of possible work from this dataset, including sales forecasting, customer review analysis, delivery time analysis, etc. 

## Objective
The objective of this project is to analyze the delivery time of each order, using visualization and some statistical techniques (particularly regression analysis). I am particularly interested in the effect of _the location of customer / seller_ on the delivery time.

## Description of Dataset
The RawDataset contained in this project was adopted from the [original dataset](https://www.kaggle.com/olistbr/brazilian-ecommerce) downloadable from Kaggle. The CleanDataset folder contains the cleaned dataset, together with some GDP information of each Brazilian city and state for further analysis.

## Library Installation
I used R and WinBUGS (for Bayesian Modelling) in this project. The followings are some necessary R packages for implementing my project:
* dplyr
* readr
* lme4
* R2WinBUGS

For the installation of WinBUGS, please refer to [here](https://www.mrc-bsu.cam.ac.uk/software/bugs/the-bugs-project-winbugs/)

## Methodology
I perform regression analysis on the dataset. Particularly, I model the delivery time using multi-level model (also called Generalized Linear Mixed Effect Model (GLMM). The first-level here refers to each order, while the second-level here refers to the customer city where the order is placed. This modeling is useful due to the following reasons:
1. It is likely that there is some correlation across the order delivery time for the orders within the same customer city.
2. I am interested in how the location of the customer affects the order delivery time (i.e. the second-level effect).

## Conclusion
1. The distance between buyer and seller has a strong effect on the delivery time
2. There exists correlation for delivery time of the customers within same city
3. The delivery time is affected by the location of the customer city, especially its latitude

## Credit
Thanks to Olist for releasing this dataset.



