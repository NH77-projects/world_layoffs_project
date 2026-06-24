-- ==================
-- 2. DATA CLEANING
-- ==================


-- ============================
-- 2.1 Standardizing columns
-- ============================

-- company
UPDATE layoffs 
SET company = NULLIF(TRIM(company),'');


-- location
UPDATE layoffs
SET location = NULLIF(TRIM(location),'');


-- industry
UPDATE layoffs
SET industry = NULLIF(TRIM(industry),'');


-- total_laid_off
ALTER TABLE layoffs
ALTER COLUMN total_laid_off TYPE INT
USING NULLIF(TRIM(total_laid_off),'')::INT;


-- percentage_laid_off
ALTER TABLE layoffs
ALTER COLUMN percentage_laid_off TYPE NUMERIC(3,2)
USING ROUND(NULLIF(TRIM(percentage_laid_off),'')::NUMERIC, 2);


-- date
ALTER TABLE layoffs
ALTER COLUMN date TYPE DATE 
USING NULLIF(TRIM(date),''):: DATE;


-- stage
UPDATE layoffs
SET stage = NULLIF(TRIM(stage),'');


-- country
UPDATE layoffs
SET country = NULLIF(TRIM(country),'');


-- funds_raised_millions
ALTER TABLE layoffs
ALTER COLUMN funds_raised_millions TYPE NUMERIC(15,2)
USING ROUND(NULLIF(TRIM(funds_raised_millions),'')::NUMERIC, 2);


-- ============================
-- 2.2 Removing duplicates
-- ============================


WITH duplicate_cte AS(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage,
		country, funds_raised_millions) AS row_num
	FROM layoffs
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


-- Creation of staging table


CREATE TABLE layoffs_staging
(LIKE layoffs);


ALTER TABLE layoffs_staging
ADD COLUMN row_num INT;


INSERT INTO layoffs_staging
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage,
		country, funds_raised_millions) AS row_num
	FROM layoffs;


DELETE 
FROM layoffs_staging
WHERE row_num > 1;


ALTER TABLE layoffs_staging
DROP COLUMN row_num;


-- =================================
-- 2.3 Fixing corrupted entries
-- =================================


UPDATE layoffs_staging
SET company = 'Ualá'
WHERE company = 'UalÃ¡'; -- A company name got corrupted during conversion.


SELECT *
FROM layoffs_staging
WHERE location::text ~ 'Ã'; -- Some location names got corrupted during conversion.


BEGIN;


UPDATE layoffs_staging
SET location = CASE
	WHEN location = 'FlorianÃ³polis' THEN 'Florianópolis'
	WHEN location = 'MalmÃ¶' THEN 'Malmö'
	WHEN location = 'DÃ¼sseldorf' THEN 'Düsseldorf'
	ELSE location
END;


COMMIT;


SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1; -- There are 3 different 'Crypto' related industry entries, let's standardize all to 'Crypto Currency'


BEGIN;


UPDATE layoffs_staging
SET industry = 'Crypto Currency'
WHERE industry LIKE 'Crypt%';


COMMIT;


SELECT DISTINCT country
from layoffs_staging
ORDER BY 1; -- There is entry which has typo at the end 'United States.'


BEGIN;


UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United Stat%';


COMMIT;


-- ==========================================================
-- 2.4 Checking NULLs, and whether we can populate them.
-- ==========================================================


SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 
/* Since our goal is to analyze the layoffs, if both total and percentage laid off are NULL and can't be populated
then those rows are useless to our analysis. Thus, let's delete them. */


BEGIN;

DELETE 
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


COMMIT;


SELECT *
FROM layoffs_staging
WHERE industry IS NULL; 
/* Four companies have NULL industry entries, checking whether there are different entries for these companies to 
figure out their potential industries. */


SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'
OR company = 'Bally''s Interactive'
OR company = 'Carvana'
OR company = 'Juul';
/* 'Airbnb', 'Carvana', and 'Juul' have entries with populated industry name. Using this information let's repopulate
NULLs. */


BEGIN;


UPDATE layoffs_staging ls1
SET industry = ls2.industry
FROM layoffs_staging ls2
	WHERE ls1.company = ls2.company
	AND ls1.industry IS NULL
	AND ls2.industry IS NOT NULL;


SELECT * 
FROM layoffs_staging ls1
	JOIN layoffs_staging ls2
		ON ls1.company = ls2.company
			WHERE ls1.industry IS NULL
			AND ls2.industry IS NOT NULL;


COMMIT;