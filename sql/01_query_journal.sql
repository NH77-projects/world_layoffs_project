-- =====================================================
-- QUERY HISTORY
-- =====================================================




-- =========================================================================================================================
/* Table of Contents

	1. DATA CLEANING
		1.1 Standardizing Columns
		1.2 Removing Duplicates
		1.3 Fixing Corrupted Entries
		1.4 Handling NULL/empty Values
	2. EXPLORATORY DATA ANALYSIS
		2.1 General Exploration
		2.2 Automation for YoY Analysis
			2.2.1 Company Share Analysis Function
			2.2.2 YoY Companies with Full Workforce Laid Off Analysis Function
			2.2.3 YoY Companies with at least Half of Workforce Laid Off Analysis Function
			2.2.4 Industry Share Analysis Function
			2.2.5 Country Share Analysis Function
			2.2.6 Selected Countries' Share Analysis Function
			2.2.7 YoY Industry Rank View
			2.2.8 Industry Snapshot View
		2.3 Global Analysis
		2.4 Industry Analysis
		2.5 Country Analysis
		2.6 Overall Analysis of Selected Countries
			2.6.1 YoY Analysis of Selected Countries
		2.7 In-Depth Analysis of 2020
*/
-- =========================================================================================================================



-- =====================================================
-- 1. DATA CLEANING
-- =====================================================




-- =====================================================
-- 1.1 Standardizing Columns
-- =====================================================




SELECT *
FROM layoffs;


-- company Column

UPDATE layoffs 
SET company = NULLIF(TRIM(company),''); 


-- location Column 

UPDATE layoffs
SET location = NULLIF(TRIM(location),''); 


-- industry Column

UPDATE layoffs
SET industry = NULLIF(TRIM(industry),''); 


-- total_laid_off Column

ALTER TABLE layoffs
ALTER COLUMN total_laid_off TYPE INT
USING NULLIF(TRIM(total_laid_off),'')::INT; 


-- percentage_laid_off Column

SELECT percentage_laid_off
FROM layoffs
WHERE percentage_laid_off !~ '^[0-9]+\.[0-9]+$';


SELECT percentage_laid_off
FROM layoffs
WHERE percentage_laid_off LIKE '_.__%'
ORDER BY 1 ; 


ALTER TABLE layoffs
ALTER COLUMN percentage_laid_off TYPE NUMERIC(3,2)
USING ROUND(NULLIF(TRIM(percentage_laid_off),'')::NUMERIC, 2); 


-- date Column

ALTER TABLE layoffs
ALTER COLUMN date TYPE DATE 
USING NULLIF(TRIM(date),''):: DATE;


-- stage Column

UPDATE layoffs
SET stage = NULLIF(TRIM(stage),'');


-- country Column

UPDATE layoffs
SET country = NULLIF(TRIM(country),'');


-- funds_raised_millions Column

SELECT funds_raised_millions
FROM layoffs
WHERE funds_raised_millions LIKE '%.__%';


ALTER TABLE layoffs
ALTER COLUMN funds_raised_millions TYPE NUMERIC(15,2)
USING ROUND(NULLIF(TRIM(funds_raised_millions),'')::NUMERIC, 2);




-- =====================================================
-- 1.2 Removing Duplicates
-- =====================================================




WITH duplicate_cte AS(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage,
		country, funds_raised_millions) AS row_num
	FROM layoffs
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


SELECT *
FROM layoffs
WHERE company = 'Yahoo';


-- Creating Staging Table

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


SELECT *
FROM layoffs_staging
WHERE row_num > 1;


ALTER TABLE layoffs_staging
DROP COLUMN row_num;




-- =====================================================
-- 1.3 Fixing Corrupted Entries
-- =====================================================




SELECT *
FROM layoffs_staging
WHERE company::text ~ 'Ã';


UPDATE layoffs_staging
SET company = 'Ualá'
WHERE company = 'UalÃ¡'; -- A company name got corrupted during conversion.


SELECT DISTINCT location
FROM layoffs_staging
ORDER BY 1;


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


SELECT *
FROM layoffs_staging
WHERE location::text ~ 'Ã';


COMMIT;


SELECT *
FROM layoffs_staging
WHERE industry::text ~ 'Ã';


SELECT *
FROM layoffs_staging
WHERE stage::text ~ 'Ã';


SELECT *
FROM layoffs_staging
WHERE country::text ~ 'Ã';


SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1; -- There are 3 different 'Crypto' related industry entries, let's standardize all to 'Crypto Currency'


BEGIN;


UPDATE layoffs_staging
SET industry = 'Crypto Currency'
WHERE industry LIKE 'Crypt%';


SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;


COMMIT;


SELECT DISTINCT industry
FROM layoffs_staging
WHERE industry LIKE 'Crypt%';


SELECT DISTINCT country
from layoffs_staging
ORDER BY 1; -- There is entry which has typo at the end 'United States.'


BEGIN;


UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United Stat%';


SELECT DISTINCT country
from layoffs_staging
ORDER BY 1;


COMMIT;




-- =====================================================
-- 1.4 Handling NULL/empty Values
-- =====================================================




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


SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 


COMMIT;


SELECT *
FROM layoffs_staging
WHERE industry IS NULL; 
/* Four companies have NULL industry entries, checking whether there are different entries for these companies to figure out 
their potential industries. */


SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'
OR company = 'Bally''s Interactive'
OR company = 'Carvana'
OR company = 'Juul';
/* 'Airbnb', 'Carvana', and 'Juul' have entries with populated industry name. Using this information let's repopulate NULLs. */


SELECT * 
FROM layoffs_staging ls1
	JOIN layoffs_staging ls2
		ON ls1.company = ls2.company
			WHERE ls1.industry IS NULL
			AND ls2.industry IS NOT NULL;


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




-- =====================================================
-- 2. EXPLORATORY DATA ANALYSIS 
-- =====================================================




-- =====================================================
-- 2.1 General Exploration
-- =====================================================




SELECT *
FROM layoffs_staging;


SELECT DISTINCT date
FROM layoffs_staging
ORDER BY 1; -- Data covers the layoffs in companies between 2020-2023


-- Let's check which company laid off the most people.


SELECT company, SUM(total_laid_off) total_num
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;
/* As expected, big companies laid off the people in thousands with Amazon having the most at 18150, followed by
Google, Meta, Salesforce, Microsoft, and Philips with 10000 or more people laid off. */


WITH top_10_company_cte AS(
SELECT company, SUM(total_laid_off) total_num
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC
LIMIT 10
)
SELECT SUM(total_num)
FROM top_10_company_cte; 
/* In total, 98576 people were fired from the top 10 results. Let's also check what percentage of the company was 
laid off. */


SELECT company, total_laid_off, percentage_laid_off, date
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL
ORDER BY 2 DESC;
/* Despite having the most number of people laid off, the percentage of staff laid off by Amazon is less than 5% in
their two big layoffs. The percentage for Google and Microsoft are also comparatively low, with 6% and 5% during
their massive layoffs, while Meta, Salesforce, and Phillips had around 10%. */




-- =====================================================
-- 2.2 Automation for YoY Analysis
-- =====================================================




-- =====================================================
-- 2.2.1 Company Share Analysis Function
-- =====================================================




CREATE OR REPLACE FUNCTION company_tree(start_date DATE, end_date DATE)
RETURNS TABLE (
company TEXT,
company_laid_off BIGINT,
pct_share_all NUMERIC,
company_laid_off_all BIGINT,
num_events BIGINT
)
LANGUAGE SQL
AS $$
WITH base AS (
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND total_laid_off IS NOT NULL
),
agg AS (
	SELECT 
		company,
		SUM(total_laid_off) AS company_laid_off,
		COUNT(*) AS num_events
	FROM base
	GROUP BY company
)
	SELECT 
		company,
		company_laid_off,
		ROUND(100.0 * company_laid_off / SUM(company_laid_off) OVER(), 2) AS pct_share_all,
		SUM(company_laid_off) OVER () AS company_laid_off_all,
		num_events
	FROM agg
	ORDER BY company_laid_off DESC
$$;


SELECT *
FROM company_tree ('2020-01-01', '2024-01-01');




-- ====================================================================
-- 2.2.2 YoY Companies with Full Workforce Laid Off Analysis Function
-- ====================================================================




CREATE OR REPLACE FUNCTION company_full_lay_off_tree (start_date DATE, end_date DATE)
RETURNS TABLE(
company TEXT,
industry TEXT,
country TEXT,
total_laid_off BIGINT
)
LANGUAGE SQL
AS $$
WITH base AS (
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND percentage_laid_off = 1
)
	SELECT company, industry, country, SUM(total_laid_off) AS total_laid_off
	FROM base
	GROUP BY company, industry, country
	ORDER BY total_laid_off DESC
$$;


SELECT *
FROM company_full_lay_off_tree('2020-01-01', '2024-01-01');

SELECT *
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;




-- ================================================================================
-- 2.2.3 YoY Companies with at least Half of Workforce Laid Off Analysis Function
-- ================================================================================




CREATE OR REPLACE FUNCTION company_at_least_half_lay_off_tree (start_date DATE, end_date DATE)
RETURNS TABLE(
company TEXT,
industry TEXT,
company_laid_off BIGINT,
pct_laid_off NUMERIC,
country TEXT
)
LANGUAGE SQL
AS $$
WITH base AS (
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND percentage_laid_off >= 0.5
)
	SELECT company, industry, total_laid_off AS company_laid_off, percentage_laid_off AS pct_laid_off, country
	FROM base
	ORDER BY company_laid_off DESC
$$;


SELECT country, COUNT(country)
FROM company_at_least_half_lay_off_tree('2020-01-01', '2024-01-01')
GROUP BY country
ORDER BY 2 DESC;




-- =====================================================
-- 2.2.4 Industry Share Analysis Function
-- =====================================================




CREATE OR REPLACE FUNCTION 	industry_tree(start_date DATE, end_date DATE)
RETURNS TABLE(
industry TEXT,
total_laid_off BIGINT,
pct_laid_off NUMERIC,
total_laid_off_all BIGINT,
num_events BIGINT,
pct_num_events NUMERIC,
total_events BIGINT
)
LANGUAGE SQL
AS $$
WITH base AS(
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND total_laid_off IS NOT NULL
),
agg AS(
	SELECT 
		industry,
		SUM(total_laid_off) AS total_laid_off,
		COUNT(*) AS num_events
	FROM base
	GROUP BY industry
)
SELECT 
	industry,
	total_laid_off,
	ROUND(100.0 * total_laid_off / SUM(total_laid_off) OVER(), 2) AS pct_laid_off,
	SUM(total_laid_off) OVER() AS total_laid_off_all,
	num_events,
	ROUND(100.0 * num_events / SUM(num_events) OVER(), 2) AS pct_num_events,
	SUM(num_events) OVER() AS total_events
FROM agg
ORDER BY total_laid_off DESC
$$;




-- =====================================================
-- 2.2.5 Country Share Analysis Function
-- =====================================================




CREATE OR REPLACE FUNCTION country_tree(start_date DATE, end_date DATE)
RETURNS TABLE (
country TEXT,
total_laid_off BIGINT,
pct_laid_off NUMERIC,
total_laid_off_all BIGINT,
num_events BIGINT,
pct_events NUMERIC,
total_events BIGINT
)
LANGUAGE SQL
AS $$
WITH base AS(
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND total_laid_off IS NOT NULL
),
agg AS(
	SELECT 
		country,
		SUM(total_laid_off) AS total_laid_off,
		COUNT(*) AS num_events
	FROM base
	GROUP BY country
)
	SELECT 
		country,
		total_laid_off,
		ROUND(100.0 * total_laid_off / SUM(total_laid_off) OVER(), 2) AS pct_laid_off,
		SUM(total_laid_off) OVER() AS total_laid_off_all,
		num_events,
		ROUND(100.0 * num_events / SUM(num_events) OVER(), 2) AS pct_events,
		SUM(num_events) OVER() AS total_events
	FROM agg
	ORDER BY total_laid_off DESC
$$;




-- =====================================================
-- 2.2.6 Selected Countries' Share Analysis Function
-- =====================================================




CREATE OR REPLACE FUNCTION gl_us_ind_tree (start_date DATE, end_date DATE)
RETURNS TABLE(
global_industry TEXT,
global_laid_off BIGINT,
global_pct_laid_off NUMERIC,
global_laid_off_all BIGINT,
global_num_events BIGINT,
global_pct_events NUMERIC,
global_total_events BIGINT,
us_industry TEXT,
us_laid_off BIGINT,
us_pct_laid_off NUMERIC,
us_laid_off_all BIGINT,
us_num_events BIGINT,
us_pct_events NUMERIC,
us_total_events BIGINT,
ind_industry TEXT,
ind_laid_off BIGINT,
ind_pct_laid_off NUMERIC,
ind_laid_off_all BIGINT,
ind_num_events BIGINT,
ind_pct_events NUMERIC,
ind_total_events BIGINT
)
LANGUAGE SQL
AS $$
WITH base AS(
	SELECT *
	FROM layoffs_staging
		WHERE date >= start_date
		AND date < end_date
		AND total_laid_off IS NOT NULL
),
global_cte AS(
	SELECT 
		industry,
		SUM(total_laid_off) AS global_laid_off,
		COUNT(*) AS global_num_events
	FROM base
	GROUP BY industry
),
us_cte AS(
	SELECT 
		industry,
		SUM(total_laid_off) AS us_laid_off,
		COUNT(*) AS us_num_events
	FROM base
	WHERE country = 'United States'
	GROUP BY industry
),
ind_cte AS(
	SELECT 
		industry,
		SUM(total_laid_off) AS ind_laid_off,
		COUNT(*) AS ind_num_events
	FROM base
	WHERE country = 'India'
	GROUP BY industry
),
joined_cte AS(
	SELECT 
		g.industry AS global_industry,
		global_laid_off,
		global_num_events,
		u.industry AS us_industry,
		us_laid_off,
		us_num_events,
		i.industry AS ind_industry,
		ind_laid_off,
		ind_num_events
	FROM global_cte AS g
		FULL OUTER JOIN us_cte AS u
			ON g.industry = u.industry
		FULL OUTER JOIN ind_cte AS i
			ON g.industry = i.industry
)
	SELECT 
		global_industry,
		global_laid_off,
		ROUND(100.0 * global_laid_off / SUM(global_laid_off) OVER(), 2) AS global_pct_laid_off,
		SUM(global_laid_off) OVER() AS global_laid_off_all,
		global_num_events,
		ROUND(100.0 * global_num_events / SUM(global_num_events) OVER(), 2) AS global_pct_events,
		SUM(global_num_events) OVER() AS global_total_events,
		us_industry,
		us_laid_off,
		ROUND(100.0 * us_laid_off / SUM(us_laid_off) OVER(), 2) AS us_pct_laid_off,
		SUM(us_laid_off) OVER() AS us_laid_off_all,
		us_num_events,
		ROUND(100.0 * us_num_events / SUM(us_num_events) OVER(), 2) AS us_pct_events,
		SUM(us_num_events) OVER() AS us_total_events,
		ind_industry,
		ind_laid_off,
		ROUND(100.0 * ind_laid_off / SUM(ind_laid_off) OVER(), 2) AS ind_pct_laid_off,
		SUM(ind_laid_off) OVER() AS ind_laid_off_all,
		ind_num_events,
		ROUND(100.0 * ind_num_events / SUM(ind_num_events) OVER(), 2) AS ind_pct_events,
		SUM(ind_num_events) OVER() AS ind_total_events
	FROM joined_cte
	ORDER BY global_laid_off DESC
$$;



-- =====================================================
-- 2.2.7 YoY Industry Rank View
-- =====================================================




CREATE OR REPLACE VIEW industry_year_rank_view AS
WITH yearly_industry AS(
	SELECT 
		'2020' AS period,
		industry,
		pct_laid_off AS share,
		RANK() OVER(ORDER BY pct_laid_off DESC) AS rank
	FROM industry_tree('2020-01-01', '2021-01-01')
UNION ALL
	SELECT
		'2021',
		industry,
		pct_laid_off,
		RANK() OVER(ORDER BY pct_laid_off DESC)
	FROM industry_tree('2021-01-01', '2022-01-01')
UNION ALL
    SELECT
        '2022',
        industry,
        pct_laid_off,
        RANK() OVER (ORDER BY pct_laid_off DESC)
    FROM industry_tree('2022-01-01', '2023-01-01')
UNION ALL
    SELECT
        '2023',
        industry,
        pct_laid_off,
        RANK() OVER (ORDER BY pct_laid_off DESC)
    FROM industry_tree('2023-01-01', '2024-01-01')
)
SELECT *
FROM yearly_industry
ORDER BY industry, period;




-- =====================================================
-- 2.2.8 Industry Snapshot View
-- =====================================================




CREATE VIEW vw_industry AS
SELECT * 
FROM industry_tree ('2020-01-01', '2024-01-01');




-- =====================================================
-- 2.3 Global Analysis
-- =====================================================




SELECT EXTRACT(YEAR FROM date) AS year,
	SUM(total_laid_off) AS laid_off,
	ROUND(100.0 * SUM(total_laid_off) / SUM(SUM(total_laid_off)) OVER(), 2) AS pct_laid_off,
	SUM(SUM(total_laid_off)) OVER() AS laid_off_all,
	COUNT(total_laid_off) AS num_events,
	ROUND(100.0 * COUNT(total_laid_off) / SUM(COUNT(total_laid_off)) OVER(), 2) AS pct_events,
	SUM(COUNT(total_laid_off)) OVER() AS total_events
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL
AND date IS NOT NULL
GROUP BY year
ORDER BY year;

/* Throughout the observation period, a total of around 380K people were laid off, and 1,616 layoff events were recorded.

The trend of both magnitude and frequency of layoffs followed a fluctuating pattern, decreasing between 2020–2021, rising in 
2022, and falling again in 2023.

2020 accounted for 21% of total layoffs and 29% of layoff events. Both figures significantly fell in the following year, 
making 2021 the year with the lowest magnitude and frequency of layoffs, at around 4% and 2% respectively. Layoffs dropped by
approximately 80.5% from 2020 to 2021.

Both values then substantially increased in 2022, reaching around 42% of total layoffs and 50% of layoff events. The highest 
number of layoffs occurred in 2022, with over 160K employees affected — nearly twice as many as in 2020. The increase from 2021 
to 2022 represents an approximate 915% rise.

Despite a smaller decline in magnitude (~22%), the frequency of layoffs dropped by around 63% from 2022 to 2023. This indicates
that fewer layoff events occurred, but each event affected a larger number of employees. Regardless, 2023 still recorded the 
second-highest magnitude of layoffs in the dataset.  
*/




-- =====================================================
-- 2.4 Industry Analysis
-- =====================================================




WITH industry_year AS(
	SELECT
		industry,
		EXTRACT(YEAR FROM date) AS year,
		SUM(total_laid_off) AS laid_off
	FROM layoffs_staging
		WHERE total_laid_off IS NOT NULL
	GROUP BY industry, EXTRACT(YEAR FROM date)
),
lagged AS(
	SELECT 
		industry,
		year,
		laid_off,
		LAG(laid_off) OVER(PARTITION BY industry ORDER BY year) AS prev_year_laid_off
	FROM industry_year
)
	SELECT 
		industry,
		year,
		laid_off,
		prev_year_laid_off,
		laid_off - prev_year_laid_off AS delta,
		ROUND(100.0 * (laid_off - prev_year_laid_off) / NULLIF(prev_year_laid_off, 0), 2) AS pct_delta
	FROM lagged
	ORDER BY industry, year;


SELECT *
FROM industry_tree('2020-01-01', '2024-01-01');

SELECT *
FROM industry_tree('2020-01-01', '2021-01-01');

SELECT *
FROM industry_tree('2021-01-01', '2022-01-01');

SELECT *
FROM industry_tree('2022-01-01', '2023-01-01');

SELECT *
FROM industry_tree('2023-01-01', '2024-01-01');

SELECT *
FROM industry_year_rank_view;

/* Across the observed period, layoffs were relatively evenly distributed across industries, with no single industry 
consistently dominating the overall share. However, the top five industries—Consumer, Retail, Other, Transportation, 
and Finance—collectively accounted for nearly 50% of all observed layoffs.

The distribution among these industries on yearly basis is not consistent, where some periods have more concentration among 
leaders, whereas other years with much closer distribution.

In 2020, Transportation(18%) and Travel(17%) concentrated the most layoffs, followed by close distribution of 3rd and 4th with
10%. The top 4 industries accounted for around 55% of the observation.

2021 shows a top concentration in 5 industries whose share range from 12% to 23%. The distribution among them for the next 
industry isn't too high where ranking goes from 23%, 18%, 17%, 15%, and 12%.

2022 however, has the most close distribution among the industries where the difference from each industry's share is around
1% - 2%.

2023 share is dominated by the leader with 23%, while having relatively close distribution among other industries, with second
highest industry having 12% where the difference from each following industry's share being around 1% - 2%.

Yearly concentration patterns varied considerably. Layoffs were highly concentrated in a small number of industries in
2020 and 2023, whereas 2022 exhibited the most balanced distribution, with only marginal differences between leading sectors.
The 2021 period fell between these two extremes, with several industries maintaining substantial but relatively similar shares.

Consumer is one of the consistent industries which had a dominant presence. Despite having comparatively lower share in 2020,
where top 4 industries had over 50% share, it was the most dominant industry with almost 23% of total layoffs in 2021. 
Subsequently, Consumer has been second major industry in following periods with around 12%, where in 2022 concentration was even,
while in 2023 leader had 23% followed by other 3 industries with around 10-12 %. 

Retail has been a consistent major industry with around 10% layoffs throughout the years, with the exception of 2021, where it
had around 7% share as sixth highest industry where average of first four was 18%. It peaked the following year becoming the 
most dominant industry with 13% share where, distribution was close among industries. It was also third dominant in 2023 with
almost 11% where distribution was close among the top industries, excluding the leader.

'Other' industry shows an interesting observation where despite having very low share in first three years, 0.6% in first year,
followed by around 4% in 2021 and 2022, it spiked to 23% in 2023 becoming the most concentrated industry, which was followed by
other industries that had around 10% share.

Transportation's share on yearly basis followed an interesting pattern. Experiencing its peak in 2020 with 18& as the most 
dominant industry, while dropping to 1% the next year. Similar pattern also occurs in following years, where its share was 
the third most dominant in 2022 with 9.5%, where the share was divided closely among the top industries with around 10%, 
whereas next year it dropped to almost 3% where top 5 industries had an average of 13%. Each dominant year was followed by a 
large decline in share.

As the fifth largest industry, Finance experienced irregular movement in dominance. Despite being the third highest industry in
2020 with around 11%, where leaders accounted for 35%, the next year it had zero layoffs according to data. However, in 2022
it was fifth dominant, where shares were closely divided among the all industries, followed by a seventh with 6% in 2023, where
share was concentrated among top 4 industries.
*/




-- =====================================================
-- 2.5 Country Analysis
-- =====================================================




WITH country_year AS (
	SELECT
		country,
		EXTRACT(YEAR FROM date) AS year,
		SUM(total_laid_off) AS layoffs
	FROM layoffs_staging
		WHERE total_laid_off IS NOT NULL
	GROUP BY country, EXTRACT(YEAR FROM date)
),
lagged AS(
	SELECT 
		country,
		year,
		layoffs,
		LAG(layoffs) OVER(PARTITION BY country ORDER BY year) AS prev_year_layoffs
	FROM country_year
)
	SELECT
		country,
		year,
		layoffs,
		prev_year_layoffs,
		layoffs - prev_year_layoffs AS absolute_change,
		ROUND(100.0 * (layoffs - prev_year_layoffs) / NULLIF(prev_year_layoffs, 0), 2) AS pct_change
	FROM lagged
	ORDER BY country, year;

	
SELECT *
FROM country_tree('2020-01-01', '2024-01-01');

SELECT *
FROM country_tree('2020-01-01', '2021-01-01');

SELECT *
FROM country_tree('2021-01-01', '2022-01-01');

SELECT *
FROM country_tree('2022-01-01', '2023-01-01');

SELECT *
FROM country_tree('2023-01-01', '2024-01-01');

/* Across the observed period, both the magnitude (~67%) and frequency(~63%) of layoffs is concentrated around the 
United States. Despite India having the second largest share of both magnitude and frequency, it only accounts for 9% of all lay 
offs with around 8% share of frequency. Netherlands has the third largest share with only around 4% of layoffs and 0.6% of 
frequency. The rest of 41 countries in the list only account for around 19% of global layoffs and 28% of total events. 
Additionally, the difference among these countries' share is very minimal. The data shows the pattern of heavy top concentration
in one country with close distribution of shares amongst the rest. 

Similar to the whole period observation, in 2020 both magnitude and frequency is lead by the United States(~62% and ~70%) and 
followed by the India(~16% and ~8%), while rest of the countries having low and close share amongst each other. 

2021 shows a small decline of around 2 % in the United States dominance, while a significant increase in India with around 10%
in total layoffs. Still both countries lead the global concentration and the most number of layoff events in the world. 
However, an outlier, China emerged with a single layoff event that accounted for around 11% of layoffs in 2021. Despite being
the third country with the highest share for layoffs in 2021, in all other periods China's share remained very low, with 0 in
2020, and around 1% - 2% in both 2022 and 2023. The rest of the countries followed similar global pattern of low dominance 
in 2021. The pattern of 2021 is also present in the next year with the United States dominance(~66% and ~59%) followed by 
India(~9% and ~7%), while rest having low and close share of layoffs.

2023 the most top concentrated year with the United States having around 71% of layoffs. Another outlier, which is Sweden,
emerged this year with around 7% of total share as the second highest country, with India for the first time not being the second
dominant country in the list. Overall, Sweden expereinced near 0% in 2020, followed by no layoffs in 2021, and around 1% in 
2022. The rest of the countries again showed low and close distribution.

Overall, the YoY analysis of countries show a similar pattern of dominance of one country with around 60% or more, and either
followed by select few and close distribution of rest, or general low and marginal share of rest of countries. 

The United States has dominated with both magnitude and frequency in each of the observed years. Despite its share declining 
around 2% from 2020 to 2021, it followed a positive trend in last two years, which peaked in 2023 with around 71% of total lay
offs. The frequency on the other hand, has had a regular decline from 2020 to 2022, which got reversed from 2022 to 2023 with
around 5% increase. Nevertheless, the United States accounted for the most layoff events in all of the years whit the share of
around 59% - 70%.

India has followed the United States as second dominant country from 2020 to 2021. While having relatively high share in both
2020(~16%) and 2021(~26%), its share of layoffs significantly dropped in 2022(~9%), and followed a negative trend to 2023(~4%),
becoming the 4th country by magnitude. Despite these fluctuations in magnitude, Inidia remained the second country with the
highest frequency in all observed years. The frequency has had an irregular pattern of an increase in one year followed by a
decline in following.


Despite being third country with the highest share, Netherlands had a consistent low level of share, which fluctuated between 
3% - 6% throughout the years, with an exception of no layoffs in 2021. Frequency of the layoffs were even smaller with around 
0.5% in observed years. 


In conclusion, throughout the observed period, layoffs remained geographically concentrated, with the United States consistently
accounting for over 60% of both total layoffs and layoff events, while the remaining countries exhibited comparatively small 
and closely distributed shares.
*/




-- =====================================================
-- 2.6 Overall Analysis of Selected Countries
-- =====================================================




SELECT *
FROM gl_us_ind_tree('2020-01-01', '2024-01-01');


SELECT us_industry, ROUND(100.0 * SUM(us_laid_off) / SUM(global_laid_off), 2)
FROM gl_us_ind_tree('2020-01-01', '2024-01-01')
GROUP BY us_industry
ORDER BY 2 DESC; -- Share of US in global industry layoffs 


SELECT *
FROM gl_us_ind_tree('2020-01-01', '2024-01-01')
ORDER BY ind_laid_off DESC;


SELECT ind_industry, ROUND(100.0 * SUM(ind_laid_off) / SUM(global_laid_off), 2)
FROM gl_us_ind_tree('2020-01-01', '2024-01-01')
GROUP BY ind_industry
ORDER BY 2 DESC; -- Share of India in global industry layoffs 

/* Throughout the whole observed period, Consumer(~15%) and Retail(~13%) industries dominate the magnitude of layoffs in the
United States, followed by Transportation(~8.2%), 'Other'(~7.6%), and Finance(~6.5%). This shows a similar pattern to the global
observation where both Consumer and Retail lead the list, followed by rest of mentioned industries with relatively close 
distribution of share, with an only exception of a switch in the ranking of Transportation(3rd) and 'Other'(4th) in the United
States. 

Findings also indicate that the industries with the highest share in global layoffs are driven by the United States, where
around 84% of global layoffs in Consumer and around 77% in Retail occurred in the United States. The rest of the top global
industries also follow the same pattern, with around 62% of global layoffs in Transportation, 54% in 'Other', and 59% in Finance
occurring in the United States. Notably, out of 30 observed global industries, the United States was responsible for more than
80% of layoffs in 14 industries. Consequently, this proves the geographic influence and concentration of layoffs occurring in
one country. 

As the second highest country in terms of the magnitude of global layoffs, the share of Industries in India is lead by the 
Education with around 28%, followed by Transportation(~13.2%), Food(~11.6%), Finance(~9.2%), and Retail(~8.3%). Unlike the global
and the United States, the share of layoffs is noticeably concentrated in Education, followed by close distribution in the rest
of the industries in India. Additionally, while Consumer and Retail respectively lead the magnitude of the global and the United
States layoffs, they are ranked as sixth(~7.9%) and fifth(~8.3%) based on their share in India. Both Education and Food 
industries, which do not dominate neither global or the United States layoffs, have a strong presence in India, while 
Transportation, Finance, and Retail sharing the top 5 similar to all observations. Moreover, India is responsible for the around
76% of global layoffs in the Education industry.
*/




-- =====================================================
-- 2.6.1 YoY Analysis of Selected Countries
-- =====================================================




SELECT *
FROM gl_us_ind_tree('2020-01-01', '2024-01-01');

SELECT *
FROM gl_us_ind_tree('2020-01-01', '2021-01-01');

SELECT *
FROM gl_us_ind_tree('2021-01-01', '2022-01-01');

SELECT *
FROM gl_us_ind_tree('2022-01-01', '2023-01-01');

SELECT *
FROM gl_us_ind_tree('2023-01-01', '2024-01-01');


/* 
Transportation showed a cyclical pattern throughout the years across all observations, where a year with a dominant share was 
followed by decline in global, the United States, and India. An extreme drop off occurred in 2021 across all observations in
Transportation. Overall, the United States has been the major driver of Transportation, being responsible for around 62% of 
global layoffs. Despite its cyclical pattern, moderate to high level of layoffs throughout the year made Transportation one of
the major global industries which account for the share of layoffs throughout the observed periods.(cyclical trend, US dominant)

Travel industry has experienced an overall negative trend over the years. Despite being the second highest industry for the share
of layofss globlly in 2020, the trajectory of its dominance experienced a decline in following periods, with an extreme of 
recording no layoffs in 2021, and having very low share in last two observed periods across all observations.(declining trend)

Retail on the other hand, has experienced a consistent moderate to high level of dominance across the periods, which was mainly 
lead by the layofss in the United States. Consistent layoffs in the industry has managed to make Retail the second highest 
industry for its share in layoffs. Overall, the United States was responsible for the 77% of global layoffs in Retail. 
Similar pattern is also evident on YoY basis, where the United States consistently drove the layoffs in the industry by 
accounting around 80% - 90% of global layoffs in Retail in two periods.(consistent performer, US dominant)

Finance was another cyclical industry with a year of moderate level of dominance followed by a decline in its share the next 
year. Despite having moderate share of global layoffs, the frequency of the global layoff events mostly occurred in the Finance.
Similar to some other mentioned industries, the United States was also a major contributor of global layoffs in Finance, 
accounting for 59% of global layoffs in the industry. (cyclical trend, US dominant) 

Consumer is one of the most consistent industries in the data. Despite having a low share in 2020, the following years show a
consistent major dominance globally, making it the industry with the highest layoffs across whole observed period. Additionally,
around 84% of global layoffs in the industry occurred in the United States, thus making the country the global driver for layoffs
in the most dominant industry.(consistent, US dominant)

Despite having a moderte share globally, Food industry has had an outlier-driven pattern, where a consistent low - moderate 
share was interrupted by a significant spike in 2021. Overall share of the industry accounts for 6% which makes it a moderate 
industry responsible for the global layoffs. Similar pattern of the United States' dominance is also prevalent in Food industry,
where around 54% of global layoffs in the industry occurred in the United States.(outlier driven, moderate consistent, US dom) 

Education, which is another outlier, was predominantly prevelant in India, accounting for around 28% of layoffs in the country.
Despite industry showing consistent low share globally, 2021 saw a spike in layoffs where around 93% of layoffs was responsible
by the India. Similarly, throughout the whole period, 76% of global layoffs in the industry occurred in India. (outlier driven,
low consistent, India driven)

The distribution of the industries acorss the United States followed similar pattern to global obsevation, where it was either
dominant by one or a select few industries, while rest having close distribution. The United States being the global driver in
layoffs across multiple industries explains the similarity among the global and the United States metrics. India however, showed
more top heavy concentration of industries on YoY basis.
*/




-- =====================================================
-- 2.7 In-Depth Analysis of 2020
-- =====================================================




SELECT *
FROM company_tree('2020-01-01', '2021-01-01');
/* During 2020, Uber laid off the most people, 7525 in total, followed by Booking.com with 4375, and Groupon with 2800. */



SELECT company, total_laid_off, percentage_laid_off, date
FROM layoffs_staging
	WHERE total_laid_off IS NOT NULL
		AND date BETWEEN '2020-01-01' AND '2020-12-31'
		AND company IN ('Uber', 'Groupon', 'Booking.com')
ORDER BY company, date DESC;

/* Despite having the lowest number of layoffs, compared to Uber and Booking.com, Groupon fired 44% of its staff in
2020. Booking.com fired quarter of its employees in 2020, while Uber carried out four layoff rounds in just over a 
month, from 2020-05-06 to 2020-06-12. Uber's first two layoffs accounted for 14% and 13%, while last two 25% and 23%
of the entire staff. */ 



SELECT ROUND(AVG(company_laid_off), 2)
FROM company_tree('2020-01-01', '2021-01-01');

/* The overall average layoff for 2020 is 179, but this metric fails to weigh in big companies, let's create bucket
based on number of layoffs. */



WITH bucket_cte AS( 
	SELECT 
	CASE
		WHEN company_laid_off < 101 THEN '0 - 100'
		WHEN company_laid_off < 501 THEN '101 - 500'
		WHEN company_laid_off < 1000 THEN '501 - 1000'
		ELSE '+1k'
	END AS bucket
	FROM company_tree('2020-01-01', '2021-01-01'))
SELECT bucket, COUNT(bucket)
FROM bucket_cte
GROUP BY bucket
ORDER BY bucket;

/* More than half of the companies in 2020 laid off 0 - 100 employees. Out of curiosity I would like to check the average 
laid off for companies which fired more than 1000 people. */



SELECT ROUND(AVG(company_laid_off), 2)
FROM company_tree('2020-01-01', '2021-01-01')
WHERE company_laid_off > 1000; 

/* The companies which had fired more than thousand people, the average layoff is 2274. */



WITH bucket_cte AS(
	SELECT 
		CASE
			WHEN total_laid_off < 101 THEN '0-100'
			WHEN total_laid_off < 501 THEN '101-500'
			WHEN total_laid_off < 1001 THEN '501-1k'
			ELSE '+1k'
		END AS bucket
	FROM company_full_lay_off_tree('2020-01-01', '2021-01-01')
)
SELECT bucket, COUNT(bucket)
FROM bucket_cte
GROUP BY bucket
ORDER BY bucket;

/* Companies which experienced full layoffs, majority laid off more than 1000 people. */



SELECT  COUNT(DISTINCT company) 
FROM company_at_least_half_lay_off_tree('2020-01-01', '2021-01-01');

SELECT COUNT(DISTINCT company)
FROM company_tree('2020-01-01', '2021-01-01');

/* In 2020 out of 451 companies 79 of them fired at least half of their workforce. */



SELECT *
FROM industry_tree('2020-01-01', '2021-01-01')
ORDER BY total_laid_off DESC
LIMIT 3;

/* The top three industries that laid off the most people in 2020 were Transportation (14,656; 18.09%), Travel (13,983; 17.26%),
and Finance (8,624; 10.65%). 

Transportation and Travel show very similar levels of impact, both in total employees laid off and in scale, with Travel 
recording 44 layoff events, closely matching Transportation in both frequency and magnitude.

Although the Finance industry recorded the highest number of layoff events (64 events, 12.03%), its total number of employees 
laid off was approximately 59% of Transportation’s total, indicating that Finance layoffs were more frequent but significantly
smaller in size per event compared to Transportation and Travel.
*/



SELECT industry, 
		SUM(total_laid_off) industry_sum_total_laid_off_2020,
		ROUND(100 * SUM(total_laid_off)/SUM(SUM(total_laid_off)) OVER(), 2) AS percentage_industry_sum_total_laid_off_2020,
		SUM(SUM(total_laid_off)) OVER() AS total_laid_off_2020,
		COUNT(industry) industry_num_of_layoff_events_2020,
		ROUND(100 * COUNT(industry)/SUM(COUNT(industry)) OVER (), 2) AS percentage_num_of_layoff_events_2020,
		SUM(COUNT(industry)) OVER() AS total_num_of_layoff_events_2020		
FROM layoffs_staging
WHERE date BETWEEN '2020-01-01' AND '2020-12-31'
AND percentage_laid_off >= 0.5
AND total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY industry_sum_total_laid_off_2020 DESC;

/* Among layoff events, where companies fired at least half of their workforce in 2020, the Finance industry accounted for the 
highest impact, with 2,618 employees affected (23.38%) across 6 severe layoff events.

It was followed by the Food industry, with 2,137 employees (19.08%) across 8 events, and the Consumer industry, with 1,336 
employees (11.93%) across 4 events.

This suggests that within high-severity layoffs (≥50% workforce reduction), Finance experienced fewer but relatively 
large-scale events, while Food showed a higher frequency of severe restructuring events.
*/



SELECT *
FROM gl_us_ind_tree('2020-01-01', '2021-01-01');

/* In the United States, a total of 50,385 employees were laid off across 334 layoff events in 2020. Consistent with the global 
trend, the Transportation industry experienced the largest workforce reductions, accounting for 10,262 layoffs (20.37% of all 
ayoffs in the United States).

Retail ranked second with 6,808 layoffs (13.51%), followed by Consumer with 5,482 layoffs (10.88%). While Travel and Finance 
were the second- and third-largest industries globally in terms of employees laid off, they ranked fourth and sixth in the 
United States, with 4,317 (8.57%) and 2,703 (5.36%) layoffs respectively. This suggests that the global prominence of these 
industries was driven in part by layoffs occurring outside the United States.

When measured by the number of layoff events rather than employees affected, the industry rankings differ considerably. 
Marketing recorded the highest number of layoff events (34), followed by Finance (30) and Retail (28). However, despite leading 
in event frequency, Marketing accounted for only 2,439 layoffs (4.84% of the total), indicating that its layoffs were generally 
smaller in scale. In contrast, Retail combined a high number of layoff events with a large number of employees affected, 
making it one of the most impactful industries in the United States during 2020.

Overall, the United States mirrors the global pattern in one key respect: Transportation experienced the largest workforce 
reductions. However, the composition of the remaining top industries differs, highlighting regional variation in how layoffs 
were distributed across sectors during 2020.

India recorded the second-highest number of layoffs globally in 2020, with 12,932 employees affected. Unlike the 
United States, where layoffs were spread across a broader range of industries, layoffs in India were heavily concentrated in 
a small number of sectors.

The Food industry experienced the largest workforce reductions, accounting for 2,770 layoffs (21.42% of all layoffs in India), 
despite recording only four layoff events. Finance followed closely with 2,631 layoffs (20.34%), while Transportation and Travel
accounted for 2,490 (19.25%) and 1,900 (14.69%) layoffs respectively.

Together, Food, Finance, Transportation, and Travel represented nearly 75% of all layoffs in India, indicating a high 
concentration of workforce reductions within a few industries. In comparison, the four largest industries in the United States 
accounted for approximately 53% of layoffs, suggesting that layoffs were distributed across a wider range of sectors.

Transportation stands out as a common pattern across regions. It was the leading industry globally and accounted for a similar 
share of layoffs in both the United States (20.37%) and India (19.25%). However, the composition of the remaining industries 
differs considerably. While Retail and Consumer industries played a major role in the United States, Food and Finance were 
far more prominent in India.

Overall, the findings suggest that although Transportation was consistently affected across countries, the broader distribution 
of layoffs varied significantly by region, reflecting different industry-level impacts during 2020.

The query below consolidates the findings from the global analysis and the country-level analyses for the United States and 
India.


These two countries were selected because they accounted for the largest share of layoffs in 2020, representing 
62.21% and 15.97% of all recorded layoffs respectively. Together, they comprise over 78% of the total layoffs in the dataset,
making them the most impactful regions for further investigation.

Countries with smaller shares, such as the Netherlands (5.68%) and others below 5%, were not analyzed in the same level of 
detail, as the objective of this project is to demonstrate data cleaning, exploratory data analysis, and comparative analytical 
techniquesrather than provide an exhaustive country-by-country study.
*/







