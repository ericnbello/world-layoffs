-- SQL Project - Data Cleaning
-- Source Dataset: https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- Step 1: Inspect the raw data
SELECT * 
FROM world_layoffs.layoffs;

-- Step 2: Create a staging table for cleaning
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

-- Data cleaning steps to follow:
-- 1. Remove Duplicates
-- 2. Standardize data and fix errors
-- 3. Examine null values and decide on treatment
-- 4. Remove any unnecessary columns/rows

---------------------------------------------------
-- 1. Remove Duplicates
---------------------------------------------------

-- Check for duplicates using a window function
SELECT company, industry, total_laid_off, `date`,
       ROW_NUMBER() OVER (
            PARTITION BY company, industry, total_laid_off, `date`
       ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Find duplicates with row_num > 1 (first occurrence is row 1)
SELECT *
FROM (
    SELECT company, industry, total_laid_off, `date`,
           ROW_NUMBER() OVER (
               PARTITION BY company, industry, total_laid_off, `date`
           ) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Check a specific company ('Oda') for legitimacy before deleting
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda';

-- Find true duplicates considering all key columns
SELECT *
FROM (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Delete duplicates using a CTE approach
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

-- Alternative approach: adding a row_num column, cleaning, then removing the helper column
ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

-- Create a new staging table with the row number calculated
CREATE TABLE world_layoffs.layoffs_staging2 (
    company text,
    location text,
    industry text,
    total_laid_off INT,
    percentage_laid_off text,
    `date` text,
    stage text,
    country text,
    funds_raised_millions INT,
    row_num INT
);

INSERT INTO world_layoffs.layoffs_staging2
    (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num)
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Remove rows where row_num is 2 or greater
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

---------------------------------------------------
-- 2. Standardize Data
---------------------------------------------------

-- Inspect the data in the new staging table
SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Identify and fix null or empty 'industry' values
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = ''
ORDER BY industry;

-- Check specific companies for discrepancies
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Convert empty strings to null for easier handling
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Populate null industry values using non-null values from the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Standardize industry names (e.g., all variations of 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Standardize country names by removing trailing periods
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Standardize date formats using STR_TO_DATE and modify column type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM world_layoffs.layoffs_staging2;

---------------------------------------------------
-- 3. Examine Null Values
---------------------------------------------------

-- Check null values in key columns
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Remove rows that are not useful (both total_laid_off and percentage_laid_off are null)
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

---------------------------------------------------
-- 4. Clean Up - Remove Helper Columns
---------------------------------------------------

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM world_layoffs.layoffs_staging2;
