-- when continent is null that means location is continent, so we need to select only countries so continenent should not be null
Select *
From covid_deaths
where continent is not null
order by 3, 4

Select Top 5 *
From covid_vaccinations
order by 3, 4

--Select Data that we are going to use
Select Location, date, total_cases, new_cases, total_deaths, population
From covid_deaths
order by 1, 2

-- Total Cases vs Total Deaths. Percentage of deaths of cases
-- Shows the likelihood of dying if contracting covid
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From covid_deaths
where location = 'Romania'
order by 1, 2

-- Total cases vs population
-- What percentage of population got COVID
Select Location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From covid_deaths
where location = 'Romania'
order by 1, 2

-- Countires with highest infection rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as InfectionRate
From covid_deaths
group by Location, Population
order by InfectionRate Desc

--Countries with the Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid_deaths
where continent is not null
group by Location
order by TotalDeathCount DESC

-- By continent
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid_deaths
where continent is not null
group by continent
order by TotalDeathCount DESC

--apparently continent doesn't include all countries, but correct continent is in location, in continent , North America not included Canada
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid_deaths
where continent is null
group by location
order by TotalDeathCount DESC

--Showing continents with the highest death counts per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid_deaths
where continent is not null
group by continent
order by TotalDeathCount DESC

-- Global numbers
Select date, SUM(cast (new_cases as float)) as TotalCases, sum(cast(new_deaths as float)) as TotalDeaths, 
CASE
	when sum(new_cases)=0 then 0
	else SUM(cast(new_deaths as int))/sum(new_cases)*100
END as DeathPercentage
From covid_deaths
where continent is not null
group by date
order by 1,2

Select SUM(cast (new_cases as float)) as TotalCases, sum(cast(new_deaths as float)) as TotalDeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From covid_deaths
where continent is not null
order by 1,2

-- covid vaccinations joined with deaths
select *
from covid_deaths dea
join covid_vaccinations vac
	on dea.location=vac.location
	and dea.date = vac.date

-- total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from covid_deaths dea
join covid_vaccinations vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location = 'albania'
order by 2, 3

--using CTE
with PopVsVac (Continent, Location, Date, Population, NewVaccination, RollingPeopleVaccinated)
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from covid_deaths dea
join covid_vaccinations vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
select *, (RollingPeopleVaccinated/Population)*100
from PopVsVac

-- Temp table
Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from covid_deaths dea
join covid_vaccinations vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
select *, (RollingPeopleVaccinated/population) *100
from #PercentPopulationVaccinated


--Creating view to store data for later visualization
Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from covid_deaths dea
join covid_vaccinations vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Select *
from PercentPopulationVaccinated