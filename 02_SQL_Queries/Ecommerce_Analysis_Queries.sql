-- 1. General Sales Insights



-- 1.1 What is the total revenue generated over the entire period?

SELECT
    P.ProductID,
    P.ProductName,
    SUM(P.Price * OD.Quantity) AS Total_Revenue
FROM OrderDetails AS OD
INNER JOIN Products AS P
    ON OD.ProductID = P.ProductID
INNER JOIN Orders AS O
    ON OD.OrderID = O.OrderID
where P.ProductName is not Null
GROUP BY P.ProductID, P.ProductName WITH ROLLUP;


--  1.2 Revenue Excluding Returned Orders

select p.ProductID, 
	   p.ProductName,
       sum(p.Price * od.Quantity) as Total_revenue
from orderdetails as od
inner join products as p
on od.ProductID = p.ProductID
inner join orders as o
on od.OrderID = o.OrderID
where o.IsReturned = 0 and P.ProductName is not Null
group by p.ProductID, 
	     p.ProductName with rollup;


-- 1.3. Total Revenue per Year

Select 
		Year(o.OrderDate) as order_year,
		sum(p.price * od.Quantity) as total_revenue
from products p
inner join orderdetails od
on p.ProductID = od.ProductID
inner join orders o
on o.OrderID = od.OrderID
where o.IsReturned = 0
group by Year(o.OrderDate)
order by order_year
;


--  1.3. Total Revenue per Month

Select date_format(o.OrderDate, '%Y-%M') as order_month,
	   sum(p.price * od.Quantity) as Total_revenue
from orderdetails od
inner join orders o
on od.OrderID = o.OrderID
inner join products p
on p.ProductID = od.ProductID
where o.IsReturned = 0
group by order_month
order by order_month
;

-- 1.4 Revenue by Product / Category

Select P.ProductName,
       P.Category,
       sum(P.Price * od.Quantity) as total_revenue
from orderdetails od
inner join orders o
on od.OrderID = o.OrderID
inner join products p
on p.ProductID = od.ProductID
where o.IsReturned = 0
group by P.ProductName,
         P.Category
order by total_revenue desc;

-- 1.5 What is the average order value (AOV) across all orders?

Select 
round(avg(order_value), 2) as Avg_order_value
from (
Select o.OrderID,
       sum(p.Price * od.Quantity) as order_value
       from products p
       inner join orderdetails od
       on od.ProductID = p.ProductID
       inner join orders o
       on o.OrderID = od.OrderID
       where IsReturned = 0
       group by o.OrderID
       ) order_rev;
 
-- 1.6.	AOV per Year / Month 

Select date_format(OrderDate, '%Y-%M') as order_month,
	   ROUND(avg(order_value),2) as AOV
from (
Select O.OrderID, O.OrderDate,
       Sum(p.Price * od.Quantity) as order_value
from products p
inner join orderdetails od
on p.ProductID = od.ProductID
inner join orders o
on o.OrderID = od.OrderID
where o.IsReturned = 0
group by O.OrderID, O.OrderDate
) order_revenue
group by order_month
order by order_month
;

-- 1.7.	What is the average order size by region?

Select Region, 
	   ROUND(avg(order_quantity),2) as AOS
from (
Select R.RegionName as Region, o.OrderID, sum(od.Quantity) as order_quantity
from regions r
inner join customers c
on r.RegionID = c.RegionID
inner join orders o
on o.CustomerID = c.CustomerID
inner join orderdetails od
on o.OrderID = od.OrderID
where o.IsReturned = 0
group by R.RegionName, o.OrderID
) as order_det
group by 1
order by AOS DESC;
       


-- 2.	Customer Insights



-- 2.1.	Who are the top 10 customers by total revenue spent?

Select c.CustomerID, c.CustomerName,
       sum(p.price * od.Quantity) as Revenue
from customers as c
inner join orders as o
on c.CustomerID = o.CustomerID
inner join orderdetails od
on o.OrderID = od.OrderID
inner join products p
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by c.CustomerID, c.CustomerName
order by Revenue desc
limit 10;

-- 2.2.	What is the repeat customer rate?

Select
round(count(case when Total_Orders > 1 then CustomerID end) * 100
      /count(CustomerID), 2
) as Repeat_customer_rate
from
(
SELECT
    C.CustomerID, C.CustomerName,
    COUNT(DISTINCT O.OrderID) AS Total_Orders
FROM Customers AS C
INNER JOIN Orders AS O
    ON C.CustomerID = O.CustomerID
WHERE O.IsReturned = 0
GROUP BY C.CustomerID, C.CustomerName
) as customer_orders;

-- 2.3.	What is the average time between two consecutive orders for the same customer Region-wise?

SELECT R.RegionName,
       ROUND(AVG(DATEDIFF(T.OrderDate, T.Previous_Order_Date)), 2)
       AS Average_Days_Between_Orders

FROM (
    SELECT CustomerID,
           OrderDate,
           LAG(OrderDate) OVER (
               PARTITION BY CustomerID
               ORDER BY OrderDate
           ) AS Previous_Order_Date
    FROM Orders
    WHERE IsReturned = 0
) AS T

INNER JOIN Customers AS C
    ON T.CustomerID = C.CustomerID

INNER JOIN Regions AS R
    ON C.RegionID = R.RegionID

WHERE T.Previous_Order_Date IS NOT NULL

GROUP BY R.RegionName
ORDER BY Average_Days_Between_Orders;

-- 2.4.	Customer Segment (based on total spend)
-- •	Platinum: Total Spend > 1500
-- •	Gold: 1000–1500
-- •	Silver: 500–999
-- •	Bronze: < 500

Select C.CustomerID, 
       C.CustomerName,
       SUM(P.Price * od.Quantity) as Total_spend,
       
       case
       when SUM(P.Price * od.Quantity) > 1500 then 'Platinum'
       when SUM(P.Price * od.Quantity) >= 1000 then 'Gold'
       when SUM(P.Price * od.Quantity) >= 500 then 'Silver'
	   when SUM(P.Price * od.Quantity) < 500 then 'Bronze'
       End as Customer_segment

From Customers as C
inner join orders as o
on c.CustomerID = o.CustomerID
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by C.CustomerID, 
       C.CustomerName
order by Total_spend desc;

-- 2.5.	What is the customer lifetime value (CLV)?

Select C.CustomerID, 
       C.CustomerName,
       SUM(P.Price * od.Quantity) as Customer_Lifetime_Value
From Customers as C
inner join orders as o
on c.CustomerID = o.CustomerID
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by C.CustomerID, 
         C.CustomerName
ORDER BY Customer_Lifetime_Value DESC;



-- 3.	Product & Order Insights



-- 3.1.	What are the top 10 most sold products (by quantity)?

Select Od.ProductID, 
       P.ProductName,
	   sum(od.Quantity) as Total_products
from orderdetails as od
inner join orders as o
on od.OrderID = o.OrderID
inner join products as P
on od.ProductID = P.ProductID
where o.IsReturned = 0
group by Od.ProductID, 
         P.ProductName
order by Total_products desc
limit 10;

-- 3.2.	What are the top 10 most sold products (by revenue)?

Select od.ProductID,
       P.ProductName,
       sum(p.Price * od.Quantity) as Revenue
from orderdetails as od
inner join orders as o
on od.OrderID = o.OrderID
inner join products as p
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by od.ProductID,
         P.ProductName
order by Revenue desc
limit 10;

-- 3.3.	Which products have the highest return rate?

Select p.ProductID,
       p.ProductName,
       count(distinct case
       when o.IsReturned = 1 then o.OrderID
       end) as Returned_orders,
       count(distinct o.OrderID) as Total_orders,
       round(count(distinct case
       when o.IsReturned = 1 then o.OrderID
       end) * 100
       / count(distinct o.OrderID),2) as Return_rate
       
from products as p
inner join orderdetails as od
on p.ProductID = od.ProductID
inner join orders as o
on od.OrderID = o.OrderID
group by p.ProductID,
         p.ProductName
order by Return_rate desc;

-- 3.4.	Return Rate by Category

Select P.Category,
       count(distinct case 
             when o.IsReturned = 1 then o.OrderID
             end) as returned_order,
		count(distinct o.OrderID) as total_order,
        round(count(distinct case
              when o.IsReturned = 1 then o.OrderID
              end) * 100
              /count(distinct o.OrderID),
              2) as Return_rate
from products as P
inner join orderdetails as od
on p.ProductID = od.ProductID
inner join orders as o
on od.OrderID = o.OrderID
group by P.Category
order by Return_rate desc;

-- 3.5.	What is the average price of products per region?
             
SELECT
    R.RegionName AS Region,
    ROUND(AVG(Product_Price), 2) AS Average_Product_Price
FROM
(
    SELECT DISTINCT
        R.RegionID,
        R.RegionName,
        P.ProductID,
        P.Price AS Product_Price
    FROM Regions AS R
    INNER JOIN Customers AS C
        ON R.RegionID = C.RegionID
    INNER JOIN Orders AS O
        ON C.CustomerID = O.CustomerID
    INNER JOIN OrderDetails AS OD
        ON O.OrderID = OD.OrderID
    INNER JOIN Products AS P
        ON OD.ProductID = P.ProductID
    WHERE O.IsReturned = FALSE
) AS RegionalProducts
INNER JOIN Regions AS R
    ON RegionalProducts.RegionID = R.RegionID
GROUP BY R.RegionID, R.RegionName
ORDER BY Average_Product_Price DESC;

-- 3.6.	What is the sales trend for each product category?

Select date_format(o.OrderDate, '%Y-%m') as Sales_month,
       p.category,
       sum(p.Price * od.Quantity) as Sales_revenue
from orders as o
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID 
where o.IsReturned = 0
group by date_format(o.OrderDate, '%Y-%m'),
         p.category
order by Sales_revenue desc;



-- 4.	Temporal Trends



-- 4.1.	What are the monthly sales trends over the past year?

Select date_format(o.OrderDate, '%Y-%m') as sales_month,
	   sum(p.Price * od.Quantity) as Total_sales
from orders as o
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID
where o.IsReturned = 0
and o.OrderDate > date_sub(
(Select max(OrderDate) from orders),
INTERVAL 1 YEAR
)
group by sales_month
order by sales_month desc ;

-- 4.2.	How does the average order value (AOV) change by month or week?

Select 
year(OrderDate) as order_year,
week(OrderDate, 3) as order_week,
avg(Order_total) as avg_order_value

from (
Select O.OrderID,
       O.OrderDate,
       sum(p.Price * od.Quantity) as Order_total
from orders as o
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as P
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by O.OrderID,
         O.OrderDate
) as WeeklyOrders
group by year(OrderDate),
         week(OrderDate, 3)
order by order_year, order_week
;



-- 5.	Regional Insights



-- 5.1.	Which regions have the highest order volume and which have the lowest?

SELECT MAX(Order_Volume) AS Highest_Order_Volume,
       MIN(Order_Volume) AS Lowest_Order_Volume
FROM (
    SELECT R.RegionID,
           R.RegionName as Region,
           COUNT(DISTINCT O.OrderID) AS Order_Volume
    FROM Regions R
    INNER JOIN Customers C
        ON R.RegionID = C.RegionID
    INNER JOIN Orders O
        ON C.CustomerID = O.CustomerID
    WHERE O.IsReturned = 0
    GROUP BY R.RegionID, R.RegionName
) AS T;
         
-- With Region Name

SELECT R.RegionID,
       R.RegionName,
       COUNT(DISTINCT O.OrderID) AS Order_Volume
FROM Regions R
INNER JOIN Customers C
    ON R.RegionID = C.RegionID
INNER JOIN Orders O
    ON C.CustomerID = O.CustomerID
WHERE O.IsReturned = 0
GROUP BY R.RegionID, R.RegionName
ORDER BY Order_Volume DESC;

-- 5.2.	What is the revenue per region and how does it compare across different regions?

Select R.RegionID,
	   R.RegionName,
       sum(P.Price * od.Quantity) as Revenue
from regions as R
inner join customers as c
on R.RegionID = c.RegionID
inner join orders o
on c.CustomerID = o.CustomerID
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID
where o.IsReturned = 0
group by R.RegionID,
	   R.RegionName
order by Revenue desc;



-- 6.	Return & Refund Insights



-- 6.1.	What is the overall return rate by product category?

Select P.Category,
       count(distinct o.OrderID) as Total_orders,
       count(distinct case
             when o.IsReturned = 1 then o.OrderID end) as Returned_orders,
	   round(count(distinct case
             when o.IsReturned = 1 then o.OrderID end) * 100
			/(count(distinct o.OrderID)),2) as Return_rate
            
from orders as o
inner join orderdetails as od
on o.OrderID = od.OrderID
inner join products as p
on od.ProductID = p.ProductID
group by P.Category
order by Return_rate desc;

-- 6.2.	What is the overall return rate by region?

Select R.RegionID, R.RegionName,
count(distinct o.OrderID) as Total_orders,
count(distinct case when o.IsReturned = 1 then o.OrderID end) as Returned_orders,
round(count(distinct case when o.IsReturned = 1 then o.OrderID end) *100/
	  (count(distinct o.OrderId)),2) as Return_rate
      
from regions as R
inner join Customers as c
on R.RegionID = c.RegionID
inner join orders as o 
on c.CustomerID=o.CustomerID
group by R.RegionID, R.RegionName
order by Return_rate desc;

-- 6.3.	Which customers are making frequent returns?

Select c.CustomerID,c.CustomerName,
count(distinct o.OrderID) as Total_orders,
count(distinct case when O.IsReturned = 1 then o.OrderID end) as Returned_orders,
round(count(distinct case when O.IsReturned = 1 then o.OrderID end)*100/
      count(distinct o.OrderID),2) as Return_rate
from customers as c
inner join orders as o
on c.CustomerID = o.CustomerID
group by c.CustomerID,c.CustomerName
having Returned_orders > 0
order by Returned_orders desc, Return_rate desc;

-- 6.4.	Overall return rate

SELECT
    COUNT(*) AS Total_Orders,

    SUM(CASE
        WHEN IsReturned = TRUE THEN 1
        ELSE 0
    END) AS Returned_Orders,

    ROUND(
        SUM(CASE
            WHEN IsReturned = TRUE THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS Return_Rate

FROM Orders;
