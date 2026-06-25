-- =====================================================
-- 7. In-Depth Analysis of 2020
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
