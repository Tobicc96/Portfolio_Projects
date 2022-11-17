--Inspecting Data
select * from Sales_Analysis..sales_data_sample

-Checking unique values

select distinct status from Sales_Analysis..sales_data_sample -- Nice one to plot
select distinct year_id from Sales_Analysis..sales_data_sample -- 3 years (2003,2004,2005)
select distinct PRODUCTLINE from Sales_Analysis..sales_data_sample -- Nice to plot
select distinct COUNTRY from Sales_Analysis..sales_data_sample -- Nice to plot
select distinct DEALSIZE from Sales_Analysis..sales_data_sample --Nice to plot
select distinct TERRITORY  from Sales_Analysis..sales_data_sample --Nice to plot

SELECT TOP 1 MAX(ORDERDATE) from Sales_Analysis..sales_data_sample 
WHERE YEAR_ID = 2005
GROUP BY ORDERDATE
ORDER BY DAY(ORDERDATE) DESC, ORDERDATE DESC


--Analysis
--Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(SALES) Revenue
FROM Sales_Analysis..sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

-- sales by year

SELECT YEAR_ID, SUM(SALES) Revenue
FROM Sales_Analysis..sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

-- Sales by Dealsize:Medium size make the most revenue

SELECT DEALSIZE, SUM(SALES) Revenue
FROM Sales_Analysis..sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

--- Year 2003: What was the best month for sales in a specific year? How much was earned that month?: November

SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM Sales_Analysis..sales_data_sample
WHERE YEAR_ID = 2003 -- Change year yo see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

-- Year 2003: November seems to be the month, what product do they sell in November: 114 Clasic Cars were sold in November

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM Sales_Analysis..sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11 -- Change year yo see the rest
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

--- Year 2004: What was the best month for sales in a specific year? How much was earned that month?: November

SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM Sales_Analysis..sales_data_sample
WHERE YEAR_ID = 2004 -- Change year yo see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

-- Year 2004: November seems to be the month, what product do they sell in November: 105 Clasic Cars were sold in November

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM Sales_Analysis..sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 -- Change year yo see the rest
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

--Who is our best customer (this could be best answered with RFM) RFM = Recency (last order date), Frequency (Count of total orders)
--Monetary: Total spend of the customer. 

--DROP TEMP Table if exists to save memory

DROP TABLE IF EXISTS #rfm;
-- Creating CTE 1
WITH rfm as
(

	SELECT
		CUSTOMERNAME,
		SUM(SALES) MonetaryValue,
		AVG(SALES) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT TOP 1 MAX(ORDERDATE) from Sales_Analysis..sales_data_sample
						WHERE YEAR_ID = 2005
						GROUP BY ORDERDATE
						ORDER BY DAY(ORDERDATE) DESC, ORDERDATE DESC) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), 
		(SELECT TOP 1 MAX(ORDERDATE) from Sales_Analysis..sales_data_sample 
						WHERE YEAR_ID = 2005
						GROUP BY ORDERDATE
						ORDER BY DAY(ORDERDATE) DESC, ORDERDATE DESC)) Recency
	FROM Sales_Analysis..sales_data_sample
	GROUP BY CUSTOMERNAME
),
-- Creating CTE 2
rfm_calc as
(

	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM rfm r
)

SELECT 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CAST(rfm_recency AS VARCHAR)+ CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) rfm_cell_string
-- Creating TEMP Table
into #rfm 
FROM rfm_calc c

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers' --Lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' --Big spenders who haven't purchased lately)
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new_customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string in (323, 333, 321, 422, 332, 432) THEN 'active' -- Customers who buy often & recentcly, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
END rfm_segment
FROM #rfm


--What products are most often sold together?
--SUBQUERIES, Suff function
SELECT DISTINCT ORDERNUMBER, stuff(

	(SELECT ',' + PRODUCTCODE
	FROM Sales_Analysis..sales_data_sample p
	WHERE ORDERNUMBER in
		(
		SELECT ORDERNUMBER
		from (
			SELECT ORDERNUMBER, count(*) rn
			FROM Sales_Analysis..sales_data_sample
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
		) n

		WHERE rn = 2
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path (''))

	, 1, 1, '') productCodes

FROM Sales_Analysis..sales_data_sample s
ORDER BY 2 DESC