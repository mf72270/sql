/* ASSIGNMENT 2 */
/* SECTION 1 */

/*
--Prompt 3- a logical model for a small bookstore
The store wants to keep customer addresses. Propose two architectures for the CUSTOMER_ADDRESS table, one that will retain changes, and another that will overwrite. Which is type 1, which is type 2?
HINT: search type 1 vs type 2 slowly changing dimensions.*/
/*

/*Answer:
For the bookstore's customer address system, we can propose two different ways to set it up, depending on whether we want to keep a history of changes or not.

The Simple Overwrite Method (Type 1):

 We just have a single CUSTOMER_ADDRESS table, or more commonly, we put the address columns right in the main CUSTOMER table. 
 When a customer moves and gives us a new address, we simply overwrite the old one. It's clean and efficient. 
 The downside is that we completely lose the historical record of where they lived before. This is called a Type 1 

The Historical Tracking Method (Type 2):

 This method is for when we need to keep a full history of every change. Instead of one address per customer, we create a separate CUSTOMER_ADDRESS table that can hold multiple addresses for each person. 
 Each address record has dates showing when it was active (start_date, end_date) and a flag marking which one is current (is_current). When a customer moves, we end-date the old address and add a new record for the new one. 
 This lets us see exactly where a customer lived when they placed each past order. This is called a Type 2 */


/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */
   
--Finding NULL:  
   SELECT   product_name, product_size, product_qty_type 
FROM product 
WHERE product_name IS NULL 
   OR product_size IS NULL 
   OR product_qty_type IS NULL;
   
--Original from question  query with NULL issues : 
   SELECT 
    product_name || ', ' || product_size || ' (' || product_qty_type || ')'
FROM product;

--Fixed query using COALESCE function and  returns  non-NULL value when they are NULL.
SELECT 
    product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;
 


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */


--Display all rows with ROW_NUMBER in the customer_purchases table  
SELECT customer_id, 
       market_date,
       product_id,
       vendor_id,
       quantity,
       cost_to_customer_per_qty,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) AS customer_visit_number
FROM customer_purchases
ORDER BY customer_id, market_date;


--Number each customer's visits.  
SELECT *, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date) AS customer_visit_number FROM customer_purchases;



/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--PART A
--Query to label most recent visit as 1 (most recent visit = 1):
SELECT customer_id,
       market_date,
       product_id,
       vendor_id,
       quantity,
       cost_to_customer_per_qty,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number_desc
FROM customer_purchases
ORDER BY customer_id, market_date DESC;

--PART B
-- only most recent visit using subquery  
SELECT *
FROM (
    SELECT customer_id,
           market_date,
           product_id,
           vendor_id,
           quantity,
           cost_to_customer_per_qty,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number_desc
    FROM customer_purchases
) ranked_visits
WHERE visit_number_desc = 1;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

--Determine the purchase frequency of each product per customer.
SELECT customer_id,
       market_date,
       product_id,
       vendor_id,
       quantity,
       cost_to_customer_per_qty,
       COUNT(*) OVER (PARTITION BY customer_id, product_id) AS times_purchased_this_product
FROM customer_purchases
ORDER BY customer_id, product_id, market_date;



-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

-- String manipulations SQL query that extracts the description (like "Organic" or "Jar")

SELECT 
    product_name,
    TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1)) AS description
FROM product;



/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- UNION --Method using CTEs:
WITH daily_sales AS (
    SELECT market_date,
           SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
),
ranked_sales AS (
    SELECT market_date,
           total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank_desc,
           RANK() OVER (ORDER BY total_sales ASC) AS sales_rank_asc
    FROM daily_sales
)
SELECT market_date, total_sales, 'Highest Sales' AS sales_type
FROM ranked_sales
WHERE sales_rank_desc = 1

UNION

SELECT market_date, total_sales, 'Lowest Sales' AS sales_type
FROM ranked_sales
WHERE sales_rank_asc = 1;

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

---- Cross Join -Calculate potential earnings if all vendors sold 5 of every product to all customers. 
WITH vendor_products AS (
    SELECT DISTINCT ven_in.vendor_id, ven_in.product_id, ven_in.original_price
    FROM vendor_inventory ven_in
),
vendor_product_details AS (
    SELECT ven.vendor_name,
           pro.product_name,
           vp.original_price
    FROM vendor_products vp
    JOIN vendor ven ON vp.vendor_id = ven.vendor_id
    JOIN product pro ON vp.product_id = pro.product_id
),
customer_count AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM customer
)
SELECT vpd.vendor_name,
       vpd.product_name,
       (vpd.original_price * 5 * cuco.total_customers) AS potential_revenue
FROM vendor_product_details vpd
CROSS JOIN customer_count cuco
ORDER BY vpd.vendor_name, vpd.product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */


--Create the product_units Table   
CREATE TABLE product_units AS
SELECT *,
       CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

-- Insert a new product record (Apple Pie example) 
INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (999, 'Apple Pie', 'Large', 1, 'unit', CURRENT_TIMESTAMP);


-- DELETE
/* 1. Delete the older record for the whatever product you added. 
HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/



--Identify the Records to Delete 
SELECT * FROM product_units WHERE product_name = 'Apple Pie' ORDER BY snapshot_timestamp;

-- Delete the older timestamp record 
DELETE FROM product_units
WHERE product_name = 'Apple Pie' 
AND snapshot_timestamp = (
    SELECT MIN(snapshot_timestamp) 
    FROM product_units 
    WHERE product_name = 'Apple Pie'
);

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */



--Add the column
ALTER TABLE product_units
ADD current_quantity INT;

--UPDATE Statement  
--1=Gets the most recent recorded quantity of the product
--0=Default value applied if no inventory records are found.

UPDATE product_units
SET current_quantity = COALESCE(
    (SELECT quantity
     FROM vendor_inventory ven_in
     WHERE ven_in.product_id = product_units.product_id
     AND ven_in.market_date = (
         SELECT MAX(market_date)
         FROM vendor_inventory vi2
         WHERE vi2.product_id = product_units.product_id
     )
     LIMIT 1), 0)
WHERE product_units.product_id IN (
    SELECT DISTINCT product_id 
    FROM vendor_inventory
);


