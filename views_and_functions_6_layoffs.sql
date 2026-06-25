-- =====================================================
-- 7. VIEWS AND FUNCTIONS
-- =====================================================


-- =====================================================
-- 7.1 YoY Industry Rank View
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
-- 7.1 YoY industry Snapshot view
-- =====================================================


CREATE VIEW vw_industry AS
SELECT * 
FROM industry_tree ('2020-01-01', '2024-01-01');


-- =====================================================
-- 7.2 Company Share Analysis Function
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


-- =====================================================
-- 7.3 Industry Share Analysis Function
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
-- 7.4 Country Share Analysis Function
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
-- 7.5 Selected Countries' Share Analysis Function
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