SELECT *
FROM dbo.jobs_in_data

--Salary trends over time

SELECT work_year, job_title, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY work_year, job_title
ORDER BY work_year, average_salary DESC;

--Salary distribution across job titles

SELECT job_title, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY job_title
ORDER BY average_salary DESC;

--Geographical salary differences

SELECT employee_residence, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY employee_residence
ORDER BY average_salary DESC;

--effect of experience level on salary

SELECT experience_level, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY experience_level
ORDER BY experience_level;

--Impact of employment type on salary

SELECT employment_type, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY employment_type;


--Salary based on Company size

SELECT company_size, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY company_size
ORDER BY average_salary DESC;

--High demand job categories

SELECT job_category, AVG(salary_in_usd) AS average_salary, COUNT(*) AS job_count
FROM dbo.jobs_in_data
GROUP BY job_category
HAVING COUNT(*)>= 50
ORDER BY average_salary DESC;

--Salary Increase by Experience Level

SELECT experience_level,
       AVG(CASE WHEN experience_level = 'Entry-level' THEN salary_in_usd END) AS entry_level_salary,
       AVG(CASE WHEN experience_level = 'Senior' THEN salary_in_usd END) AS senior_level_salary,
       (AVG(CASE WHEN experience_level = 'Senior' THEN salary_in_usd END) - AVG(CASE WHEN experience_level = 'Entry-level' THEN salary_in_usd END)) / AVG(CASE WHEN experience_level = 'Entry-level' THEN salary_in_usd END) * 100 AS salary_increase_percentage
FROM dbo.jobs_in_data
GROUP BY experience_level;

--Countries with high salary discrepancies

SELECT employee_residence, MAX(average_salary) - MIN(average_salary) AS salary_discrepancy
FROM (
    SELECT employee_residence, AVG(salary_in_usd) AS average_salary
    FROM dbo.jobs_in_data
    GROUP BY employee_residence
) AS avg_salary_by_country
GROUP BY employee_residence
ORDER BY salary_discrepancy DESC;

--Companies offering competitive salaries

SELECT company_location, AVG(salary_in_usd) AS average_salary
FROM dbo.jobs_in_data
GROUP BY company_location
HAVING AVG(salary_in_usd) > (SELECT AVG(salary_in_usd) FROM dbo.jobs_in_data)
ORDER BY average_salary DESC;

 --Moving Average Salary


 WITH moving_average AS (
    SELECT job_category,
           work_year,
           AVG(salary_in_usd) OVER (PARTITION BY job_category ORDER BY work_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary
    FROM dbo.jobs_in_data
)
SELECT job_category,
       work_year,
       moving_avg_salary
FROM moving_average;

--High paying job within each category

WITH ranked_jobs AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY job_category ORDER BY salary_in_usd DESC) AS rank_within_category
    FROM dbo.jobs_in_data
)
SELECT job_category, job_title, salary_in_usd
FROM ranked_jobs
WHERE rank_within_category <= 3;

--Seasonal Salary Patterns

WITH monthly_salaries AS (
    SELECT MONTH(work_year) AS month,
           AVG(salary_in_usd) AS avg_salary
    FROM dbo.jobs_in_data
    GROUP BY MONTH(work_year)
)
SELECT month, avg_salary
FROM monthly_salaries
ORDER BY month;

--Job Titles with High Salary Growth

CREATE TABLE #temp_avg_salary_growth_rate (
    job_title VARCHAR(100),
    avg_growth_rate FLOAT
);

-- Insert data into the temporary table
INSERT INTO #temp_avg_salary_growth_rate (job_title, avg_growth_rate)
    SELECT job_title,
           ((MAX(salary_in_usd) / MIN(salary_in_usd)) - 1) * 100 AS avg_growth_rate
    FROM dbo.jobs_in_data
    GROUP BY job_title;

-- Declare and calculate the overall average salary growth rate
DECLARE @overall_avg_growth_rate FLOAT;
SELECT @overall_avg_growth_rate = AVG(avg_growth_rate) FROM #temp_avg_salary_growth_rate;

-- Identify job titles where the growth rate exceeds the overall average
SELECT job_title, avg_growth_rate
FROM #temp_avg_salary_growth_rate
WHERE avg_growth_rate > @overall_avg_growth_rate;