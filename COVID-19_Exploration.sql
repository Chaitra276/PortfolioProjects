/*
Covid-19 Data Exploration 
Datasets - CovidDeaths, CovidVaccinations -> Size: 85,000 rows each
Skills used: Aggregate Functions, Converting Data Types, Joins, Window Functions with Partition By(), CTEs, Temp Tables, Views
*/

Select *
From SQLPortfolioProject..CovidDeaths$

Select *
From SQLPortfolioProject..CovidVaccinations$

-- 1. Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From SQLPortfolioProject..CovidDeaths$ 
order by 1,2


-- 2. Calculating DeathRate
-- Likelihood of dying if you contract COVID in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathRate
From SQLPortfolioProject..CovidDeaths$
Where location = 'India'
order by 1,2


-- 3. Total Cases as a percentage of Population

Select Location, date, Population, total_cases,  (total_cases/population)*100 as TotalCasesPercent
From SQLPortfolioProject..CovidDeaths$
order by 1,2


-- 4. Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as MaxTotalCasesPercent
From SQLPortfolioProject..CovidDeaths$
Group by Location, Population
order by MaxTotalCasesPercent desc


-- 5. Total Death Count of each country

Select Location, SUM(cast(Total_deaths as int)) as TotalDeathCount
From SQLPortfolioProject..CovidDeaths$
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- 6. Showing contintents with the highest death count per population

Select continent, SUM(cast(Total_deaths as int)) as TotalDeathCount
From SQLPortfolioProject..CovidDeaths$
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- 7. Total cases and deaths globally

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathRate
From SQLPortfolioProject..CovidDeaths$
where continent is not null 
order by 1,2


-- 8. New Vaccinations vs Population

Select dea.location, dea.date, dea.population, vac.new_vaccinations
From SQLPortfolioProject..CovidDeaths$ dea
Join SQLPortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 1,2


-- 9. Total vaccinations for every country

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationPerCountry
FROM SQLPortfolioProject..CovidDeaths$ dea
JOIN SQLPortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2


-- 10. CTE for Total Vaccinations vs Population

WITH PopVsVac (Location, Date, Population, New_Vaccinations, RollingVaccinationPerCountry)
AS
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationPerCountry
FROM SQLPortfolioProject..CovidDeaths$ dea
JOIN SQLPortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
)
SELECT *, (RollingVaccinationPerCountry/Population) * 100 AS TotalPopVsTotalVac
FROM PopVsVac


-- 11. Temp Table for Total Vaccinations vs Population

DROP TABLE IF EXISTS #temp_PopVsVac
CREATE TABLE #temp_PopVsVac(
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinationPerCountry numeric
)

INSERT INTO #temp_PopVsVac
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationPerCountry
FROM SQLPortfolioProject..CovidDeaths$ dea
JOIN SQLPortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT *, (RollingVaccinationPerCountry/Population) * 100 AS TotalPopVsTotalVac
FROM #temp_PopVsVac


-- 12. Creating Views (Data in views can be used for later visualizations) 

CREATE VIEW PopVsVacView AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationPerCountry
FROM SQLPortfolioProject..CovidDeaths$ dea
JOIN SQLPortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT * FROM PopVsVacView

