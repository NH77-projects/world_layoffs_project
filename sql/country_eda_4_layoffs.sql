-- =====================================================
-- 4. COUNTRY EDA
-- =====================================================


-- =====================================================
-- 4.1 Country YoY Analysis
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
United States. Despite India having the second largest share of both magnitude and frequency, it only accounts for 9% of all 
layoffs with around 8% share of frequency. Netherlands has the third largest share with only around 4% of layoffs and 0.6% of 
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
dominant country in the list. Overall, Sweden experienced near 0% in 2020, followed by no layoffs in 2021, and around 1% in 
2022. The rest of the countries again showed low and close distribution.

Overall, the YoY analysis of countries show a similar pattern of dominance of one country with around 60% or more, and either
followed by select few and close distribution of rest, or general low and marginal share of rest of countries. 

The United States has dominated with both magnitude and frequency in each of the observed years. Despite its share declining 
around 2% from 2020 to 2021, it followed a positive trend in last two years, which peaked in 2023 with around 71% of total lay
offs. The frequency on the other hand, has had a regular decline from 2020 to 2022, which got reversed from 2022 to 2023 with
around 5% increase. Nevertheless, the United States accounted for the most layoff events in all of the years with the share of
around 59% - 70%.

India has followed the United States as second dominant country from 2020 to 2021. While having relatively high share in both
2020(~16%) and 2021(~26%), its share of layoffs significantly dropped in 2022(~9%), and followed a negative trend to 2023(~4%),
becoming the 4th country by magnitude. Despite these fluctuations in magnitude, India remained the second country with the
highest frequency in all observed years. The frequency has had an irregular pattern of an increase in one year followed by a
decline in following.


Despite being third country with the highest share, Netherlands had a consistent low level of share, which fluctuated between 
3% - 6% throughout the years, with an exception of no layoffs in 2021. Frequency of the layoffs were even smaller with around 
0.5% in observed years. 


In conclusion, throughout the observed period, layoffs remained geographically concentrated, with the United States consistently
accounting for over 60% of both total layoffs and layoff events, while the remaining countries exhibited comparatively small 
and closely distributed shares.
*/
