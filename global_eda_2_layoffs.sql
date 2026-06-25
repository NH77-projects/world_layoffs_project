-- ===========================================
-- 3. GLOBAL EDA
-- ===========================================


-- ===========================================
-- 3.1 Global Year-over-Year(YoY) overview
-- ===========================================

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


-- ===========================================
-- 3.2 YoY averages
-- ===========================================


SELECT 
	EXTRACT(YEAR FROM date) AS year,
	SUM(total_laid_off) AS layoffs,
	SUM(total_laid_off) / 12 AS monthly_avg_layoffs,
	ROUND(SUM(SUM(total_laid_off)) OVER() / 4, 2) AS total_avg_layoffs
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL
AND date IS NOT NULL
GROUP BY year
ORDER BY year; -- AVG layoffs per each year, and total avg layoffs
