-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2
;

SELECT 
	MAX(total_laid_off),
    MAX(percentage_laid_off)
FROM layoffs_staging2
;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC
;

-- Difference between window Function and Group By
# Window Function
SELECT
	company,
    SUM(total_laid_off) OVER(PARTITION BY company) AS laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
;

# Group By
SELECT
	company,
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
;


WITH cte_sum AS
(
SELECT
	company,
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
)
SELECT
	SUM(laid_off)
FROM cte_sum
;

-- Checking date range of data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2
;

-- Which industry was hit with the most number of layoffs
SELECT
	industry,
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC
;


-- Which country was hit with the most number of layoffs
SELECT
	country,
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC
;


-- How were the layoffs per year
SELECT
	YEAR(`date`) as 'year',
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;

-- Remove the NULLs
SELECT
	YEAR(`date`) as 'year',
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;

-- We seem to use the main numerical column to do the EDA to begin with.
-- We can look at these numerical columns based on each column in the dataset.
-- And it should try to make sense for us to get a sense of what the data is
-- trying to tell us.

-- Now we would like to see the layoffs on a montly progression

SELECT
	SUBSTRING(`date`, 1, 7) AS `MONTH`,
    SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH`
;

-- We need to do a rolling total
-- We will use a CTE and a Window Function
WITH Rolling_Total AS
(
SELECT
	SUBSTRING(`date`, 1, 7) AS `MONTH`,
    SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH`
)
SELECT 
	`MONTH`, 
    laid_off,
    SUM(laid_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total
;


-- Now so the layoffs per company per year
SELECT
	company,
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
;


-- Starting Point
SELECT
	company,
    YEAR(`date`),
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 1 ASC
;


SELECT
	company,
    YEAR(`date`),
    SUM(total_laid_off)  AS laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
;


-- We will use a CTE to rank the company's with the highest laid off based on the laid off column
-- So what we actually would like to see is, RANK the highest layoffs per company per year
-- So for example, in 2020 rank the companies based on the highest to lowest layoffs
-- Then do the same for 2021 and so on
WITH Company_Year(company, years, total_laid_off) AS
(
SELECT
	company,
    YEAR(`date`),
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT 
	*,
    DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
-- WHERE Ranking <= 5
;
