## What is the total amount each customer spent at the restaurant?

select s.customer_id,
sum(m.price) as tot_spent
from sales as s
inner join menu m on m.product_id = s.product_id
group by 1;

## How many days has each customer visited the restaurant?

select customer_id ,
count(distinct order_date) as visited_restaurant
from sales
group by customer_id ;

------------------------------------

## What was the first item from the menu purchased by each customer?

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

 ## 4. WHAT IS THE MOST PURCHASED ITEM ON THE MENU AND HOW MANY TIMES WAS IT 
## PURCHASED BY ALL CUSTOMERS?

select m.product_name,
count(m.product_name) as no_of_times
from sales as s
inner join menu as m on m.product_id = s.product_id
group by m.product_name
order by no_of_times desc
limit 1;

##5. WHICH ITEM WAS THE MOST POPULAR FOR EACH CUSTOMER?

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
 
##6. WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER

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
    WHERE s.order_date >mb.join_date
)
SELECT customer_id, product_name
FROM orders
WHERE rn = 1;

#### 7. WHICH ITEM WAS PURCHASED JUST BEFORE THE CUSTOMER BECAME A MEMBER?

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
 
 
 
 -- Select the items purchased just before the customer became a member

WITH CTE AS (
    SELECT  
        s.customer_id,  
        s.order_date, 
        mem.join_date, 
        m.product_name,  
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
    FROM  
        sales AS s 
    INNER JOIN 
        menu AS m ON s.product_id = m.product_id 
    INNER JOIN 
        members AS mem ON mem.customer_id = s.customer_id  
    WHERE  
        s.order_date < mem.join_date
)
SELECT 
    customer_id, 
    product_name, 
    order_date
FROM 
    CTE  
WHERE  
    rnk = 1
ORDER BY
    customer_id;

)  
SELECT CUSTOMER_ID, PRODUCT_NAME 
FROM CTE  
WHERE  
RNK = 1; 
 
 
 
 
#-#WHAT IS THE TOTAL ITEMS AND AMOUNT SPENT FOR EACH MEMBER BEFORE THEY BECAME A MEMBER?

select s.customer_id,
count(m.product_id) as tot_items,
sum(m.price) as tot_spent
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
JOIN members AS mb ON mb.customer_id = s.customer_id
WHERE s.order_date < mb.join_date
group by s.customer_id
order by s.customer_id;

##9. IF EACH $1 SPENT EQUATES TO 10 POINTS AND SUSHI HAS A 2X POINTS MULTIPLIER HOW MANY POINTS WOULD EACH CUSTOMER HAVE?

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


## ---10. IN THE FIRST WEEK AFTER A CUSTOMER JOINS THE PROGRAM (INCLUDING THEIR JOIN DATE) -----
  #---THEY EARN 2X POINTS ON ALL ITEMS AFTER THAT 1X, NOT JUST SUSHI  ----
  # ---HOW MANY POINTS DO CUSTOMER A AND B HAVE AT THE END OF JANUARY?

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

#11. Bonus Questions : Join All The Things

SELECT S.CUSTOMER_ID, ORDER_DATE, PRODUCT_NAME, PRICE,  
     CASE  
       WHEN ORDER_DATE <= JOIN_DATE THEN 'N'  
    ELSE 'Y'  
   END AS MEMBER  
FROM SALES AS S 
INNER JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID  
LEFT JOIN MEMBERS AS MEM ON MEM.CUSTOMER_ID = S.CUSTOMER_ID  
ORDER BY 1,2,3,4 DESC;

# - RANK ALL THNGS

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