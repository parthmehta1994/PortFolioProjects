USE covid

--(1) --------------------------------------------------------- Total no. of Rows --------------------------------------------------------------------------------------


SELECT COUNT(*) as Total_Rows
FROM covid..covidcases$


--(2) --------------------------------------------------------- Total no. of Columns --------------------------------------------------------------------------------------

SELECT COUNT(*) AS Total_Columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'covidcases$';

-- --------------------------------------------------- Checking for Distinct Location, Continent and Population --------------------------------------------------------------------------------------
--(3) ------------------------------------------------Maximum Population Per COuntry-----------------------------------------------------------------

SELECT DISTINCT covidcases$.location, MAX(CAST(population as bigint)) as Total_Population_Per_Country
FROM covid..covidcases$
WHERE continent is not null
GROUP BY location
ORDER BY location

--(4) --------------------------------------------------- Death Percentage per total cases --------------------------------------------------------------------------------------
-- --------------------------Shows how many people died who contracted covid in the United States-------------------------------------------------------------------


SELECT location,date,total_cases, new_cases, cast(total_deaths as int) as total_deaths, cast(population as bigint) as Population, 
round(cast(((total_deaths/nullif(total_cases,0))*100) as float),2) as Death_Percent  
FROM covid..covidcases$ as c
WHERE location like '%states'
ORDER BY location,date,Death_Percent;

--(5) --------------------------------------------------- Total cases per popluation in US  --------------------------------------------------------------------------------------
-- --------------------------Shows how many people contracted covid in the United States-------------------------------------------------------------------

SELECT location,date,cast(total_cases as int) as total_cases, new_cases, total_deaths, cast(population as bigint) as Population, round(cast(((total_cases/population)*100) as float),2) as Infection_Rate
FROM covid..covidcases$ as c
WHERE location like '%states'
ORDER BY location,date, Infection_Rate;

-- --------------------------------------------------- Highest infection relative to population  --------------------------------------------------------------------------------------

--(6) ---------------------------------------Shows the countries with the highest infection rate in a descing order --------------------------------------------

SELECT location,SUM(cast(new_cases as bigint)) as Total_Cases, max(cast(population as bigint)) as Total_Population,ROUND((SUM(cast(new_cases as float)) / MAX(cast(population as float))) * 100, 2) as Infection_Rate
FROM covid..covidcases$
group by location
order by Infection_Rate desc

-- --------------------------------------------------- Highest death count/rate relative to population  --------------------------------------------------------------------------------------

--(7) ---------------------------------------------Shows the countries with the highest death count in a descing order --------------------------------------------

SELECT location, max(cast(total_deaths as int)) as max_deaths, max(cast(population as bigint)) as max_populaion, round(max(cast(((total_deaths/population)*100) as float)),2) as Death_Rate
FROM covid..covidcases$
WHERE continent is not null
group by location
order by Death_Rate desc;

--(8) ---------------------------------------------Comparing if there are duplicate records in continent and location--------------------------------
WITH Deaths_Per_Continent_Not_Null AS
(
SELECT continent, sum(cast(new_deaths as bigint)) as Total_Deaths_per_Continent
FROM covid..covidcases$
where continent is not null
group by continent  -- We come to know aafter the query that there is a continent which is null lets solve for that and see what is it
),
Deaths_Per_Continent_Null AS
(
SELECT continent, location, sum(cast(new_deaths as bigint)) as Total_Deaths_per_Continent
FROM covid..covidcases$
WHERE continent is NULL or continent like ''
group by continent, location
)
SELECT DPCNN.continent, DPCN.location,DPCNN.Total_Deaths_per_Continent,DPCN.Total_Deaths_per_Continent, (DPCNN.Total_Deaths_per_Continent - DPCN.Total_Deaths_per_Continent) AS Diff
FROM Deaths_Per_Continent_Null AS DPCN
INNER JOIN Deaths_Per_Continent_Not_Null AS DPCNN
	ON DPCN.location = DPCNN.continent
ORDER BY DPCN.continent;

-- From the above query and output we can see that thera are 6 duplicate records of continent name in location column which needs to be removed

--Checking to see if there are any more duplicates betwixt the 2 columns

SELECT column_name AS Duplicate_Column, COUNT(*) AS No_Of_Dup
FROM
(SELECT DISTINCT continent AS column_name FROM covid..covidcases$
UNION ALL
SELECT DISTINCT location AS column_name FROM covid..covidcases$) AS Combine_Names
GROUP BY column_name
HAVING COUNT(*) > 1;

-- Removing records of the location which overlap the continent

DELETE FROM covid..covidcases$
WHERE location in (
	SELECT continent 
	FROM covid..covidcases$
	WHERE continent is not null
	)
	
-- After removing duplicate records go back to check if there exist any duplicates by running the query above

--(9) ------------------------------------------------------Max Deaths per Continent----------------------------------------------------------------
------------- Showing Continents with the highest death count, highest cases when compared to population -------------------------------------------
-- We use a subqueries for this since we first have to get the maximum total deaths per country and then perform a sum of the output column------------
-- 9a

SELECT continent, sum(max_deaths_per_country) as total_max_deaths_per_continent
FROM (SELECT continent, location, max(cast(total_deaths as bigint)) as max_deaths_per_country
FROM covid..covidcases$
where continent is not null
group by continent,location
) as max_deaths_per_country_per_continent
where continent is not null
group by continent

-- This is another way to perform the above calculation without having to use subquery since it uses sum function to calculate cululative new cases
-- 9b
SELECT continent, sum(cast(new_deaths as bigint)) as max_deaths_per_continent
FROM covid..covidcases$
where continent is not null
group by continent;

-- Having a differnece column for the above 2 queries
WITH total_deaths_calc AS
(
SELECT continent, sum(max_deaths_per_country) as total_max_deaths_per_continent_9a
FROM (SELECT continent, location, max(cast(total_deaths as bigint)) as max_deaths_per_country
FROM covid..covidcases$
where continent is not null
group by continent,location
) as max_deaths_per_country_per_continent
where continent is not null
group by continent
),
new_deaths_calc AS
(
SELECT continent, sum(cast(new_deaths as bigint)) as max_deaths_per_continent_9b
FROM covid..covidcases$
where continent is not null
group by continent
)
SELECT tdc.continent, tdc.total_max_deaths_per_continent_9a, ndc.max_deaths_per_continent_9b,(tdc.total_max_deaths_per_continent_9a-ndc.max_deaths_per_continent_9b) as diff
FROM total_deaths_calc as tdc
JOIN new_deaths_calc as ndc ON
	tdc.continent = ndc.continent
order by tdc.continent

/*From the above result we see that North America winesses a higher total deaths when calculated using maximum total deaths as compared to summing up
 new cases. We have to dig up why is this the case */                                                                                    

 -- Getting the earliest and latest date of the dataset
 SELECT min(date) as earliest_date, max(date) as latest_date
 FROM covid..covidcases$

 SELECT distinct continent, location, sum(cast(new_deaths as int)) as sum_of_new_deaths, max(cast(total_deaths as int)) as max_of_total_deaths,
 (sum(cast(new_deaths as int)) - max(cast(total_deaths as int))) as differnece
 FROM covid..covidcases$
 WHERE continent like 'North%'
 group by continent, location

-- From the above query we come to know that US has a data discrepamcy. Digging in more

 SELECT continent, location, sum(cast(new_deaths as bigint)) as sum_of_new_deaths, max(cast(total_deaths as bigint)) as max_of_total_deaths,
 (sum(cast(new_deaths as bigint)) - max(cast(total_deaths as bigint))) as differnece
 FROM covid..covidcases$
 WHERE continent like 'North%' AND location like '%States'
 group by continent, location

 --SELECT date,location, total_deaths, new_deaths, SUM(new_deaths) OVER (PARTITION BY location order by date, location) as Cumulative_Deaths 
 --FROM covid..covidcases$
 --WHERE continent is not null AND location like '%States'

 -- Checking the US Total Deaths VS SUm of New Deaths. From this we can see that the total deaths rows are wrong. It is better to stick to sun of all the new deaths

WITH DeathsData AS (
    SELECT 
        date,
        location,
        total_deaths,
        new_deaths,
        SUM(new_deaths) OVER (PARTITION BY location ORDER BY date) AS Cumulative_Deaths
    FROM 
        covid..covidcases$
    WHERE 
        continent IS NOT NULL AND
        location LIKE '%States'
)

SELECT 
    *,
    (Cumulative_Deaths - total_deaths) AS Difference
FROM 
    DeathsData
WHERE 
    (Cumulative_Deaths - total_deaths) != 0
ORDER BY 
    date, 
    location;


 -- We leave this for further questioning as its still unclear

 -- (10) Global Numbers ----------------------------- Death Percentage per cases GLobally-------------------------------------------------------------------

 SELECT sum(cast(new_cases as bigint)) as Global_Cases, sum(cast(new_deaths as bigint)) as Global_Deaths, round(sum(new_deaths)/sum(new_cases)*100,2) 
 FROM covid..covidcases$
 WHERE continent is not null

 -- (11) --------------------------------------------Total Populations Vs Vaccinations---------------------------------------------------------------

 SELECT *
 FROM covid..covidcases$
 ORDER BY location,date
 SELECT *
 FROM covid..covidvaccinations$
 order by location, date

 -- AS we can see from the above 2 queries the two tables can be joined and uniqely identified based on a combination of 2 columns ie a composite key
 -- Date and Location is the composite key
-- Joining the 2 tables based on that


With PopVSVac (date, continent, location, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT c.date,c.continent, c.location, c.population, cast(v.new_vaccinations as bigint), SUM(cast(v.new_vaccinations as bigint)) OVER (PARTITION BY c.location order by c.location, c.date) as RollingPeopleVaccinated
FROM covid..covidcases$ as c
JOIN covid..covidvaccinations$ as v ON
	C.date = V.date AND c.location = v.location
WHERE c.continent is not null
)

SELECT *, round((RollingPeopleVaccinated/population)*100,2) AS VaccinePercent
FROM PopVSVac