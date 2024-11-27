#Data Cleaining with SQL

#Steps to follow
-- 1. Remove duplicates.
-- 2. Standardise data.
-- 3. Address Nulls and Blanks(first try to populate them with data ELSE delete them)
-- 4. Removing blanks rows OR columns

-- Important Note : Assess all data and columns well AND based on your analysis needs
-- decide if you need certain data columns as it will amount to irrelevant data to
-- your analysis.

-- Step 1. Create a copy of your data to work with and make changes to.
CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs
;

SELECT *
FROM layoffs_staging
;

-- Step 2. Remove duplicates
-- We will use WINDOW FXNS to do this
SELECT
	*,
    ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging
;

-- We can check to confirm for duplicates using a CTE here
-- We will check to see if there are values greater than 1 in the row_num column
WITH duplicate_cte AS
(
	SELECT
		*,
		ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
		) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
;

-- As we are going to make some updates or modifications to the table, let's create
-- a new copy of our table
CREATE TABLE layoffs_staging2 AS
SELECT
	*,
    ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging
;


-- Verify new staging table
SELECT *
FROM layoffs_staging2
;

-- Verifying that the identified duplicates are indeed duplicates
SELECT *
FROM layoffs_staging2
WHERE company = 'Wildlife Studios'
;

-- Delete the duplicate rows from the table
DELETE
FROM layoffs_staging2
WHERE row_num > 1
;

-- Confirm duplicates have been deleted
SELECT *
FROM layoffs_staging2
WHERE row_num > 1
;
-- 5 duplicate rows deleted


-- STEP 3. Standardisation of Data
-- We are checking each column to make sure that the data in each column
-- is in the correct format, value, organisation, etc.

#COMPANY COLUMN
SELECT company
FROM layoffs_staging2
-- ORDER BY company DESC
;

SELECT COUNT(company), COUNT(DISTINCT company)
FROM layoffs_staging2
;

-- Removing leading and traliing whitespaces
SELECT company, TRIM(company)
FROM layoffs_staging2
;

-- Update the table with this trimmed column
UPDATE layoffs_staging2
SET company = TRIM(company)
;

SELECT *
FROM layoffs_staging2
;

#LOCATION COLUMN
SELECT  DISTINCT location
FROM layoffs_staging2
-- ORDER BY location
;

#INDUSTRY COLUMN
SELECT *
FROM layoffs_staging2
;

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry
;

-- There are 3 anomalies I can observe
# A Null
# A blank record
# Three different types of Crypto

SELECT *
FROM layoffs_staging2
WHERE industry LIKE "Crypto%"
;
-- Looking at the results "Crypto" seems to be the main representation or designation in this data

-- Update all Crypto representations to "Crypto"
UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%"
;

SELECT *
FROM layoffs_staging2
;


#DATE COLUMN
-- Dates seem to always be problematic
-- Let us put the dates in a common format
SELECT `date`
FROM layoffs_staging2
;

SELECT `date`, STR_TO_DATE(`date`, "%m/%d/%Y")
FROM layoffs_staging2
;
-- When using the STR_TO_DATE fxn, you need to remember to include
-- the forward slashes in the date format portion of the fxn
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y")
;
-- The change has been updated
-- However, the datatype of the date column is "TEXT"
-- and for time series calculations it will be better
-- to convert the data type to date

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;
-- So this column now has a DATE datatype

SELECT *
FROM layoffs_staging2
;

#COUNTRY COLUMN
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country
;

SELECT *
FROM layoffs_staging2
WHERE country LIKE "United States%"
;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE "United States%"
;

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE "United States%"
;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%"
;

SELECT *
FROM layoffs_staging2
;


-- STEP 4. Nulls & Blanksl
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;
-- Ideally, we would delet this data because we cannot use it to perform any analysis due to the lack of information

-- We observed some nulls and blank spaces in the some columns, "industry" to be specific
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
;

-- Let us check on these companies and their blanks or nulls
SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb"
;

-- So we can populate the industry column with the already existing records for the companies identified.
-- We will join the table on itself see these records side-by-side
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL
;

-- To see just the industries
SELECT
	t1.industry,
    t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL
;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL
; 

-- However, to effect this update, we need to change the blanks spaces to NULLs
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''
;

-- The new updates statement now will be due to changing the blank spaces to NULLs
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
; 


SELECT  stage
FROM layoffs_staging2
ORDER BY stage
;

SELECT *
FROM layoffs_staging2
WHERE stage IS NULL
;

SELECT *
FROM layoffs_staging2
WHERE company = "Zapp"
;
-- NULL values for Column "stage" checked nad have single hit records
-- Unable to populate

-- DELETING ROWS AND/OR COLUMNS
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;
-- Data here is not useful due to lack of key values in the total_laid_off col. and the percentage_laid_off
-- We delet these rows

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;


SELECT *
FROM layoffs_staging2
;

-- So now we get rid of the row_num column
-- We do not need it
ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

















