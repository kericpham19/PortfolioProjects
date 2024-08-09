-- Calling the covid data table from portfolio project data schemas
SELECT *
FROM portfolio_project.covid_data;

-- Calling the covid vaccinations table from the portfolio project data schemas
SELECT *
FROM portfolio_project.covidvaccinations;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project.covid_data
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths

-- Shows the likelihood of dying if you conctract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM portfolio_project.covid_data
WHERE location LIKE '%States%'; # Replace 'States' with a country of choosing to find the desire country data.

-- Looking at Total Cases vs Population

-- Shows what percentage of population got covid
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS DeathPercentage 
FROM portfolio_project.covid_data
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases / population)) * 100 AS Percent_Population_Infected 
FROM portfolio_project.covid_data
GROUP BY population, location
ORDER BY Percent_Population_Infected DESC;

-- Show contintents with the highest death count per population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM portfolio_project.covid_data
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers

SELECT date, 
SUM(new_cases) AS total_new_cases, 
SUM(cast(new_deaths AS INT)) AS total_deaths, 
SUM(cast(new_deaths as int)) / SUM(New_Cases)*100 as DeathPercentage
FROM portfolio_project.covid_data
WHERE continent is not null
GROUP BY date 
ORDER BY 1, 2;


-- Looking at  Total Population vs Vaccinations 
-- Shows Percentage of Population that has recieved at least one Covid Vaccine 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac,new_vaccinations)) OVER (Partition BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated 
FROM portfolio_project.covid_data dea
JOIN portfolio_project.covidvaccinations vac
	ON dea.location
    AND	dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3;

-- Using CTE to perform Calculation on Partition By in previous query

With PopsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac,new_vaccinations)) OVER (Partition BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM portfolio_project.covid_data dea
JOIN portfolio_project.covidvaccinations vac
	ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null

)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using Temp Table to perfom Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 