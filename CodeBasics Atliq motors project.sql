CREATE DATABASE CODEBASICS;

USE CODEBASICS;	

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

SELECT * FROM dim_date
JOIN electric_vehicle_sales_by_makers
ON dim_date.ï»¿date = electric_vehicle_sales_by_makers.ï»¿date;

-- Q1: List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold--

WITH RankSales as(
	SELECT maker, fiscal_year, SUM(electric_vehicles_sold) AS Total_vehicles_sold,
    ROW_NUMBER() OVER (partition by fiscal_year ORDER BY SUM(electric_vehicles_sold) DESC) AS rank_desc,
    ROW_NUMBER() OVER (PARTITION BY fiscal_year ORDER BY SUM(electric_vehicles_sold) ASC) AS rank_asc
    FROM electric_vehicle_sales_by_makers evm
    JOIN dim_date dd
    ON evm.ï»¿date = dd.ï»¿date 
    WHERE dd.fiscal_year IN (2023, 2024)
    AND evm.vehicle_category = '2-Wheelers'
    GROUP BY maker, fiscal_year
)

SELECT maker , fiscal_year , Total_vehicles_sold, 'TOP3' as rank_type
FROM RankSales
WHERE rank_desc <=3

UNION ALL 

SELECT maker , fiscal_year , Total_vehicles_sold, 'BOTTOM3' as rank_type
FROM RankSales
WHERE rank_asc <=3;

-- Q2: What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

WITH TopMakers AS (
    SELECT 
        maker,
        SUM(electric_vehicles_sold) AS total_sales
    FROM electric_vehicle_sales_by_makers evm
    JOIN dim_date dd ON evm.ï»¿date = dd.ï»¿date
    WHERE evm.vehicle_category = '4-Wheelers' 
      AND dd.fiscal_year BETWEEN 2022 AND 2024
    GROUP BY maker
    ORDER BY total_sales DESC
    LIMIT 5
),
QuarterlyTrends AS (
    SELECT 
        dd.fiscal_year,
        dd.quarter,
        evm.maker,
        SUM(evm.electric_vehicles_sold) AS quarterly_sales
    FROM electric_vehicle_sales_by_makers evm
    JOIN dim_date dd ON evm.ï»¿date = dd.ï»¿date
    WHERE evm.vehicle_category = '4-Wheelers' 
      AND dd.fiscal_year BETWEEN 2022 AND 2024
    GROUP BY dd.fiscal_year, dd.quarter, evm.maker
)
SELECT 
    qt.fiscal_year,
    qt.quarter,
    qt.maker,
    qt.quarterly_sales
FROM QuarterlyTrends qt
JOIN TopMakers tm ON qt.maker = tm.maker
ORDER BY qt.fiscal_year, qt.quarter, qt.maker;

-- Q3: Market Share by Makers 2-wheeler and 4-wheeler:

WITH TotalSales AS (
    SELECT 
        vehicle_category,
        SUM(electric_vehicles_sold) AS total_category_sales
    FROM electric_vehicle_sales_by_makers
    GROUP BY vehicle_category
),
MakerSales AS (
    SELECT 
        maker,
        vehicle_category,
        SUM(electric_vehicles_sold) AS maker_sales
    FROM electric_vehicle_sales_by_makers
    GROUP BY maker, vehicle_category
)
SELECT 
    ms.maker,
    ms.vehicle_category,
    ms.maker_sales,
    ts.total_category_sales,
    ROUND((ms.maker_sales * 100.0 / ts.total_category_sales),2) AS market_share_percentage
FROM MakerSales ms
JOIN TotalSales ts ON ms.vehicle_category = ts.vehicle_category
ORDER BY ms.vehicle_category, market_share_percentage DESC;


--  Q4: Total Number of Makers (2 vs 4 wheelers):

SELECT  count(Distinct maker),vehicle_category FROM electric_vehicle_sales_by_makers
Group by vehicle_category;

--  Q5: Total amount of EV sales by vehicle category. 

SELECT SUM(electric_vehicles_sold) AS Total_EV_sold, vehicle_category 
FROM electric_vehicle_sales_by_makers
GROUP BY vehicle_category;  

-- Q6:  Total Vehicle sale by all states.

SELECT sum(total_vehicles_sold) as Total_vehicle_sold
FROM electric_vehicle_sales_by_state ;

-- Q7: Total EV sale by States. 

SELECT sum(electric_vehicles_sold) as Total_vehicle_sold
FROM electric_vehicle_sales_by_state ;

-- Q8: SQL Query to calculate the Compound Annual Growth Rate (CAGR) of EV sales

WITH AnnualSales AS (
    SELECT 
        dd.fiscal_year,
        SUM(evm.electric_vehicles_sold) AS total_sales
    FROM electric_vehicle_sales_by_makers evm
    JOIN dim_date dd ON evm.ï»¿date = dd.ï»¿date
    GROUP BY dd.fiscal_year
),
CAGRCalculation AS (
    SELECT 
        MIN(fiscal_year) AS start_year,
        MAX(fiscal_year) AS end_year,
        MIN(total_sales) AS start_sales,
        MAX(total_sales) AS end_sales
    FROM AnnualSales
)
SELECT 
    start_year,
    end_year,
    start_sales,
    end_sales,
    (POWER((end_sales/ start_sales), (1.0 / (end_year - start_year))) - 1)*100 AS cagr
FROM CAGRCalculation; 

-- Q9: Query to find top 5 states with high penetration rate.

SELECT state,
ROUND((SUM(electric_vehicles_sold)) *100 /(SUM(total_vehicles_sold)),2) as Penetration_Rate
FROM electric_vehicle_sales_by_state
GROUP BY state
ORDER BY 2 DESC
LIMIT 5;

--  Q10: How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024? 

SELECT 
    State, 
    SUM(electric_vehicles_sold) AS Total_EV_Sales, 
    SUM(total_vehicles_sold) AS Total_Vehicle_Sales,
    ROUND((SUM(electric_vehicles_sold) * 100.0 / SUM(total_vehicles_sold)),2) AS Penetration_Rate
FROM 
    electric_vehicle_sales_by_state
WHERE 
    state IN ('Delhi', 'Karnataka')
GROUP BY 
    State;
    
SELECT Month(ï»¿date),state,vehicle_category
from electric_vehicle_sales_by_state;