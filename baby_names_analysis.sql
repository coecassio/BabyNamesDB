USE baby_names_db; -- select the schema 

-- Dataset Exploration:
SELECT * FROM regions;

SELECT Region, COUNT(State) AS state_count
FROM regions
GROUP BY Region;

SELECT COUNT(DISTINCT State) as states
FROM names;

SELECT DISTINCT
	n.State AS names_state, 
    r.State AS regions_state, 
    r.Region
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State;

/* Note: It seems there are two problems in the 
regions fact table:
1. New Hampshire's state was registered 
as "New England", instead of "New_England"
2. Michigan (MI) is missing from the regions
table, that only has 50 entries because DC
is included*/

/* Note: In order to fix the regions table,
another script called "baby_names_regions_fix.sql"
was created and executed. */

/* Note: If updating/inserting wasn't a valid option 
due to lack of permitions, another solution would be 
using a CTE before queries using Region to generate a 
clean table, such as:

WITH regions_fix AS (
SELECT 
	State,
    CASE WHEN Region = "New England" THEN "New_England" ELSE Region END AS Region
FROM regions
UNION
SELECT 
	"MI" AS State,
    "Midwest" AS Region
)
*/

SELECT COUNT(*) FROM names; 

SELECT MIN(Year) AS min_year, MAX(Year) AS max_year
FROM names;

/* Note: The table has 2.212.361 name records from the 
period between 1980 and 2009 (inclusive) */


-- 1. Tracking Changes in Name Popularity:
/* Objective: Find the orverall most popular girl and boy names and show 
how they have changed in popularity rankings over the years */

SELECT 
	Name, 
	SUM(Births) AS total_births
FROM names
WHERE Gender = "F"
GROUP BY Name
ORDER BY 2 DESC
LIMIT 1; -- Most popular girl name is Jessica


WITH girl_ranking AS (
SELECT 
	Year,
    Name,
    RANK()
		OVER (
			PARTITION BY Year 
            ORDER BY SUM(Births) DESC
		) AS name_ranking  
FROM names
WHERE Gender = "F"
GROUP BY 1, 2
)
SELECT Year, name_ranking
FROM girl_ranking
WHERE Name = "Jessica";

/* Note: While unsing RANK() allows value ties, those 
still count towards the next number in the order. 
(alternatives being ROW_NUMBER() and DENSE_RANK()) */

/* Note: It seems the name was consistently in the 
top 3 from 1990 to 1997, when it started falling 
out of favour,ranking 78 in 2009. */

SELECT 
	Name, 
	SUM(Births) AS total_births
FROM names
WHERE Gender = "M"
GROUP BY Name
ORDER BY 2 DESC
LIMIT 1; -- Most popular boy name is Michael

WITH boy_ranking AS (
SELECT 
	Year,
    Name,
    RANK()
		OVER (
			PARTITION BY Year 
            ORDER BY SUM(Births) DESC
		) AS name_ranking  
FROM names
WHERE Gender = "M"
GROUP BY 1, 2
)
SELECT Year, name_ranking
FROM boy_ranking
WHERE Name = "Michael"; 

/* Note: Michael ranked 1st from 1980 until 1998, 
2nd from 1999 until 2008, and only dropped to 3rd in 2009. */

/* Objective: Find the names with the biggest jumps in popularity 
from the first year of the data set to the last year */

-- If we evaluate by the total difference in babies named:
WITH last_year AS (
	SELECT 
		Name, 
		SUM(Births) as births_2009
	FROM names
	WHERE Year = 2009
	GROUP BY Name
),
first_year AS (
	SELECT 
		Name, 
		SUM(Births) as births_1980
	FROM names
	WHERE Year = 1980
	GROUP BY Name
)
SELECT 
	last_year.Name, 
	births_2009-births_1980 As birth_diff
FROM last_year
	LEFT JOIN  first_year -- Since the objective only states popularity increases
		ON last_year.Name = first_year.Name
 ORDER BY 2 DESC
 LIMIT 10; 
 
 /*Note: The top 5 names with the biggest jumps in popularity were: 
1. Isabella, 2. Ethan, 3. Emma, 4. Noah and 5. Sophia */
           
-- If we evaluate by ranking variation:
WITH last_year AS (
	SELECT 
		Name, 
		RANK()
			OVER (
				PARTITION BY Year
				ORDER BY SUM(Births) DESC
			) AS rank_2009
	FROM names
	WHERE Year = 2009
	GROUP BY Name
),
first_year AS (
	SELECT 
		Name, 
		RANK()
			OVER (
				PARTITION BY Year
                ORDER BY SUM(Births) DESC
			) AS rank_1980
	FROM names
	WHERE Year = 1980
	GROUP BY Name
)
SELECT 
	last_year.Name,
    first_year.rank_1980,
	last_year.rank_2009,
	CAST(rank_1980 AS SIGNED) - CAST(rank_2009 AS SIGNED) AS rank_increase
FROM last_year
	JOIN  first_year -- Inner join since we're comparing rankings in both periods
		ON last_year.Name = first_year.Name
 ORDER BY rank_increase DESC
 LIMIT 10; 
 
 /* Note: The top 5 names with the biggest jumps in popularity were: 
1. Aidan, 2. Colton, 3. Skylar, 4. Rylan and 5. Aliyah.
It's important to note that all top 5 names were tied in 
the 1980 ranking, meaning we would likely get different 
results had we used ROW_NUMBER() instead of RANK()*/

-- 2. Compare Popularity Across Decades:
/* Objetive: For each year, return the 3 most popular girl 
names and 3 most popular boy names */

-- Matrix/Pivot Table solution:
WITH name_ranking AS (
SELECT
	Year,
    Gender,
    Name,
    RANK()
		OVER (
			PARTITION BY Year, Gender
            ORDER BY SUM(Births) DESC
        ) AS name_rank
FROM names
GROUP BY 1,2,3
)
SELECT
	Year,
    MIN(CASE WHEN Gender = "F" AND name_rank = 1 THEN Name ELSE NULL END) AS girl_1st,
    MIN(CASE WHEN Gender = "F" AND name_rank = 2 THEN Name ELSE NULL END) AS girl_2nd,
    MIN(CASE WHEN Gender = "F" AND name_rank = 3 THEN Name ELSE NULL END) AS girl_3rd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 1 THEN Name ELSE NULL END) AS boy_1st,
    MIN(CASE WHEN Gender = "M" AND name_rank = 2 THEN Name ELSE NULL END) AS boy_2nd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 3 THEN Name ELSE NULL END) AS boy_3rd
FROM name_ranking
GROUP BY 1;

-- Table solution:
SELECT *
FROM (
SELECT
	Year,
    Gender,
    Name,
    RANK()
		OVER (
			PARTITION BY Year, Gender
            ORDER BY SUM(Births) DESC
        ) AS name_rank
FROM names
GROUP BY 1,2,3
) name_ranking
WHERE name_rank < 4;

/* Objective: For each decade, return the 3 most popular girl 
names and 3 most popular boy names */

-- Matrix/Pivot Table solution:
WITH decade_births AS (
SELECT
	(CASE 
		WHEN Year BETWEEN 1980 AND 1989 THEN "1980s" 
        WHEN Year BETWEEN 1990 AND 1999 THEN "1990s"
        WHEN Year BETWEEN 2000 AND 2009 THEN "2000s"
        ELSE NULL END
        ) AS decade,
	Year,
    Gender,
    Name,
    Births
FROM names),
decade_ranks AS (
SELECT
	decade,
    Gender,
    Name,
    RANK()
		OVER(
			PARTITION BY decade, Gender
            ORDER BY SUM(Births) DESC
        ) AS name_rank
FROM decade_births
GROUP BY 1,2,3)
SELECT
	decade,
    MIN(CASE WHEN Gender = "F" AND name_rank = 1 THEN Name ELSE NULL END) AS girl_1st,
    MIN(CASE WHEN Gender = "F" AND name_rank = 2 THEN Name ELSE NULL END) AS girl_2nd,
    MIN(CASE WHEN Gender = "F" AND name_rank = 3 THEN Name ELSE NULL END) AS girl_3rd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 1 THEN Name ELSE NULL END) AS boy_1st,
    MIN(CASE WHEN Gender = "M" AND name_rank = 2 THEN Name ELSE NULL END) AS boy_2nd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 3 THEN Name ELSE NULL END) AS boy_3rd
FROM decade_ranks
GROUP BY 1;

-- Table solution:
WITH decade_births AS (
SELECT
	(CASE 
		WHEN Year BETWEEN 1980 AND 1989 THEN "1980s" 
        WHEN Year BETWEEN 1990 AND 1999 THEN "1990s"
        WHEN Year BETWEEN 2000 AND 2009 THEN "2000s"
        ELSE NULL END
        ) AS decade,
	Year,
    Gender,
    Name,
    Births
FROM names),
decade_ranks AS (
SELECT
	decade,
    Gender,
    Name,
    RANK()
		OVER(
			PARTITION BY decade, Gender
            ORDER BY SUM(Births) DESC
        ) AS name_rank
FROM decade_births
GROUP BY 1,2,3)
SELECT *
FROM decade_ranks
WHERE name_rank < 4;

-- 3. Compare Popularity Across Decades:
/* Objective: Return the number of babies born in each of the six regions */

-- If we want total births in the period:
SELECT 
	r.Region, 
    SUM(n.Births) AS total_births
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State
GROUP BY 1;

-- If we want births per year (Matrix/Pivot Table):
SELECT 
	n.Year, 
    SUM(CASE WHEN r.Region = "Pacific" THEN n.Births ELSE NULL END) AS pacific_births,
    SUM(CASE WHEN r.Region = "South" THEN n.Births ELSE NULL END) AS south_births,
    SUM(CASE WHEN r.Region = "Mountain" THEN n.Births ELSE NULL END) AS mountain_births,
    SUM(CASE WHEN r.Region = "New_England" THEN n.Births ELSE NULL END) AS new_england_births,
    SUM(CASE WHEN r.Region = "Mid_Atlantic" THEN n.Births ELSE NULL END) AS mid_atlantic_births,
    SUM(CASE WHEN r.Region = "Midwest" THEN n.Births ELSE NULL END) AS midwest_births
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State
GROUP BY 1;

-- If we want births per year (Table):
SELECT 
	n.Year, 
	r.Region,
    SUM( n.Births) AS total_births
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State
GROUP BY 1, 2
ORDER BY 1, 2;


/* Objective: Return the 3 most popular girl names and 3 most popular boy names within each region */


-- Matrix/Pivot Table solution:
WITH name_ranking AS (
SELECT
	r.Region,
    n.Gender,
	n.Name,
	RANK()
		OVER (
			PARTITION BY r.Region, n.Gender
            ORDER BY SUM(n.Births) DESC
        ) AS name_rank
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State
GROUP BY 1, 2, 3)
SELECT
	Region,
    MIN(CASE WHEN Gender ="F" AND name_rank = 1 THEN Name ELSE NULL END) AS girl_1st,
	MIN(CASE WHEN Gender = "F" AND name_rank = 2 THEN Name ELSE NULL END) AS girl_2nd,
    MIN(CASE WHEN Gender = "F" AND name_rank = 3 THEN Name ELSE NULL END) AS girl_3rd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 1 THEN Name ELSE NULL END) AS boy_1st,
    MIN(CASE WHEN Gender = "M" AND name_rank = 2 THEN Name ELSE NULL END) AS boy_2nd,
    MIN(CASE WHEN Gender = "M" AND name_rank = 3 THEN Name ELSE NULL END) AS boy_3rd
FROM name_ranking
GROUP BY 1;

-- Table solution:
SELECT * 
FROM (
SELECT
	r.Region,
    n.Gender,
	n.Name,
	RANK()
		OVER (
			PARTITION BY r.Region, n.Gender
            ORDER BY SUM(n.Births) DESC
        ) AS name_rank
FROM names n 
	LEFT JOIN regions r 
		ON n.State = r.State
GROUP BY 1, 2, 3) name_ranking
WHERE name_rank < 4;

-- 4. Explore Unique Names in the Dataset:
/* Objective: Find the 10 most popular androgynous names 
(names given to both females and males) */

SELECT
	Name,
    COUNT(DISTINCT Gender) AS gender_count,
    SUM(Births) AS total_births
FROM names
GROUP BY 1
HAVING gender_count = 2
ORDER BY 3 DESC
LIMIT 10;

/* Objective: Find the length of the shortest and longest names, 
and identify the most popular short and long names */

-- Shortest names:
WITH name_length AS (
SELECT DISTINCT
	Name,
    length(Name) AS name_length
FROM names
ORDER BY 2 -- The shortest names have 2 characters
)
SELECT 
	l.Name, 
	l.name_length,
    SUM(n.Births) AS total_births
FROM name_length l 
	LEFT JOIN names n 
		ON l.Name = n.Name
WHERE l.name_length = 2
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1; -- Ty

-- Longest names:
WITH name_length AS (
SELECT DISTINCT
	Name,
    length(Name) AS name_length
FROM names
ORDER BY 2 DESC -- The longest names have 15 characters
)
SELECT 
	l.Name, 
	l.name_length,
    SUM(n.Births) AS total_births
FROM name_length l 
	LEFT JOIN names n 
		ON l.Name = n.Name
WHERE l.name_length = 15
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1; -- Franciscojavier

/* Objective: The founder of Maven Analytics is named Chris.
Find the state with the highest percent of babies named "Chris" */
WITH chris_amount AS (
SELECT
	State,
    SUM(Births) AS chris_births
FROM names
WHERE Name = "Chris"
GROUP BY State
)
SELECT
	n.State,
    ca.chris_births,
    SUM(n.Births) AS total_births,
    100*ca.chris_births/SUM(n.Births) AS chris_percentage
FROM names n
	LEFT JOIN chris_amount ca 
		ON n.State = ca.State
GROUP BY 1, 2
ORDER BY 4 DESC;