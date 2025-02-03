# Global Layoffs Data Cleaning & Analysis Project

This repository contains a comprehensive project that involves cleaning a global layoffs dataset, performing exploratory data analysis (EDA) using MySQL, and visualizing key insights with an interactive Tableau Public dashboard.

## Overview

The dataset contains information on company layoffs including details such as company name, industry, location, total layoffs, percentage layoffs, funding details, and dates. This project demonstrates a complete workflow from data cleaning to EDA and visualization, showcasing best practices in data processing and analysis.

---

## Table of Contents

- [Data Cleaning Process](#data-cleaning-process)
  - [1. Creating a Staging Table](#1-creating-a-staging-table)
  - [2. Removing Duplicate Records](#2-removing-duplicate-records)
  - [3. Standardizing Data](#3-standardizing-data)
  - [4. Handling Null Values & Removing Unnecessary Data](#4-handling-null-values--removing-unnecessary-data)
- [Exploratory Data Analysis (EDA)](#exploratory-data-analysis-eda)
  - [Basic Data Inspection](#basic-data-inspection)
  - [Identifying Key Trends & Outliers](#identifying-key-trends--outliers)
  - [Grouped Aggregations](#grouped-aggregations)
- [Tableau Public Dashboard](#tableau-public-dashboard)
- [Conclusion](#conclusion)
- [Technologies Used](#technologies-used)

---

## Data Cleaning Process

### 1. Creating a Staging Table

To safeguard the original data, we first create a staging table that is an exact copy of the raw dataset. This allows us to perform cleaning operations without modifying the original data.

```sql
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;
```

### 2. Removing Duplicate Records

Duplicates can skew our analysis. We identify duplicates using the ROW_NUMBER() window function, partitioning by key columns. After identifying duplicates, we remove all but the first occurrence.

```sql
WITH DELETE_CTE AS (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
    FROM DELETE_CTE
) AND row_num > 1;
```

Alternatively, a temporary row_num column can be added to facilitate duplicate removal and then dropped after cleanup.

### 3. Standardizing Data

Data inconsistencies are resolved with the following operations:

#### Handling Missing Industry Data:

Set blank industry values to NULL and update them by matching company names.

```sql
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
```

#### Standardizing Industry Names:

Consolidate similar entries, e.g., changing 'Crypto Currency' and 'CryptoCurrency' to a single term 'Crypto'.

```sql
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');
```

#### Standardizing Country Names:

Remove trailing periods from country names.

```sql
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);
```

#### Converting Date Format:

Convert the date column from text to a proper DATE format.

```sql
UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;
```

### 4. Handling Null Values & Removing Unnecessary Data

After cleaning, some rows with non-essential null values are removed (e.g., where both total_laid_off and percentage_laid_off are null).

```sql
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```

Finally, any helper columns such as row_num are dropped from the table:

```sql
ALTER TABLE world_layoffs.layoffs_staging
DROP COLUMN row_num;
```

## Exploratory Data Analysis (EDA)

After cleaning, we perform several SQL queries to uncover trends and insights in the data.

### Basic Data Inspection

Retrieve all data to get an overall view of the dataset:

```sql
SELECT * 
FROM world_layoffs.layoffs_staging2;
```

### Identifying Key Trends & Outliers

#### Largest Layoff Event:

```sql
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;
```

#### Layoff Percentage Range:

```sql
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;
```

#### Companies with 100% Layoffs:

Identify companies where the entire workforce was laid off, often indicating startups that went out of business.

```sql
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;
```

#### Sorting by Funds Raised:

Analyze well-funded companies that still experienced 100% layoffs.

```sql
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
```

### Grouped Aggregations

#### Biggest Single Layoff Events:

```sql
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;
```

#### Total Layoffs by Company:

Summing layoffs across multiple events.

```sql
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC
LIMIT 10;
```

#### Total Layoffs by Location:

```sql
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY SUM(total_laid_off) DESC
LIMIT 10;
```

#### Total Layoffs by Country:

```sql
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;
```

#### Yearly Layoff Trends:


```sql
SELECT YEAR(date) AS Year, SUM(total_laid_off) AS Total_Layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY Year ASC;
```

#### Layoffs by Industry:

```sql
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;
```

#### Layoffs by Company Stage:

```sql
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY SUM(total_laid_off) DESC;
```

## Tableau Public Dashboard

To bring the analysis to life, an interactive Tableau Public dashboard was created. The dashboard includes:

#### Geographical Insights:

Interactive maps and charts showing the locations and countries most affected by layoffs.

#### Industry & Company Stage Analysis:
Visual breakdowns of layoffs by industry and the stage of the company.

You can view the live dashboard here: [Tableau Public Dashboard](https://public.tableau.com/app/profile/ericnbello/viz/WorldLayoffs_17382760095000/CompaniesbyCountry)

## Conclusion

This project demonstrates a complete workflow:

- Data Cleaning: Ensured data quality through staging, duplicate removal, and standardization.
- Exploratory Analysis: Uncovered trends, outliers, and key insights using MySQL queries.
- Visualization: Presented findings via an interactive Tableau Public dashboard.

The work shown here is a testament to thorough data preparation and analysis skills, providing actionable insights from raw datasets.

## Technologies Used

- MySQL: Data cleaning and exploratory analysis.
- Tableau Public: Data visualization and dashboard creation.
- Kaggle Dataset: Source of the global layoffs data.