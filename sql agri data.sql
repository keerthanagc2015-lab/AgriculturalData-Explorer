use agridata_explorar;
select * from agriculture_data;
#•	1.Year-wise Trend of Rice Production Across States (Top 3)
SELECT 
    year,
    state_name,
    SUM(rice_production_1000_tons) AS total_production
FROM agriculture_data
WHERE state_name IN (
    SELECT state_name FROM (
        SELECT state_name
        FROM agriculture_data
        GROUP BY state_name
        ORDER BY SUM(rice_production_1000_tons) DESC
        LIMIT 3
    ) AS top_states
)
GROUP BY year, state_name
ORDER BY year;
#2, Top 5 Districts by Wheat Yield Increase Over the Last 5 Years
SELECT 
    dist_name,
    MAX(CASE WHEN year = (SELECT MAX(year) FROM agriculture_data) 
        THEN wheat_production_1000_tons END) 
    -
    MAX(CASE WHEN year = (SELECT MAX(year)-4 FROM agriculture_data) 
        THEN wheat_production_1000_tons END) 
    AS yield_increase
FROM agriculture_data
GROUP BY dist_name
ORDER BY yield_increase DESC
LIMIT 5;
#•	3.States with the Highest Growth in Oilseed Production (5-Year Growth Rate)
SELECT 
    state_name,
    
    (
        MAX(CASE WHEN year = (SELECT MAX(year) FROM agriculture_data) 
            THEN oilseeds_production_1000_tons END)
        -
        MAX(CASE WHEN year = (SELECT MAX(year)-4 FROM agriculture_data) 
            THEN oilseeds_production_1000_tons END)
    )
    /
    MAX(CASE WHEN year = (SELECT MAX(year)-4 FROM agriculture_data) 
        THEN oilseeds_production_1000_tons END)
    * 100 AS growth_rate

FROM agriculture_data
GROUP BY state_name
ORDER BY growth_rate DESC
LIMIT 5;
#•	4.District-wise Correlation Between Area and Production for Major Crops (Rice, Wheat, and Maize)
-- RICE
SELECT 
    dist_name,
    'Rice' AS crop,
    (
        (COUNT(*) * SUM(rice_area_1000_ha * rice_production_1000_tons) 
        - SUM(rice_area_1000_ha) * SUM(rice_production_1000_tons))
        /
        SQRT(
            (COUNT(*) * SUM(rice_area_1000_ha * rice_area_1000_ha) - POW(SUM(rice_area_1000_ha), 2)) *
            (COUNT(*) * SUM(rice_production_1000_tons * rice_production_1000_tons) 
            - POW(SUM(rice_production_1000_tons), 2))
        )
    ) AS correlation
FROM agriculture_data
GROUP BY dist_name

UNION ALL

-- WHEAT
SELECT 
    dist_name,
    'Wheat',
    (
        (COUNT(*) * SUM(wheat_area_1000_ha * wheat_production_1000_tons) 
        - SUM(wheat_area_1000_ha) * SUM(wheat_production_1000_tons))
        /
        SQRT(
            (COUNT(*) * SUM(wheat_area_1000_ha * wheat_area_1000_ha) - POW(SUM(wheat_area_1000_ha), 2)) *
            (COUNT(*) * SUM(wheat_production_1000_tons * wheat_production_1000_tons) 
            - POW(SUM(wheat_production_1000_tons), 2))
        )
    )
FROM agriculture_data
GROUP BY dist_name

UNION ALL

-- MAIZE
SELECT 
    dist_name,
    'Maize',
    (
        (COUNT(*) * SUM(maize_area_1000_ha * maize_production_1000_tons) 
        - SUM(maize_area_1000_ha) * SUM(maize_production_1000_tons))
        /
        SQRT(
            (COUNT(*) * SUM(maize_area_1000_ha * maize_area_1000_ha) - POW(SUM(maize_area_1000_ha), 2)) *
            (COUNT(*) * SUM(maize_production_1000_tons * maize_production_1000_tons) 
            - POW(SUM(maize_production_1000_tons), 2))
        )
    )
FROM agriculture_data
GROUP BY dist_name;
#•	5.Yearly Production Growth of Cotton in Top 5 Cotton Producing States
WITH yearly_data AS (
    SELECT 
        state_name,
        year,
        SUM(cotton_production_1000_tons) AS total_production
    FROM agriculture_data
    GROUP BY state_name, year
),

top_states AS (
    SELECT state_name
    FROM yearly_data
    GROUP BY state_name
    ORDER BY SUM(total_production) DESC
    LIMIT 5
)

SELECT 
    yd.state_name,
    yd.year,
    yd.total_production,
    
    yd.total_production 
    - LAG(yd.total_production) 
      OVER (PARTITION BY yd.state_name ORDER BY yd.year) 
    AS yearly_growth

FROM yearly_data yd
JOIN top_states ts
    ON yd.state_name = ts.state_name

ORDER BY yd.state_name, yd.year;
#6.Districts with the Highest Groundnut Production in 2017
SELECT 
    dist_name,
    SUM(groundnut_production_1000_tons) AS total_production
FROM agriculture_data
WHERE year = 2017
GROUP BY dist_name
ORDER BY total_production DESC
LIMIT 10;
#•	7.Annual Average Maize Yield Across All States
SELECT 
    year,
    SUM(maize_production_1000_tons) / SUM(maize_area_1000_ha) AS avg_maize_yield
FROM agriculture_data
WHERE maize_area_1000_ha > 0
GROUP BY year
ORDER BY year;
#•	8.Total Area Cultivated for Oilseeds in Each State
SELECT 
    state_name,
    SUM(oilseeds_area_1000_ha) AS total_area
FROM agriculture_data
GROUP BY state_name
ORDER BY total_area DESC;
#•	9.Districts with the Highest Rice Yield
SELECT 
    dist_name,
    SUM(rice_production_1000_tons) / SUM(rice_area_1000_ha) AS rice_yield
FROM agriculture_data
WHERE rice_area_1000_ha > 0
GROUP BY dist_name
ORDER BY rice_yield DESC;
#•	10.Compare the Production of Wheat and Rice for the Top 5 States Over 10 Years
WITH yearly_data AS (
    SELECT 
        state_name,
        year,
        SUM(rice_production_1000_tons) AS rice_prod,
        SUM(wheat_production_1000_tons) AS wheat_prod
    FROM agriculture_data
    GROUP BY state_name, year
),

top_states AS (
    SELECT state_name
    FROM yearly_data
    GROUP BY state_name
    ORDER BY SUM(rice_prod + wheat_prod) DESC
    LIMIT 5
),

last_10_years AS (
    SELECT *
    FROM yearly_data
    WHERE year >= (SELECT MAX(year) - 9 FROM yearly_data)
)

SELECT 
    l.state_name,
    l.year,
    l.rice_prod,
    l.wheat_prod
FROM last_10_years l
JOIN top_states t
    ON l.state_name = t.state_name
ORDER BY l.state_name, l.year;