-- =====================================================
-- 3. INDUSTRY EDA
-- =====================================================


-- =====================================================
-- 3.1 Yearly change in industry analysis
-- =====================================================


WITH industry_year AS(
	SELECT
		industry,
		EXTRACT(YEAR FROM date) AS year,
		SUM(total_laid_off) AS layoffs
	FROM layoffs_staging
		WHERE total_laid_off IS NOT NULL
	GROUP BY industry, EXTRACT(YEAR FROM date)
),
lagged AS(
	SELECT 
		industry,
		year,
		layoffs,
		LAG(layoffs) OVER(PARTITION BY industry ORDER BY year) AS prev_year_layoffs
	FROM industry_year
)
	SELECT 
		industry,
		year,
		layoffs,
		prev_year_layoffs,
		layoffs - prev_year_layoffs AS absolute_change,
		ROUND(100.0 * (layoffs - prev_year_layoffs) / NULLIF(prev_year_layoffs, 0), 2) AS pct_change
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

