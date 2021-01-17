/*
Student name: Mathaus Vila Nova
LinkedIn: https://www.linkedin.com/in/mathausvilanova/
Course: Udacity SQL Nanodegree Program
*/

/* Introduction */
-- Create a View called “forestation” by joining all three tables - forest_area, land_area and regions in the workspace.
CREATE VIEW forestation AS (
	SELECT
		fa.country_code,
		fa.country_name,
		fa.year,
		fa.forest_area_sqkm,
		((la.total_area_sq_mi)*2.59) AS total_area_sqkm,
		rg1.income_group,
		rg1.region,
		ROUND(CAST(float8 (fa.forest_area_sqkm/((la.total_area_sq_mi*2.59)+0.0010)*100) AS numeric), 4) AS percent_forest_area
	FROM
		forest_area AS fa
		INNER JOIN land_area AS la ON CONCAT(fa.country_code, fa.year) = CONCAT(la.country_code, la.year)
		INNER JOIN regions AS rg1 ON fa.country_code = rg1.country_code
		--INNER JOIN regions AS rg2 ON la.country_code = rg2.country_code
);


/* 1. GLOBAL SITUATION */
-- a. What was the total forest area (in sq km) of the world in 1990?
SELECT
	country_code,
	country_name,
	SUM(forest_area_sqkm) AS total_forest_area_sqkm
FROM forestation
WHERE
	country_code='WLD'
	AND year='1990'
GROUP BY country_code, country_name

-- b. What was the total forest area (in sq km) of the world in 2016??
SELECT
	country_code,
	country_name,
	SUM(forest_area_sqkm) AS total_forest_area_sqkm
FROM forestation
WHERE
	country_code='WLD'
	AND year='2016'
GROUP BY country_code, country_name

-- c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
WITH cte1 AS (
	SELECT
		country_code,
		country_name,
		SUM(forest_area_sqkm) AS total_forest_area_sqkm
	FROM forestation
	WHERE
		country_code='WLD'
		AND year='1990'
	GROUP BY country_code, country_name
),
cte2 AS (
	SELECT
		country_code,
		country_name,
		SUM(forest_area_sqkm) AS total_forest_area_sqkm
	FROM forestation
	WHERE
		country_code='WLD'
		AND year='2016'
	GROUP BY country_code, country_name
)

SELECT
	ct1.country_code,
	ct1.country_name,
	ct1.total_forest_area_sqkm AS forest_area_sqkm_90,
	ct2.total_forest_area_sqkm AS forest_area_sqkm_16,
	ROUND(CAST(float8 (ct2.total_forest_area_sqkm - ct1.total_forest_area_sqkm) AS numeric), 2) AS forest_area_change_sqkm, -- between 2016 and 1990
	ROUND(CAST(float8 ((ct2.total_forest_area_sqkm/ct1.total_forest_area_sqkm)-1)*(100) AS numeric), 2) AS forest_area_change_percent -- between 2016 and 1990
FROM
	cte1 AS ct1
	INNER JOIN cte2 AS ct2 ON ct1.country_code = ct2.country_code

-- d. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
SELECT
	*
FROM (
	SELECT
		country_code,
		country_name,
		ROUND(CAST(float8 SUM(total_area_sqkm) AS numeric), 2) AS total_land_area
	FROM forestation
	WHERE year='2016'
	GROUP BY country_code, country_name
) AS tb1
WHERE
	total_land_area < (
		SELECT
			((t2.total_forest_area_sqkm - t1.total_forest_area_sqkm)*(-1))
		FROM (
			SELECT
				country_code,
				country_name,
				SUM(forest_area_sqkm) AS total_forest_area_sqkm
			FROM forestation
			WHERE
				country_code='WLD'
				AND year='1990'
			GROUP BY country_code, country_name
		) AS t1
			INNER JOIN (
			SELECT
				country_code,
				country_name,
				SUM(forest_area_sqkm) AS total_forest_area_sqkm
			FROM forestation
			WHERE
				country_code='WLD'
				AND year='2016'
			GROUP BY country_code, country_name
		) AS t2 ON t1.country_code = t2.country_code
)
ORDER BY total_land_area DESC
LIMIT 1


/* 2. REGIONAL OUTLOOK */
-- a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
SELECT
	region,
	ROUND(CAST(float8 (SUM(forest_area_sqkm)/SUM(total_area_sqkm))*100 AS numeric), 2) AS percent_forest_area
FROM forestation
WHERE
	year='2016'
	--AND region='World'
GROUP BY region
ORDER BY 2
/*
Comments: uncomment the "AND region='World'" in the WHERE clause will give us the result considering only the World region in 2016.
To check the highest and lowest region, we can run the above query again and order our result (ORDER BY) by ASC to see the lowest and DESC to see the highest.
*/

-- b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
SELECT
	region,
	ROUND(CAST(float8 (SUM(forest_area_sqkm)/SUM(total_area_sqkm))*100 AS numeric), 2) AS percent_forest_area
FROM forestation
WHERE
	year='1990'
	--AND region='World'
GROUP BY region
ORDER BY 2 DESC
/*
Comments: uncomment the "AND region='World'" in the WHERE clause will give us the result considering only the World region in 1990.
To check the highest and lowest region, we can run the above query again and order our result (ORDER BY) by ASC to see the lowest and DESC to see the highest.
*/

-- c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
WITH cte1 AS (
	SELECT
		region,
		ROUND(CAST(float8 (SUM(forest_area_sqkm)/SUM(total_area_sqkm))*100 AS numeric), 2) AS percent_forest_area_16
	FROM forestation
	WHERE
		year='2016'
	GROUP BY region
), cte2 AS (
	SELECT
		region,
		ROUND(CAST(float8 (SUM(forest_area_sqkm)/SUM(total_area_sqkm))*100 AS numeric), 2) AS percent_forest_area_90
	FROM forestation
	WHERE
		year='1990'
	GROUP BY region
)

SELECT
	ct1.region,
	ct2.percent_forest_area_90,
	ct1.percent_forest_area_16,
	CASE
		WHEN percent_forest_area_16 > percent_forest_area_90 THEN 'INCREASED'
		WHEN percent_forest_area_16 < percent_forest_area_90 THEN 'DECREASED'
		ELSE 'SAME'
	END AS comparison_90_16
FROM
	cte1 AS ct1
	INNER JOIN cte2 AS ct2 ON ct1.region = ct2.region
ORDER BY 4


/* 3. COUNTRY-LEVEL DETAIL */
-- a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?
-- b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?
WITH cte1 AS (
	SELECT
		country_code,
		country_name,
		region,
		COALESCE(SUM(forest_area_sqkm), 0.0) AS forest_area_sqkm_90
	FROM forestation
	WHERE
		forest_area_sqkm IS NOT NULL
		AND country_code != 'WLD'
		AND year='1990'
	GROUP BY country_code, country_name, region
), cte2 AS (
	SELECT
		country_code,
		country_name,
		region,
		COALESCE(SUM(forest_area_sqkm), 0.0) AS forest_area_sqkm_16
	FROM forestation
	WHERE
		forest_area_sqkm IS NOT NULL
		AND country_code != 'WLD'
		AND year='2016'
	GROUP BY country_code, country_name, region
)

SELECT
	ct1.country_code,
	ct1.country_name,
	ct1.region,
	ct1.forest_area_sqkm_90,
	ct2.forest_area_sqkm_16,
	CASE
		WHEN ct1.forest_area_sqkm_90 > 0 THEN ROUND(CAST(float8 (ct2.forest_area_sqkm_16-ct1.forest_area_sqkm_90) AS numeric), 2)
		ELSE 0.0
	END AS forest_diff_sqkm,
	CASE
		WHEN ct1.forest_area_sqkm_90 > 0 THEN ROUND(CAST(float8 ((ct2.forest_area_sqkm_16/(ct1.forest_area_sqkm_90+0.001))-1)*100 AS numeric), 2)
		ELSE 0.0
	END AS forest_diff_sqkm_percent
FROM
	cte1 AS ct1
	INNER JOIN cte2 AS ct2 ON CONCAT(ct1.country_code, ct1.country_name) = CONCAT(ct2.country_code, ct2.country_name)
ORDER BY 7
LIMIT 5

/*
Comments: to change between a. and b. question's answer, you must need to change the ORDER BY clause.
ORDER BY 6 ASC if you want to see the largest amount decrease and ORDER BY 7 ASC if you want to see the largest percent decrease.
*/

-- c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
SELECT
	quartile,
	COUNT(1) count_of_countries
FROM (
	SELECT
		CASE
			WHEN percent_forest_area BETWEEN 0 AND 25 THEN '1'
			WHEN percent_forest_area BETWEEN 25 AND 50 THEN '2'
			WHEN percent_forest_area BETWEEN 50 AND 75 THEN '3' 
			ELSE '4'
		END AS quartile
	FROM forestation
	WHERE
		country_code!='WLD'
		AND total_area_sqkm > 0
		AND year='2016'
) AS t1
GROUP BY quartile
ORDER BY 2 DESC

--d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT
	country_name,
	region,
	ROUND(CAST(float8 (percent_forest_area) AS numeric), 2) AS percent_forest_area
FROM forestation
WHERE
	country_code!='WLD'
	AND total_area_sqkm > 0
	AND year='2016'
	AND percent_forest_area > 75
ORDER BY 3 DESC

--e. How many countries had a percent forestation higher than the United States in 2016?
WITH cte AS (
	SELECT
		country_code,
		country_name,
		region,
		year,
		SUM(total_area_sqkm) AS land_area_sqkm,
		SUM(forest_area_sqkm) AS forest_area_sqkm,
		CASE
			WHEN ROUND(CAST(float8 (SUM(forest_area_sqkm)/(SUM(total_area_sqkm)+0.0001))*100 AS numeric), 2) > 100 THEN CAST(100 AS float)
			ELSE ROUND(CAST(float8 (SUM(forest_area_sqkm)/(SUM(total_area_sqkm)+0.0001))*100 AS numeric), 2)
		END AS forest_percent_area
	FROM forestation
	WHERE
		forest_area_sqkm IS NOT NULL
		AND country_code != 'WLD'
		AND year='2016'
	GROUP BY country_code, country_name, year, region
)

SELECT
	COUNT(1) AS count_of_countries
FROM cte
WHERE
	forest_percent_area > (
			SELECT
				forest_percent_area
			FROM cte
			WHERE
			country_code='USA'
			AND year='2016')
