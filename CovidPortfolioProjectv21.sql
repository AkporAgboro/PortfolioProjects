--Data import complete from two excel files
-- Checking the two tables to verify that I have not imported BEANS. lol

SELECT *
FROM PortfolioProject..CovidDeaths



SELECT *
FROM PortfolioProject..CovidVaccinations

--EXPLORING THE CovidDeaths table first


--Checking the list of continents if there are just 6. Antarctica is not habited.
SELECT DISTINCT continent
FROM PortfolioProject..CovidDeaths

-- I see now that there are NULL Values in the countinent fields of some records. Time to dig in deeper
-- Are there countries (locations) in the NULL records? and if there are, are there population figures?

SELECT DISTINCT continent, location, population
FROM PortfolioProject..CovidDeaths
Where continent IS NULL

-- Hmmm...I see then that there are some aggregated figures in the location column
-- So my initial assumption that this column contained only countries, is wrong.
--What to do... I could clean the table (drop all records where the continent is NULL, or create a temp table excluding to run my queries off 
-- I will exclude the records where the continent is NULL in my subsequent queries

--Selecting the data I will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- What is the death percentage of the total infection cases? Round to 2 decimal places
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- What is the death percentage to total infection cases in Nigeria? Round to 2 decimal places
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location LIKE 'NIgeria'
ORDER BY location, date

--Looking at total cases vs population in Nigeria
--Looking at what percentage of the population got infected in Nigeria
SELECT location, date, population, total_cases, ROUND((total_cases/population)*100, 4) AS PercentageInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location LIKE 'NIgeria'
ORDER BY location, date

--Which countries had the highest infection rate per population?
SELECT location, population, MAX(total_cases) AS HighestInfectinonCount, ROUND (MAX ((total_cases/population)*100),2) AS PercentageInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY location, population
ORDER BY PercentageInfected DESC


--Which countries had the highest deaths per population?
SELECT location, population, MAX(Cast(total_deaths as int)) AS HighestDeathCount, ROUND (MAX ((total_deaths/population)*100),2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY location, population
ORDER BY DeathPercentage DESC

--What countries had the highest death count
SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY location
ORDER BY HighestDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- What continent had the highest death count?
SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- What Continent has the highest death count per population?
SELECT continent, MAX(Cast(total_deaths as int)) AS HighestDeathCount, ROUND (MAX ((total_deaths/population)*100),2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY continent
ORDER BY DeathPercentage DESC

-- GLOBAL NUMBERS

--Death percentage per day globally

SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths AS int)) as TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
GROUP BY date
ORDER BY date, TotalCases

-- Global Totals of cases, deaths and the death percentage from infection
SELECT SUM(new_cases) as TotalCases, SUM(CAST(new_deaths AS int)) as TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location <> 'International'
--GROUP BY date
ORDER BY TotalCases, TotalDeaths

-- Now I need to bring in the CovidVaccinations table and see both
-- Firstly, let's see what's in there one more time

SELECT *
FROM PortfolioProject..CovidVaccinations

SELECT *
FROM PortfolioProject..CovidDeaths

--Joining the two tables together to query them
SELECT * 
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date


-- How many people were vaccinated per day in each country?
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location <> 'International'
--GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY continent,location, date


--A running count of people vaccinated in each country per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Vaccinations_Cumulative
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location <> 'International'
--GROUP BY dea.continent, dea.location, dea.date, dea.population
--ORDER BY continent,location, date

-- Using CTE to determine what percentage of the poppulation has been vaccinated per day

WITH PercVacc (Continent, Location, Date, Population, New_Vaccinations, Vaccinations_Cumulative)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Vaccinations_Cumulative
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location <> 'International')

SELECT *, (Vaccinations_Cumulative/Population)*100 AS PercentPopulationVaccinated
FROM PercVacc

--Using a Temp table to do the same above

DROP TABLE IF EXISTS #PercentofPopulationVaccinated
CREATE TABLE #PercentofPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Vaccinations_Cumulative numeric
)

INSERT INTO #PercentofPopulationVaccinated
(Continent, Location, Date, Population, New_Vaccinations, Vaccinations_Cumulative)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Vaccinations_Cumulative
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location <> 'International'

SELECT *, (Vaccinations_Cumulative/Population)*100 AS PercentPopulationVaccinated
FROM #PercentofPopulationVaccinated

--Creating views to store data for later visualizations
Create View PercentPopulationVaccinated 

--(Continent, Location, Date, Population, New_Vaccinations, Vaccinations_Cumulative) 
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Vaccinations_Cumulative
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location AND
dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location <> 'International'