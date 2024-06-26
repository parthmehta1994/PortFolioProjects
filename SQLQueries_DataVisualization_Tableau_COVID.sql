-- (1) Global Numbers ----------------------------- Death Percentage per cases GLobally-------------------------------------------------------------------

 SELECT sum(cast(new_cases as bigint)) as Global_Cases, sum(cast(new_deaths as bigint)) as Global_Deaths, round(sum(new_deaths)/sum(new_cases)*100,2) 
 FROM covid..covidcases$
 WHERE continent is not null

 --(2) ------------------------------------------Death Count Per Continent --------------------------------------------------------------------------

SELECT continent, sum(cast(new_deaths as bigint)) as max_deaths_per_continent
FROM covid..covidcases$
where continent is not null
group by continent;

--(3) ------------------------------------------ Indection Rate Per Country -----------------------------------------------------------------------

SELECT location,SUM(cast(new_cases as bigint)) as Total_Cases, max(cast(population as bigint)) as Total_Population,ROUND((SUM(cast(new_cases as float)) / MAX(cast(population as float))) * 100, 2) as Infection_Rate
FROM covid..covidcases$
WHERE continent is not null
group by location
order by Infection_Rate desc;

-- (4) ------------------------------------------ Infection Rate Per Country chronologically on each day -------------------------------------------

SELECT location, date, population, MAX(total_cases) as Total_Cases, round(max((total_cases/population))*100,2) as PercentPopulationInfected
FROM covid..covidcases$
WHERE continent is not null
group by location, population, date
order by location, date 

--(5) -------------------------------------------- Death COunt per country -------------------------------------------------------------------------

SELECT location, sum(cast(new_deaths as bigint)) as Total_Deaths
FROM covid..covidcases$
where continent is not null
group by location
order by Total_Deaths
