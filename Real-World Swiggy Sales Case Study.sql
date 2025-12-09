SELECT * FROM swiggy_data

--Data Validation and Cleaning
--Null Check
SELECT 
	SUM(CASE WHEN State IS NULL THEN 1  ELSE 0 END) AS null_state,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN [Order Date] IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN [Restaurant Name] IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN [Dish Name] IS NULL THEN 1 ELSE 0 END) AS null_dish,
	SUM(CASE WHEN [Price (INR)] IS NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN [Rating Count] IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;

--Blank or Empty String
SELECT *
FROM swiggy_data
WHERE
State ='' OR City='' OR [Restaurant Name]='' OR Location='' OR Category='' OR [Dish Name]='' OR [Price (INR)]='' OR Rating='' OR [Rating Count]=''

--Duplicate Detection
SELECT 
State, City, [Order Date], [Restaurant Name], Location, Category, [Dish Name], [Price (INR)], Rating, [Rating Count], count(*) as CNT
FROM swiggy_data
GROUP BY
State, City, [Order Date], [Restaurant Name], Location, Category, [Dish Name], [Price (INR)], Rating, [Rating Count]
Having count(*)>1

--Delete Duplication
WITH CTE AS (
SELECT *, ROW_NUMBER() Over(
	PARTITION BY State, City, [Order Date], [Restaurant Name], Location, Category, [Dish Name], [Price (INR)], Rating, [Rating Count]
ORDER BY (SELECT NULL)
) AS rn
FROM swiggy_data
)
DELETE FROM CTE WHERE rn>1

--CREATING SCHEMA
--DIMENSION TABLES
--DATE TABLE

CREATE TABLE dim_date (
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	full_Date DATE,
	Year INT,
	Month INT,
	Month_Name varchar(20),
	Quarter INT,
	Day INT,
	Week INT
	)

--dim_location
CREATE TABLE dim_location (
	location_id INT IDENTITY(1,1) PRIMARY KEY,
	State VARCHAR(100),
	City VARCHAR(100),
	location VARCHAR(200)
);

--dim_Restaurant
CREATE TABLE dim_restaurant (
	restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(200)
);

--dim_category
CREATE TABLE dim_category (
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(200)
);

--dim_dish
CREATE TABLE dim_dish (
	dish_id INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(200)
);


SELECT * FROM swiggy_data

--FACT TABLE
CREATE TABLE fact_swiggy_orders (
	order_id INT IDENTITY(1,1) PRIMARY KEY,

	date_id INT,
	Price_INR DECIMAL(10,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,

	location_id INT,
	restaurant_id INT,
	category_id INT,
	dish_id INT,

	FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
	FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
)

SELECT * FROM fact_swiggy_orders

--INSERT DATA IN TABLES
--dim_date
INSERT INTO dim_date (full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT 
	[Order Date],
	YEAR([Order Date]),
	MONTH([Order Date]),
	DATENAME(MONTH, [Order Date]),
	DATEPART(QUARTER, [Order Date]),
	DAY([Order Date]),
	DATEPART(WEEK, [Order Date])
FROM swiggy_data
WHERE [Order Date] IS NOT NULL;

SELECT * FROM dim_location

--dim_location
INSERT INTO dim_location (State, City, location)
SELECT DISTINCT
	State,
	City,
	Location
FROM swiggy_data;


--dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	[Restaurant Name]
FROM swiggy_data;


--dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT 
	Category
FROM swiggy_data;

--dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
	[Dish Name]
FROM swiggy_data;


SELECT * FROM swiggy_data
--fact_table
INSERT INTO fact_swiggy_orders
(
	date_id,
	Price_INR,
	Rating,
	Rating_Count,
	location_id,
	restaurant_id,
	category_id,
	dish_id
)
SELECT
	dd.date_id,
	s.[Price (INR)],
	s.Rating,
	s.[Rating Count],

	d1.location_id,
	dr.restaurant_id,
	dc.category_id,
	dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
	ON dd.full_Date = s.[Order Date]

JOIN dim_location d1
	ON d1.State = s.State
	AND d1.City = s.City
	AND d1.location = s.location

JOIN dim_restaurant dr
	ON dr.Restaurant_Name = s.[Restaurant Name]

JOIN dim_category dc
	ON dc.Category = s.Category

JOIN dim_dish dsh
	ON dsh.Dish_Name = s.[Dish Name];


SELECT * FROM fact_swiggy_orders


SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l	ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id

--KPI's
--Toatl Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders

--Total Revenue (INR Million)
SELECT 
FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000, 'N2') + 'INR Million'
AS Total_Revenue 
FROM fact_swiggy_orders

--Average Dish Price
SELECT 
FORMAT(AVG(CONVERT(FLOAT,price_INR)), 'N2') + 'INR Million'
AS Total_Revenue 
FROM fact_swiggy_orders

--Average Rating
SELECT
AVG(Rating) AS Avg_Rating
FROM fact_swiggy_orders

--Deep Dive Business Analysis

--Monthly Order Trendz
SELECT 
d.year,
d.month,
d.month_name,
count(*) AS Total_Orders 
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.Month,
d.month_name
ORDER BY count(*) DESC

SELECT 
d.year,
d.month,
d.month_name,
SUM(Price_INR) AS Total_Orders 
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.Month,
d.month_name
ORDER BY SUM(Price_INR) DESC

--QuaterlySELECT
SELECT
d.year,
d.quarter,
count(*) AS Total_Orders 
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.quarter
ORDER BY count(*) DESC

--Yearly Trend
SELECT
d.year,
count(*) AS Total_Orders 
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year 
ORDER BY count(*) DESC

--Orders by Day of week (Mon-Sun)
SELECT 
	DATENAME(WEEKDAY, d.full_date) AS day_name,
	COUNT(*) AS total_order
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.full_Date), DATEPART(WEEKDAY, d.full_Date)
ORDER BY DATEPART(WEEKDAY, d.full_Date);

--Top 10 Cities by Order Volume
SELECT TOP 10
l.city,
COUNT(*) AS Total_Orders FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.City
ORDER BY COUNT(*) DESC

SELECT TOP 10
l.city,
SUM(f.Price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.City
ORDER BY SUM(f.Price_INR) ASC

--Revenue contribution by states
SELECT
l.State,
SUM(f.Price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.State
ORDER BY SUM(f.Price_INR) ASC

--Top 10 restaurants by Orders
SELECT TOP 10
r.restaurant_name,
SUM(f.Price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY SUM(f.Price_INR) DESC

--Top Categories by order Volume
SELECT
	c.category,
	COUNT(*) AS Total_orders 
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category
ORDER BY Total_orders DESC

--Most Ordered Dishes
SELECT
	d.dish_name,
	COUNT(*) AS order_count 
FROM fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC

--Cuisine Performance (orders + Avg Rating)
SELECT
	c.category,
	COUNT(*) AS total_orders,
	AVG(f.rating) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders DESC

--Total orders by price range
SELECT 
	CASE
		WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'UNDER 100'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
		ELSE '500+'
	END AS price_range,
	COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY
	CASE
		WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'UNDER 100'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
		ELSE '500+'
	END
ORDER BY total_orders DESC

--Rating count Distribution (1-5)
SELECT 
	rating,
	COUNT(*) AS rating_count
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY rating 