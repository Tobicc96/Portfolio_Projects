-- Explore Data

SELECT * 
FROM PortfolioProject..CovidDeaths

--Creating Tables

-- 1.  

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- 2. 

SELECT location, SUM(cast(new_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND Location <> 'International'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- 4.

SELECT Location, Population, CAST(Date AS date) AS Date , MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC
