--Danny's Dinner - Taste of Success  SOLUTION
--------------------------------------------------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) 
--     they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- 11.Bonus Questions : Join All The Things
-- 12. RANK ALL THNGS

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1. What is the total amount each customer spent at the restaurant?

select s.customer_id,
sum(m.price) as tot_spent
from sales as s
inner join menu m on m.product_id = s.product_id
group by 1;


--2. How many days has each customer visited the restaurant?

select customer_id ,
count(distinct order_date) as visited_restaurant
from sales
group by customer_id ;


--3.  What was the first item from the menu purchased by each customer?

SELECT customer_id, product_name
FROM (
    SELECT 
        s.customer_id,
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM sales AS s
    INNER JOIN menu AS m ON m.product_id = s.product_id
) AS FirstPurchase
WHERE rn = 1;

--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name,
count(m.product_name) as no_of_times
from sales as s
inner join menu as m on m.product_id = s.product_id
group by m.product_name
order by no_of_times desc
limit 1;


-- 5. Which item was the most popular for each customer?

SELECT customer_id, product_name
from (
select s.customer_id, m.product_name,
count(*) as order_count,
dense_rank() over (partition by customer_id order by count(*) desc) as rn
from sales s
inner join menu as m on m.product_id = s.product_id
group by s.customer_id, m.product_name
) as purchased_cnt
where rn = 1;

 
-- 6. Which item was purchased first by the customer after they became a member?

WITH orders AS (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        mb.join_date,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ) AS rn
    FROM menu AS m
    INNER JOIN sales AS s ON m.product_id = s.product_id
    JOIN members AS mb ON mb.customer_id = s.customer_id
    WHERE s.order_date > mb.join_date
)
SELECT customer_id, product_name
FROM orders
WHERE rn = 1;


-- 7. Which item was purchased just before the customer became a member?

WITH orders AS (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        mb.join_date,
       DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ) AS rn
    FROM menu AS m
    INNER JOIN sales AS s ON m.product_id = s.product_id
    JOIN members AS mb ON mb.customer_id = s.customer_id
    WHERE s.order_date < mb.join_date
)
SELECT customer_id, product_name
FROM orders
WHERE rn = 1;
 
 
-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,
count(m.product_id) as tot_items,
Sum(m.price) as tot_spent
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
JOIN members AS mb ON mb.customer_id = s.customer_id
WHERE s.order_date < mb.join_date
group by s.customer_id
order by s.customer_id;

--9. IF EACH $1 SPENT EQUATES TO 10 POINTS AND SUSHI HAS A 2X POINTS MULTIPLIER HOW MANY POINTS WOULD EACH CUSTOMER HAVE?

SELECT s.customer_id,
    SUM(
        CASE 
            WHEN m.product_name = 'Sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM 
    sales AS s
INNER JOIN 
    menu AS m ON s.product_id = m.product_id
GROUP BY 
    s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date)  they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH purchase_points AS (
    SELECT 
        s.customer_id,
        CASE 
            WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 7 DAY) THEN m.price * 20
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END AS points
     FROM menu AS m INNER JOIN sales AS s ON m.product_id = s.product_id
    INNER JOIN members AS mb ON mb.customer_id = s.customer_id
    WHERE 
        s.order_date <= '2024-01-31')
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM 
    purchase_points
    group by customer_id
    order by customer_id;


---11. Bonus Questions : Join All The Things

SELECT S.CUSTOMER_ID, ORDER_DATE, PRODUCT_NAME, PRICE,  
     CASE  
       WHEN ORDER_DATE <= JOIN_DATE THEN 'N'  
    ELSE 'Y'  
   END AS MEMBER  
FROM SALES AS S 
INNER JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID  
LEFT JOIN MEMBERS AS MEM ON MEM.CUSTOMER_ID = S.CUSTOMER_ID  
ORDER BY 1,2,3,4 DESC;


---12. - RANK ALL THNGS

WITH CTE AS (
SELECT S.CUSTOMER_ID, ORDER_DATE, PRODUCT_NAME, PRICE,  
     CASE  
       WHEN JOIN_DATE <= ORDER_DATE THEN 'Y'  
    ELSE 'N'  
   END AS MEMBER_STATUS
FROM SALES AS S 
JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID  
LEFT JOIN MEMBERS AS MEM ON MEM.CUSTOMER_ID = S.CUSTOMER_ID  
)
SELECT *, 
		CASE  
			WHEN CTE.MEMBER_STATUS = 'Y'  THEN RANK() OVER(PARTITION BY CUSTOMER_ID, MEMBER_STATUS ORDER BY ORDER_DATE)  
            ELSE NULL
       END AS RNK 
   FROM CTE; 
