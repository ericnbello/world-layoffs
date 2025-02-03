-- EDA - Exploratory Data Analysis on Layoffs Data
-- This file explores trends, patterns, and outliers to generate insights for Tableau dashboards.

---------------------------------------------------
-- Initial Data Inspection
---------------------------------------------------
SELECT * 
FROM world_layoffs.layoffs_staging2;

---------------------------------------------------
-- Basic Metrics
---------------------------------------------------

-- Maximum number of layoffs in a single record
SELECT MAX(total_laid_off) AS max_layoffs
FROM world_layoffs.layoffs_staging2;

-- Examine the range of layoff percentages
SELECT MAX(percentage_laid_off) AS max_percentage,
       MIN(percentage_laid_off) AS min_percentage
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- Identify companies that laid off 100% of their workforce (percentage_laid_off = 1)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;

-- For companies with 100% layoffs, order by funds raised to see funding context
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

---------------------------------------------------
-- Aggregations using GROUP BY
---------------------------------------------------

-- Companies with the largest single layoff event (by a single day)
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;

-- Companies with the most total layoffs over time
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 10;

-- Layoffs aggregated by location
SELECT location, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY total_layoffs DESC
LIMIT 10;

-- Layoffs aggregated by country
SELECT country, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY total_layoffs DESC;

-- Yearly trend in layoffs
SELECT YEAR(date) AS layoff_year, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY layoff_year ASC;

-- Layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY total_layoffs DESC;

-- Layoffs by company stage (e.g., startup, mature, etc.)
SELECT stage, SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY total_layoffs DESC;
