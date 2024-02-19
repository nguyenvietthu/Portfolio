USE northwind;

-- List of Products from the Beverages Category
SELECT *
FROM products p 
	INNER JOIN categories c 
    ON p.CategoryID = c.CategoryID
WHERE c.CategoryName ='Beverages';

-- But I want to know more about supplier of these products
WITH new_table AS(
   SELECT p.ProductID, p.ProductName, c.CategoryName, p.SupplierID
   FROM products p 
   INNER JOIN categories c 
   ON p.CategoryID = c.CategoryID
   WHERE c.CategoryName ='Beverages'
)
SELECT 
   n.ProductName, n.CategoryName, s.SupplierName
FROM new_table as n
	INNER JOIN suppliers as s
    ON n.SupplierID = s.SupplierID;

-- When we use outter JOIN?
-- Khi muốn trả về full kết quả bảng bên trái, và những kết quả matching của bản bên phải.
-- VD: Phòng đoàn LEFT JOIN Học sinh: Những học sinh ko có trong phòng đoàn trả về null. Ta sẽ lọc ra được những học sinh này
SELECT p.ProductName, c.CategoryName
FROM products as p
	 LEFT OUTER JOIN categories as c
     ON p.CategoryID = c.CategoryID;

							-- KHI NAO DUNG NULL---
-- NULL values: sẽ có những khách hàng chưa có ngày sinh. Nếu lọc 1 cách bình thường những ng có ngày sinh sẽ thiếu sót
SELECT BirthDate
FROM employees;
-- It's wrong data type
-- Update the BirthDate column to DATE type with '00:00:00' as the time part
ALTER TABLE employees MODIFY BirthDate date;
-- Now we can't use it
SELECT *
FROM employees
WHERE BirthDate >= '1800-01-01' AND BirthDate IS NOT NULL;

------------- SQL BUILD-IN FUNCTION ----------
-- COUNT: Có bao nhiêu sản phẩm tổng cộng?
SELECT COUNT(*) FROM products;
-- or
SELECT COUNT(ProductID) FROM products;
-- khác nhau?
SELECT COUNT( DISTINCT ProductID) FROM products;
-- We can count more than 1
SELECT COUNT( DISTINCT City), COUNT(City),  COUNT( DISTINCT Country), COUNT(Country)
FROM customers;

-- SUM ------------
-- Q0: How many products do we have?
SELECT COUNT(*)
FROM products;
-- Q1: How many products have the price more than 20$
SELECT COUNT(*)
FROM products
WHERE Price > 20;
-- Q2: How many products have the price between 30-50
SELECT COUNT(*)
FROM products
WHERE Price between 30 and 50;   
-- Q3: What is the least/highest price product?
SELECT *
FROM products
order by price DESC;

-- How many highest product that we've sell?
SELECT COUNT(*) as Number_Order, SUM(Quantity) as Total_Quantity
FROM orderdetails
WHERE ProductID = 38;

-- Get some Insight
-- Challenge 1: Categories bring back highest revenue?
WITH temp AS(
	SELECT c.CategoryName, p.ProductName, p.Price, o.Quantity, (p.Price * o.Quantity) as sale_amount 
	FROM categories as c
		INNER JOIN products as p ON c.CategoryID = p.CategoryID
		INNER JOIN orderdetails as o ON p.ProductID = o.ProductID
	)
SELECT CategoryName, SUM(sale_amount) 
FROM temp
GROUP BY CategoryName
ORDER BY SUM(sale_amount) DESC;

-- Challenge 2:  Số lượng khách hàng phân bố theo từng quốc gia (đã mua hàng)? Quốc gia nào đem lại doanh thu cao nhất?
SELECT * FROM customers;
SELECT * FROM orders;
-- Tổng số khách hàng: 91
SELECT COUNT( DISTINCT CustomerID) FROM customers;
-- Tổng số khách đã mua hàng: 74
WITH temp as (
SELECT c.CustomerID, c.CustomerName, c.Country, o.OrderID
FROM customers as c
	INNER JOIN orders as o
		ON c.CustomerID = o.CustomerID
 )       
SELECT COUNT(DISTINCT CustomerID) as 'Tổng số khách đã mua hàng là' FROM temp;
-- Phân chia theo từng quốc gia:
WITH temp as (
SELECT c.CustomerID, c.CustomerName, c.Country, o.OrderID
FROM customers as c
	INNER JOIN orders as o
		ON c.CustomerID = o.CustomerID
 )       
SELECT Country, COUNT(DISTINCT CustomerID) 
FROM temp
GROUP BY Country
ORDER BY COUNT(DISTINCT CustomerID)  DESC;

-- Top 5 Quốc gia đem lại nhiều doanh thu nhất? Chiếm bao nhiêu phần trăm?
WITH temp as(
SELECT c.CustomerName, c.Country, p.ProductName, od.Quantity, p.Price, (od.Quantity*p.Price) as SaleAmount
FROM customers as c
	INNER JOIN orders as o ON c.CustomerID = o.CustomerID
    INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p on p.ProductID = od.ProductID)
SELECT  Country, 
		SUM(SaleAmount) as TotalRevenue, 
        ROUND(SUM(SaleAmount)/(SELECT SUM(SaleAmount) FROM temp)*100,2) as RevenuePercentage,
        RANK() OVER (ORDER BY SUM(SaleAmount) DESC) AS XEPHANG
FROM temp
GROUP BY Country
ORDER BY TotalRevenue DESC
LIMIT 5;
-- Challenge 3: Top 5 Khách hàng nào đã mua hàng ( số lượng ) nhiều nhất?
SELECT c.CustomerID, c.CustomerName, SUM(od.Quantity) as Total_Quantity
FROM customers as c
	INNER JOIN orders as o ON c.CustomerID = o.CustomerID
    INNER JOIN orderdetails as od ON od.OrderID = o.OrderID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY Total_Quantity DESC
LIMIT 5;
-- Vậy người mua nhiều sản phẩm nhất này có phải là người đem lại nhiều doanh thu nhất không?
WITH temp as(
SELECT c.CustomerID, c.CustomerName, od.Quantity, p.Price, (od.Quantity * p.Price) as SaleAmount
FROM customers as c
	INNER JOIN orders as o ON c.CustomerID = o.CustomerID
    INNER JOIN orderdetails as od ON od.OrderID = o.OrderID
    INNER JOIN products as p ON p.ProductID = od.ProductID)
SELECT CustomerID, CustomerName, SUM(Quantity), SUM(SaleAmount),
RANK() OVER(order by SUM(SaleAmount) DESC) as Xephang
FROM temp
GROUP BY 1,2
ORDER BY SUM(Quantity) DESC
LIMIT 10;

-- Challenge 4: Top 5 Nhân viên nào sale giỏi nhất? Cho thông tin nhân viên đó
WITH temp as (
SELECT e.EmployeeID, SUM(p.Price*od.Quantity) as SaleAmount
FROM employees as e
	INNER JOIN orders as o ON e.EmployeeID = o.EmployeeID
    INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p ON od.ProductID = p.ProductID
GROUP BY e.EmployeeID
ORDER BY SaleAmount DESC
LIMIT 5
)
SELECT * 
FROM employees
WHERE employees.EmployeeID IN (SELECT EmployeeID FROM temp) ;


-- Challenge 5: Năm nào là năm có nhiều doanh thu nhất?
-- Cụ thể là tháng nào trong năm đó
-- Đổi kiểu Datetime->Date
AlTER TABLE orders MODIFY OrderDate Date;

WITH sale_table as(
SELECT  YEAR(o.OrderDate) as Yearr, MONTH(o.OrderDate) as Monthh, 
		SUM(od.Quantity * p.Price) as SaleAmount
FROM orders as o
	INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p ON od.ProductID = p.ProductID
GROUP BY 1,2
ORDER BY 1,2
)
SELECT Yearr, Monthh, SaleAmount,
		 RANK() OVER(Partition by Yearr ORDER BY SaleAmount DESC) as RANKING,
		 FORMAT(SUM(SaleAmount) OVER( Partition by Yearr), '0,0') as TotalSale
FROM sale_table;


-- Challenge HARD: Trong các Quốc gia cung cấp sản phẩm top đầu như Mỹ, Úc và Đức thì loại hàng  nào đang chiếm % nhiều nhất?
WITH final as(
SELECT s.Country, c.CategoryName, SUM(od.Quantity*p.Price) as SaleAmount
FROM orders as o
	INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p ON p.ProductID = od.ProductID
    INNER JOIN categories as c ON c.CategoryID = p.CategoryID
    INNER JOIN suppliers as s ON s.SupplierID = p.SupplierID
GROUP BY 1,2
ORDER BY 1,2)
SELECT Country, CategoryName, SaleAmount,
		SUM(SaleAmount) OVER (Partition by Country) as TotalSale,
		ROUND(SaleAmount / SUM(SaleAmount) OVER (Partition by Country) * 100,2) as Percent,
        RANK() OVER (Partition by Country Order by SaleAmount DESC) as RANKING
FROM final
-- WHERE RANKING = 1
ORDER BY  TotalSale DESC, Country, RANKING;

# Country, TotalRevenue, RevenuePercentage
-- 'USA', '69611.75', '18.01'
-- 'Austria', '51671.96', '13.37'
-- 'Germany', '47241.82', '12.23'

-- Đâu là khách hàng có ít nhất 1 lần mua hàng 2 liên tiếp. Cho thông tin khách hàng đó?
WITH step1 as (
SELECT CustomerID, OrderDate,
		LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as PreviousDate
FROM orders
ORDER BY 1,2)
SELECT customers.*
FROM customers
WHERE customers.CustomerID IN ( SELECT CustomerID
								FROM step1
								WHERE OrderDate = PreviousDate + INTERVAL 1 DAY);
-- Khách nào là khách hàng trung thành? ( mua nhiều hơn 10 ngày)
SELECT CustomerID, COUNT(DISTINCT OrderDate) as NumberofTime
FROM orders
GROUP BY CustomerID
HAVING NumberofTime >= 10;
-- Khách hàng nào chỉ mua 1 lần và không quay lại
WITH Purchased_History as (
	SELECT CustomerID, COUNT(DISTINCT OrderDate) as NumberofTime
	FROM orders
	GROUP BY CustomerID)
SELECT * FROM customers
WHERE customers.CustomerID IN ( SELECT P.CustomerID 
								FROM Purchased_History as P
								WHERE P.NumberofTime < 2)
-- Moving Average 3 days and how it calculate

SELECT MIN(OrderDate), MAX(OrderDate)
FROM orders;
-- I wanna create a Calendar Table contain range from Min to Max
-- So i use Recursive CTE to do that
-- Create the calendar table 
CREATE TEMPORARY TABLE calendar_table (
    CalendarDate DATE
);
-- Insert dates using a recursive CTE
INSERT INTO calendar_table (CalendarDate)
WITH RECURSIVE DateRange AS (
    SELECT '1996-07-04' AS CalendarDate
    UNION ALL
    SELECT CalendarDate + INTERVAL 1 DAY
    FROM DateRange
    WHERE CalendarDate < '1997-02-12'
)
SELECT CalendarDate FROM DateRange;

-- Display the contents of the calendar table for verification
SELECT * FROM calendar_table;

-- JOIN to get final_sale table
WITH sale_table as(
SELECT ct.CalendarDate, COALESCE(SUM(p.Price * od.Quantity),0) as SaleAmount
FROM calendar_table as ct
	LEFT OUTER JOIN orders as o ON o.OrderDate = ct.CalendarDate
	LEFT OUTER JOIN orderdetails as od ON o.OrderID = od.OrderID
    LEFT OUTER JOIN products as p ON p.ProductID = od.ProductID
GROUP BY 1
)
-- Let's do Moving 3 days Average
SELECT *, AVG(SaleAmount) OVER(ORDER BY CalendarDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as MA3
FROM sale_table;
-- 26/12/2023
SELECT * FROM orders;
-- Khách hàng đã mua gì trong lần cuối cùng họ mua hàng
SELECT c.CustomerName, o.OrderID, o.OrderDate, p.ProductName, od.Quantity
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN orderdetails as od ON od.OrderID = o.OrderID
JOIN products as p ON p.ProductID = od.ProductID
WHERE o.OrderDate IN (
    SELECT MAX(OrderDate)
    FROM orders
    GROUP BY CustomerID
);

-- Quý nào trong năm nào có doanh thu cao nhất?
-- SELECT * , DATE_FORMAT(OrderDate, '%Y-%m') as YearMonth, DATE_FORMAT(OrderDate, '%Y-%m')
-- FROM orders;
WITH YQSale as(
SELECT CONCAT(YEAR(OrderDate), '-Q', Quarter(OrderDate)) as YearQuarter,
		SUM(od.Quantity*p.Price) as SaleAmount
FROM orders as o
	JOIN orderdetails as od ON od.OrderID = o.OrderID 
    JOIN products as p ON p.ProductID = od.ProductID
GROUP BY 1
ORDER BY 1)
SELECT *, SUM(SaleAmount) OVER(Order by YearQuarter) as TotalSale
FROM YQSale;


-- 28/12/2023
-- Nhân viên nào bán được nhiều hơn trung bình sale, amount.
-- Step1: Bảng sale của từng nhân viên
WITH sale_per_emp as (
	SELECT e.EmployeeID, SUM(p.Price*od.Quantity) as SaleAmount
	FROM employees as e
		INNER JOIN orders as o ON e.EmployeeID = o.EmployeeID
		INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
		INNER JOIN products as p ON od.ProductID = p.ProductID
	GROUP BY e.EmployeeID
	ORDER BY SaleAmount DESC
), 
-- Step2: AVG of SaleAmount
Average_sale as(
	SELECT AVG(SaleAmount) as avgSale
    FROM sale_per_emp
)
-- Final:
SELECT * 
FROM employees
WHERE EmployeeID IN (
				-- Employee ID of Whose Sale > AVG 
				SELECT spe.EmployeeID
				FROM sale_per_emp as spe, Average_sale as a
				WHERE spe.SaleAmount > a.avgSale);


-- How to rankk, just for education purpose
WITH sale_per_emp as (
	SELECT e.EmployeeID, ROUND(COALESCE(SUM(p.Price*od.Quantity),0),-4) as SaleAmount,
    CASE 
		WHEN  YEAR(e.BirthDate) < 1960 THEN '1960+'
        ELSE '1960-'
	END as AGE
	FROM employees as e
		LEFT JOIN orders as o ON e.EmployeeID = o.EmployeeID
		LEFT JOIN orderdetails as od ON o.OrderID = od.OrderID
		LEFT JOIN products as p ON od.ProductID = p.ProductID
	GROUP BY 3,1
)
SELECT AGE, EmployeeID, SaleAmount,
		RANK() OVER(partition by AGE order by SaleAmount DESC) as RANK1,
        DENSE_RANK() OVER(partition by AGE order by SaleAmount DESC) as RANK2,
        ROW_NUMBER() OVER(partition by AGE order by SaleAmount DESC) as RANK3
FROM sale_per_emp;

-- So sanh kha nang ban hang
WITH sale_per_emp as (
	SELECT e.EmployeeID, ROUND(COALESCE(SUM(p.Price*od.Quantity),0),-4) as SaleAmount,
    CASE 
		WHEN  YEAR(e.BirthDate) < 1960 THEN '1960+'
        ELSE '1960-'
	END as AGE
	FROM employees as e
		LEFT JOIN orders as o ON e.EmployeeID = o.EmployeeID
		LEFT JOIN orderdetails as od ON o.OrderID = od.OrderID
		LEFT JOIN products as p ON od.ProductID = p.ProductID
	GROUP BY 3,1
)
SELECT AGE, EmployeeID, SaleAmount,
		LEAD(SaleAmount,1,0) OVER(partition by AGE order by EmployeeID) as Next_employee,
        LAG(SaleAmount,1,0) OVER(partition by AGE order by EmployeeID) as Previous_employee
FROM sale_per_emp;

-- TEST
SET @target := 35000;
WITH sale_table as(
SELECT  YEAR(o.OrderDate) as Yearr, MONTH(o.OrderDate) as Monthh, 
		SUM(od.Quantity * p.Price) as SaleAmount
FROM orders as o
	INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p ON od.ProductID = p.ProductID
GROUP BY 1,2
ORDER BY 1,2
)
-- Total Monthly Sale Amount >= target
SELECT SUM(SaleAmount) as TotalGreaterANDEqualtoTarget
FROM sale_table
WHERE SaleAmount>=@target;

-- WINDOW FUNCTION
SELECT *,
		FIRST_VALUE(CategoryName) OVER(partition by Country order by SaleAmount DESC) as Most_Sale,
        LAST_VALUE(CategoryName) OVER w as Least_Sale,
         MAX(SaleAmount) OVER w as Max_sale,
         ROUND(cume_dist() OVER (order by SaleAmount DESC)*100,2)
         -- percent_rank
FROM temp_table
window w as (partition by Country order by SaleAmount DESC
						ROWS between 2 preceding and 2 following );
					-- sự khác biệt của rows và range

-- Temp Table
DROP TEMPORARY TABLE IF EXISTS temp_table;
CREATE TEMPORARY TABLE temp_table AS
SELECT * FROM
(
SELECT s.Country, c.CategoryName, SUM(od.Quantity*p.Price) as SaleAmount
FROM orders as o
	INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
    INNER JOIN products as p ON p.ProductID = od.ProductID
    INNER JOIN categories as c ON c.CategoryID = p.CategoryID
    INNER JOIN suppliers as s ON s.SupplierID = p.SupplierID
GROUP BY 1,2
ORDER BY 1) a;
SELECT * FROM temp_table;

-- EXIST
USE northwind;
SELECT *
FROM customers c
WHERE EXISTS (SELECT 1 
				FROM orders o
                WHERE o.CustomerID = c.CustomerID and MONTH(o.OrderDate) IN (1,2) AND YEAR(o.OrderDate) = 1997);
                
-- Data Manipulation Using Correlated Subqueries
-- Step1: Bảng sale của từng nhân viên
WITH sale_per_emp as (
	SELECT e.EmployeeID, SUM(p.Price*od.Quantity) as SaleAmount
	FROM employees as e
		INNER JOIN orders as o ON e.EmployeeID = o.EmployeeID
		INNER JOIN orderdetails as od ON o.OrderID = od.OrderID
		INNER JOIN products as p ON od.ProductID = p.ProductID
	GROUP BY e.EmployeeID
	ORDER BY SaleAmount DESC
), 
	groupingg as (
    SELECT 'Bad' name, 0 low, 30000 as high
    UNION ALL 
    SELECT 'Average' name, 30000 as low, 70000 as high
    UNION ALL
    SELECT 'Vip' name, 70000 as low, 200000 as high
)
SELECT groupingg.name, COUNT(*) as num_employee
FROM sale_per_emp  
INNER JOIN groupingg 
	ON sale_per_emp.SaleAmount between groupingg.low and groupingg.high
GROUP BY 1;

