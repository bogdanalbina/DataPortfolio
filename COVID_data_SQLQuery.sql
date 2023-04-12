-- Data Set Our World in Data COVID - dataset continuously updated. Data processing for April 2023
-- Data Set contains continent in location when continent column is null. To see real data by country, continent must be null. 

SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT TOP 5 *
FROM covid_vaccinations
ORDER BY 3, 4

--Select Data for future manipulation

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2

-- Total Cases vs Total Deaths. Percentage of death when infected. Likelihood of dying if contracted COVID, in Romania

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE location = 'Romania'
ORDER BY 1, 2

-- Total cases vs population. What percentage of population got COVID
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM covid_deaths
WHERE Location = 'Romania'
ORDER BY 1, 2

-- Countries with the highest infection rate compared to population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS InfectionRate
FROM covid_deaths
GROUP BY Location, Population
ORDER BY InfectionRate DESC

--Countries with the Highest Death Count per Population
SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Highest DeathCount by continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Same as above but some data is not included in the column continent. Instead continent appears as location when continent column is null.
-- Location column also includes income clasification, so we exclude that.
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NULL AND location NOT IN ('World', 'High Income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global numbers. Total cases per day, total deaths per day and Death Percentage. Using new_cases and new_deaths, so attention when dividing by zero
SELECT date, SUM(CAST (new_cases AS FLOAT)) AS TotalCases, SUM(CAST(new_deaths AS FLOAt)) AS TotalDeaths, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100
END AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total number of cases, deaths, and percentage
SELECT SUM(CAST (new_cases AS FLOAT)) AS TotalCases, SUM(CAST(new_deaths AS FLOAT)) AS TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Covid vaccinations joined with deaths, on date and location
SELECT *
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date = vac.date

-- Total population vs vaccinations. Rolling sum of vaccination based on new vaccinations partitioned by location and rolled by date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT (FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Percentage of People vaccinated using using CTE. Percentage higher than 100% because multiple doses, and we used only new_vaccination data
WITH PopVsVac (Continent, Location, Date, Population, NewVaccination, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT (FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac

-- Same as above using Temporary Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR (255),
date DATETIME,
population NUMERIC,
New_vaccination NUMERIC,
RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT (FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population) *100
FROM #PercentPopulationVaccinated


--Creating a view to store data for later visualization in Visualization tool
DROP VIEW IF EXISTS PercentPopulationVaccinated
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT (FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO

SELECT *
FROM PercentPopulationVaccinated
