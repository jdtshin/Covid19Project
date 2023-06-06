
--Query 1: Checking to ensure that the CovidDeaths dataset was properly imported into SQL Server.
SELECT *
FROM CovidPortfolioProject..CovidDeaths
ORDER BY location, date


--Query 2: Using a formula to determine the Covid-19 fatality rate (or death percentage).
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states%' and continent is not null
ORDER BY location, date


--Query 3: Using a formula to determine the infection rate for the United States (wildcard notation also includes the Virgin Islands into the query result).
SELECT location, date, total_cases, population, (total_cases/population)*100 AS percent_population_infected
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states%' and continent is not null
ORDER BY location, date


--Query 4: Using the MAX() function to determine which location had the highest number of total cases, as well as the highest infection rate. 
--The WHERE clause was used to exclude observations that did not include a continent, such as World, Asia, Higher Income, etc.
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_population_infected
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY percent_population_infected DESC


--Query 5: Using the MAX() function to determine the location with the highest death count.
SELECT location, MAX(total_deaths) AS total_death_count
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC


--Query 6: Using the MAX() function to determine the continent with the highest death count. Same as Query 5, just switched out location with continent.
SELECT continent, MAX(total_deaths) AS total_death_count
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC


--Query 7: Using the SUM() function to determine the number of all the Covid-19 new cases and new deaths, then calculating the death rate for the new cases.
SELECT SUM(new_cases) AS sum_of_new_cases, SUM(new_deaths) AS sum_of_new_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS new_death_percentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null AND new_cases != 0
ORDER BY 1, 2


--Query 8: Joining the CovidDeath and CovidVaccination tables on location and date. Using the OVER and PARTITION BY clause to divide the result set for new vaccinations by location, thus creating a continuous count of the number of new vaccinations based order by location and date.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

----NOTE: (OVER clause): The OVER clause combined with the PARTITION BY clause is used to break up data into partitions.
----NOTE: (PARTITION BY clause): The PARTITION BY clause is a subclause of the OVER clause. The PARTITION BY clause divides a query's result set into partitions, where the window function is operated on each partition separately and recalculates for each partition.
----NOTE: (PARTITION BY vs. GROUP BY): The GROUP BY clause is often used in conjunction with an aggregate function (SUM, AVG, COUNT, MAX, MIN, etc.). The GROUP BY clause reduces the number of rows returned by rolling them up and calculating the aggregate function for each group.
----NOTE: (PARTITION BY vs. GROUP BY): The PARTITION BY clause divides the result set into partitions and changes how the window function is calculated. The PARTITION BY clause does not reduce the number of rows returned.
----NOTE: In simple words, the GROUP BY clause is aggregate, and the PARTITION BY clause is analytic.


--Query 9: Creating a CTE (Common Table Expression)
--CTE named PopvsVac is created with the columns of continent, location, date, population, new_vaccinations, and rolling_count _of_vaccinations.
--The inner SQL query is the same as Query 8, which was used to determine the rolling count (SUM) of the number of vaccinations for each location, using the OVER and PARTITION BY clauses.
--The CTE is then called below, where all the data is selected, as well as the percentage of the population that has been vaccinated.
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_count_of_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (rolling_count_of_vaccinations/population)*100
FROM PopvsVac

----NOTE: A Common Table Expression, or CTE, is a temporary result set that you can reference within another SELECT, INSERT, UPDATE, or DELETE statement. CTEs are used to simplify queries.


--Query 10: Creating a TEMP TABLE
--Created a temp table called #PercentPopulationVaccinated, then inserted data from query 8 (rolling count of vaccinations by location) into the temporary table.
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_count_of_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

--Selects all the data, as well as the percentage of the population that has been vaccinated by location.
SELECT *, (rolling_count_of_vaccinations/population)*100
FROM #PercentPopulationVaccinated


----NOTE: A temporary table (aka temp table) is a table that is created and used within the context of a specific session in a dbms. It is designed to store temporary data that is needed for a short duration and does not require a permanent storage solution.
----NOTE: Temp Tables are created on-the-fly and are typically used to perform complex calculations, store intermediate results, or manipulate subsets of data during the execution of a query or a series of queries.
----NOTE: Temp Tables are only accessible within the session that created them and are automatically dropped or deleted when the session ends or when it is dropped by the user.


--Query 11: Creating a SQL VIEW for the percentage of the population that has been vaccinated by location (query 8)
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated

----NOTE: SQL Views are virtual tables whose contents are defined by a query. Views contain rows and columns like a normal table. SQL Views do not exist as a stored set of data values in a database. 
----NOTE: Views act as a filter on the underlying tables referenced in the view. The query that defines the view can be from one or more tables or from other views in the curernt or other databases.
----NOTE: Views are generally used to focus, simplify, and customize the perception each user has of the database. Types of views include Indexed, Partitioned, and System views (look into later).