World Layoffs Analysis: SQL & Power BI Project 



 Project Flow
Raw Data → SQL Cleaning → EDA → Views → Power BI Dashboard



Project Overview

This project covers the analysis of world layoffs between 2020 and 2023 using PostgreSQL for data cleaning and 
exploratory data analysis(EDA) and Power BI for visualization purposes.

The goal of the project was to clean and standardize the raw data to identify year-over-year(YoY) trends of layoffs across 
industries and countries, subsequently presenting the findings using an interactive dashboard.



Project Objectives

The aim of the analysis was to answer:
- How did the trend of both magnitude and frequency of layoffs move between 2020 and 2023?
- Which industries experienced the highest layoffs?
- Which countries were affected the most by layoffs?
- How the trends of the United States and India compare to global layoffs?
- What patterns were observed on YoY changes in layoffs across industries and countries?



Tools Used

PostgreSQL
- Data cleaning
- Data transformation
- Exploratory data analysis
- Use of SQL techniques such as CTEs, functions, window functions, joins, unions, views

Power BI
- KPI
- Interactive visualization
- Country analysis
- Trend analysis



Data cleaning

Before the analysis the data was cleaned and standardized by:
- Standardization of columns
- Removing duplicates
- Fixing corrupted entries
- Checking null and empty values, and attempting to repopulate them



Exploratory Data Analysis

Based on the scope, several analyses were conducted.

Global analysis
- Changes in total layoffs and number of layoff events throughout the years
- Average layoffs over time
- Distribution of global layoffs across industries and countries

Industry Analysis
- Industries with highest magnitude and frequency of layoffs
- YoY trends of industries layoffs
- Identification of trend patterns of layoffs over the years

Country analysis
- Countries with the highest layoffs
- Countries' dominance in global layoffs on YoY basis
- Comparison of global, United States, and India layoffs

In-Depth Analysis of 2020
- Company analysis
- Industry analysis
- Country analysis



Dashboard Overview

The Power BI dashboard consists of three interactive pages:

1. Global Layoffs KPI
Provides overview of global metrics of the dataset, which are:
- Total layoffs and layoffs across top 5 industries
- Layoffs by year
- Total number of layoff events and number of layoffs across top 5 industries
- Number of layoff events by year
- Largest single layoff event
- Average layoffs per year

2. Country Analysis
Includes:
- Share of layoffs and number of layoffs across countries
- Comparison of layoffs and number of layoff events across industries with global vs United States vs India 

Year-over-Year Analysis
Shows:
- Global layoffs of top 5 industries over time
- Global number of layoff events across top 5 industries over periods
- Country-specific trends of top 5 industries across years



Key Findings
The main findings of the analysis include:
- Layoffs peaked in 2022.
- Majority of the layoffs were concentrated in the United States.
- Consumer and Retail industries experienced the most layoffs.
- Finance industry experienced the most layoff events.
- The trend of layoffs on YoY basis varied across industries and countries.



Conclusion
This project followed complete data analysis workflow:

1. Data Cleaning
2. Data Exploration
3. Data Transformation
4. Dashboard Creation
5. Insight Generation

By utilizing PostgreSQL and Power BI, raw data was transformed into clean and structured form that explains shifts in labor 
market during 2020 - 2023 across regions and industries.
