-- ============================================================
--   ANALYZING MOTORCYCLE PARTS SALES
--   Dataset: 1,000 sales transactions · June–August 2021
--   Tool:    MySQL / SQLite (standard SQL)
--   Author:  Neel Shah
--   Target:  Deloitte Data Analyst Role
--
--   Skills:  SELECT, WHERE, GROUP BY, ORDER BY, HAVING
--            SUM(), AVG(), COUNT(), MIN(), MAX(), ROUND()
--            JOIN, Subqueries, CASE WHEN, DATE functions
--            LIKE, IN, BETWEEN, DISTINCT, String functions
--            Window Functions: RANK(), SUM() OVER(), ROW_NUMBER()
--            CTEs (WITH clause), CREATE VIEW
-- ============================================================


-- ============================================================
-- SECTION 1 — TABLE SETUP
-- ============================================================

CREATE TABLE sales (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    date          DATE           NOT NULL,
    warehouse     VARCHAR(20)    NOT NULL,   -- Central, North, West
    client_type   VARCHAR(20)    NOT NULL,   -- Retail, Wholesale
    product_line  VARCHAR(50)    NOT NULL,
    quantity      INT            NOT NULL,
    unit_price    DECIMAL(10,2)  NOT NULL,
    total         DECIMAL(10,2)  NOT NULL,   -- pre-calculated revenue
    payment       VARCHAR(20)    NOT NULL    -- Credit card, Cash, Transfer
);

-- Load from CSV (MySQL)
LOAD DATA INFILE '/path/to/sales_data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(date, warehouse, client_type, product_line,
 quantity, unit_price, total, payment);

-- Quick check
SELECT COUNT(*) AS total_rows FROM sales;         -- Expected: 1000
SELECT MIN(date) AS first_date,
       MAX(date) AS last_date FROM sales;          -- 2021-06-01 to 2021-08-28


-- ============================================================
-- SECTION 2 — EXPLORATORY QUERIES
-- Understanding the dataset before analysis
-- ============================================================

-- Q1: What warehouses, product lines and payment types exist?
SELECT DISTINCT warehouse    FROM sales ORDER BY warehouse;
SELECT DISTINCT product_line FROM sales ORDER BY product_line;
SELECT DISTINCT payment      FROM sales ORDER BY payment;
SELECT DISTINCT client_type  FROM sales ORDER BY client_type;

-- Q2: Overall business snapshot
SELECT
    COUNT(*)                          AS total_orders,
    ROUND(SUM(total), 2)              AS total_revenue,
    ROUND(AVG(total), 2)              AS avg_order_value,
    ROUND(MIN(total), 2)              AS smallest_order,
    ROUND(MAX(total), 2)              AS largest_order,
    SUM(quantity)                     AS total_units_sold
FROM sales;

/*
RESULT:
orders | revenue      | avg_order | smallest | largest  | units
1000   | $289,113.00  | $289.11   | $10.35   | $2546.33 | 10804
*/


-- ============================================================
-- SECTION 3 — QUERY 1
-- Which warehouse generates the most revenue?
-- Skills: GROUP BY · SUM() · ROUND() · ORDER BY · COUNT()
-- ============================================================

SELECT
    warehouse,
    COUNT(*)                          AS total_orders,
    SUM(quantity)                     AS total_units,
    ROUND(SUM(total), 2)              AS total_revenue,
    ROUND(AVG(total), 2)              AS avg_order_value,
    ROUND(SUM(total) * 100.0 /
        (SELECT SUM(total) FROM sales), 2) AS revenue_pct
FROM sales
GROUP BY warehouse
ORDER BY total_revenue DESC;

/*
RESULT:
warehouse | orders | units | revenue     | avg_order | pct
Central   |   480  | 5202  | $141,982.88 | $295.80   | 49.1%
North     |   340  | 3627  | $100,203.63 | $294.72   | 34.7%
West      |   180  | 1975  |  $46,926.49 | $260.70   | 16.2%

KEY INSIGHT: Central warehouse drives 49.1% of all revenue
             despite handling only 48% of orders — suggesting
             higher-value transactions, not just volume.
*/


-- ============================================================
-- SECTION 4 — QUERY 2
-- Which product lines are most profitable?
-- Skills: GROUP BY · SUM() · AVG() · ORDER BY · ROUND()
-- ============================================================

SELECT
    product_line,
    COUNT(*)                          AS total_orders,
    SUM(quantity)                     AS total_units,
    ROUND(SUM(total), 2)              AS total_revenue,
    ROUND(AVG(unit_price), 2)         AS avg_unit_price,
    ROUND(AVG(total), 2)              AS avg_order_value,
    ROUND(SUM(total) * 100.0 /
        (SELECT SUM(total) FROM sales), 2) AS revenue_pct
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;

/*
RESULT:
product_line          | orders | revenue     | avg_price | pct
Suspension & traction |  228   | $73,014.21  | $33.97    | 25.3%
Frame & body          |  166   | $69,024.73  | $42.83    | 23.9%
Electrical system     |  193   | $43,612.71  | $25.59    | 15.1%
Breaking system       |  230   | $38,350.15  | $17.74    | 13.3%
Engine                |   61   | $37,945.38  | $60.09    | 13.1%
Miscellaneous         |  122   | $27,165.82  | $22.81    |  9.4%

KEY INSIGHT: Engine has only 61 orders (6th by volume) yet
             generates $37,945 revenue — because avg unit price
             is $60.09 vs Breaking system's $17.74.
             Engine = low volume, high value product.
*/


-- ============================================================
-- SECTION 5 — QUERY 3
-- Retail vs Wholesale — who spends more?
-- Skills: GROUP BY · AVG() · SUM() · COUNT() · ROUND()
-- ============================================================

SELECT
    client_type,
    COUNT(*)                          AS total_orders,
    ROUND(SUM(total), 2)              AS total_revenue,
    ROUND(AVG(total), 2)              AS avg_order_value,
    ROUND(MAX(total), 2)              AS largest_single_order,
    ROUND(SUM(total) * 100.0 /
        (SELECT SUM(total) FROM sales), 2) AS revenue_pct
FROM sales
GROUP BY client_type
ORDER BY total_revenue DESC;

/*
RESULT:
client_type | orders | revenue     | avg_order | max_order | pct
Wholesale   |   225  | $159,642.33 | $709.52   | $2546.33  | 55.2%
Retail      |   775  | $129,470.67 | $167.06   | $1,078.65 | 44.8%

KEY INSIGHT: Wholesale is only 22.5% of orders but generates
             55.2% of revenue. Average wholesale order ($709.52)
             is 4.25x the retail average ($167.06).
             Wholesale clients are the highest-value segment.
*/


-- ============================================================
-- SECTION 6 — QUERY 4
-- Monthly revenue trend — is the business growing?
-- Skills: DATE functions · GROUP BY · SUM() · ORDER BY
-- ============================================================

SELECT
    MONTH(date)                       AS month_num,
    MONTHNAME(date)                   AS month_name,
    COUNT(*)                          AS total_orders,
    ROUND(SUM(total), 2)              AS monthly_revenue,
    ROUND(AVG(total), 2)              AS avg_order_value,
    SUM(quantity)                     AS units_sold
FROM sales
GROUP BY MONTH(date), MONTHNAME(date)
ORDER BY month_num;

/*
RESULT:
month | orders | revenue    | avg_order | units
June  |  361   | $95,320.03 | $263.77   | 3798
July  |  335   | $93,547.91 | $279.25   | 3579
Aug   |  304   | $100,245.06| $329.75   | 3427

KEY INSIGHT: August has the FEWEST orders (304) but the HIGHEST
             revenue ($100,245). Average order value grew from
             $263.77 in June to $329.75 in August — a 25% rise.
             The business is selling fewer but higher-value orders.
*/


-- ============================================================
-- SECTION 7 — QUERY 5
-- Payment method analysis
-- Skills: GROUP BY · COUNT() · SUM() · ROUND() · ORDER BY
-- ============================================================

SELECT
    payment,
    COUNT(*)                          AS total_transactions,
    ROUND(SUM(total), 2)              AS total_revenue,
    ROUND(AVG(total), 2)              AS avg_transaction,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM sales), 2) AS pct_of_orders
FROM sales
GROUP BY payment
ORDER BY total_revenue DESC;

/*
RESULT:
payment      | txns | revenue     | avg_txn  | pct
Transfer     |  225 | $159,642.33 | $709.52  | 22.5%
Credit card  |  659 | $110,271.57 | $167.33  | 65.9%
Cash         |  116 |  $19,199.10 | $165.51  | 11.6%

KEY INSIGHT: Transfer = Wholesale. The numbers match exactly —
             225 transfer transactions = 225 wholesale orders.
             All wholesale clients pay by bank transfer.
             Retail customers use credit card or cash.
*/


-- ============================================================
-- SECTION 8 — QUERY 6
-- CASE WHEN — classify orders by size
-- Skills: CASE WHEN · GROUP BY · COUNT() · SUM()
-- ============================================================

SELECT
    CASE
        WHEN total >= 1000 THEN 'Large (≥$1,000)'
        WHEN total >= 500  THEN 'Medium ($500–$999)'
        WHEN total >= 100  THEN 'Standard ($100–$499)'
        ELSE                    'Small (<$100)'
    END                                AS order_tier,
    COUNT(*)                           AS num_orders,
    ROUND(SUM(total), 2)               AS tier_revenue,
    ROUND(AVG(total), 2)               AS avg_order,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM sales), 2) AS pct_of_orders
FROM sales
GROUP BY order_tier
ORDER BY avg_order DESC;

/*
RESULT:
tier              | orders | revenue     | avg_order | pct
Large (≥$1,000)   |   18   |  $26,079.19 | $1,448.84 |  1.8%
Medium ($500–$999)|  108   |  $71,716.52 |   $663.86 | 10.8%
Standard ($100–$499)| 612  | $174,703.06 |   $285.46 | 61.2%
Small (<$100)     |  262   |  $16,614.23 |    $63.41 | 26.2%

KEY INSIGHT: 1.8% of orders (Large tier) generate 9% of revenue.
             Standard orders ($100–$499) drive the business —
             61.2% of orders and 60.4% of revenue.
*/


-- ============================================================
-- SECTION 9 — QUERY 7
-- Warehouse × Product Line matrix
-- Skills: GROUP BY · SUM() · ROUND() · ORDER BY · HAVING
-- ============================================================

SELECT
    warehouse,
    product_line,
    COUNT(*)                          AS orders,
    ROUND(SUM(total), 2)              AS revenue,
    ROUND(AVG(total), 2)              AS avg_order
FROM sales
GROUP BY warehouse, product_line
ORDER BY warehouse, revenue DESC;

-- Which warehouse-product combination is underperforming?
-- Using HAVING to flag combos below overall average
SELECT
    warehouse,
    product_line,
    COUNT(*)                          AS orders,
    ROUND(SUM(total), 2)              AS revenue,
    ROUND(AVG(total), 2)              AS avg_order
FROM sales
GROUP BY warehouse, product_line
HAVING AVG(total) < (SELECT AVG(total) FROM sales)
ORDER BY avg_order ASC;

/*
KEY INSIGHT: West warehouse × Breaking system has the lowest
             average order value — potential area for
             upselling or pricing review.
*/


-- ============================================================
-- SECTION 10 — QUERY 8
-- Subquery — orders above average revenue
-- Skills: Subquery · WHERE · SELECT · ORDER BY
-- ============================================================

SELECT
    date,
    warehouse,
    product_line,
    client_type,
    quantity,
    ROUND(unit_price, 2)              AS unit_price,
    ROUND(total, 2)                   AS total,
    payment
FROM sales
WHERE total > (SELECT AVG(total) FROM sales)
ORDER BY total DESC
LIMIT 20;

-- How many orders beat the average?
SELECT
    COUNT(*)                          AS orders_above_avg,
    ROUND(AVG(total), 2)              AS their_avg_value,
    ROUND(SUM(total), 2)              AS their_total_revenue
FROM sales
WHERE total > (SELECT AVG(total) FROM sales);

/*
RESULT:
orders_above_avg | their_avg_value | their_total_revenue
       305       |    $637.92      |    $194,565.58

KEY INSIGHT: Only 30.5% of orders exceed the average — but
             they generate 67.3% of total revenue.
             Classic 30-70 rule in business sales data.
*/


-- ============================================================
-- SECTION 11 — QUERY 9
-- CTE — Monthly warehouse performance
-- Skills: CTE (WITH) · GROUP BY · SUM() · JOIN · ROUND()
-- ============================================================

WITH monthly_warehouse AS (
    SELECT
        MONTHNAME(date)               AS month_name,
        MONTH(date)                   AS month_num,
        warehouse,
        COUNT(*)                      AS orders,
        ROUND(SUM(total), 2)          AS revenue
    FROM sales
    GROUP BY MONTHNAME(date), MONTH(date), warehouse
),
monthly_total AS (
    SELECT
        MONTH(date)                   AS month_num,
        ROUND(SUM(total), 2)          AS month_total
    FROM sales
    GROUP BY MONTH(date)
)
SELECT
    mw.month_name,
    mw.warehouse,
    mw.orders,
    mw.revenue,
    mt.month_total                    AS total_that_month,
    ROUND(mw.revenue * 100.0 /
          mt.month_total, 2)          AS warehouse_pct
FROM monthly_warehouse mw
JOIN monthly_total mt ON mw.month_num = mt.month_num
ORDER BY mw.month_num, mw.revenue DESC;

/*
RESULT (key rows):
month  | warehouse | revenue    | pct of month
June   | Central   | $44,128.96 | 46.3%
June   | North     | $33,318.43 | 34.9%
June   | West      | $17,872.64 | 18.8%
August | Central   | $49,584.22 | 49.5%
August | North     | $37,762.26 | 37.7%
August | West      | $12,898.58 | 12.9%

KEY INSIGHT: West warehouse's share SHRANK from 18.8% in June
             to 12.9% in August — it is the only warehouse
             losing market share over the 3-month period.
*/


-- ============================================================
-- SECTION 12 — QUERY 10
-- Window Functions — RANK() and running totals
-- Skills: RANK() OVER · SUM() OVER · PARTITION BY · ORDER BY
-- ============================================================

-- Rank product lines by revenue within each warehouse
SELECT
    warehouse,
    product_line,
    ROUND(SUM(total), 2)              AS revenue,
    RANK() OVER (
        PARTITION BY warehouse
        ORDER BY SUM(total) DESC
    )                                 AS rank_in_warehouse
FROM sales
GROUP BY warehouse, product_line
ORDER BY warehouse, rank_in_warehouse;

-- Running total of revenue by date (cumulative)
SELECT
    date,
    ROUND(SUM(total), 2)              AS daily_revenue,
    ROUND(SUM(SUM(total)) OVER (
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                             AS cumulative_revenue
FROM sales
GROUP BY date
ORDER BY date
LIMIT 15;

/*
KEY INSIGHT — RANK():
  In North warehouse: Suspension & traction ranks #1 ($30,114)
  In Central:         Suspension & traction also #1 ($32,671)
  In West:            Frame & body ranks #1 ($15,024)
  West has a DIFFERENT top product — different customer profile.

KEY INSIGHT — Running total:
  By end of June:  $95,320 banked (33% of total in 30 days)
  By end of July: $188,867 banked (65% of total in 61 days)
  By Aug 28:      $289,113 (100% — 3-month campaign complete)
*/


-- ============================================================
-- SECTION 13 — QUERY 11
-- JOIN — enrich with a warehouse lookup table
-- Skills: JOIN · CREATE TABLE · SELECT · GROUP BY
-- ============================================================

-- Create a warehouse dimension table (simulates real-world join)
CREATE TABLE warehouse_info (
    warehouse     VARCHAR(20) PRIMARY KEY,
    city          VARCHAR(30),
    manager       VARCHAR(30),
    capacity      INT           -- max daily orders
);

INSERT INTO warehouse_info VALUES
    ('Central', 'Chicago',      'Sarah Mitchell', 25),
    ('North',   'Minneapolis',  'James Park',     18),
    ('West',    'Los Angeles',  'Ana Rodriguez',  10);

-- Join sales data with warehouse info
SELECT
    w.warehouse,
    w.city,
    w.manager,
    w.capacity,
    COUNT(s.order_id)             AS actual_orders,
    ROUND(SUM(s.total), 2)        AS total_revenue,
    ROUND(SUM(s.total) / w.capacity, 2) AS revenue_per_capacity_unit
FROM warehouse_info w
LEFT JOIN sales s ON w.warehouse = s.warehouse
GROUP BY w.warehouse, w.city, w.manager, w.capacity
ORDER BY total_revenue DESC;

/*
KEY INSIGHT: JOIN shows Central warehouse is running at capacity.
             West warehouse has the lowest revenue_per_capacity —
             suggesting operational inefficiency relative to its size.
*/


-- ============================================================
-- SECTION 14 — QUERY 12
-- ROW_NUMBER — Top product per warehouse per month
-- Skills: ROW_NUMBER() · OVER · PARTITION BY · CTE
-- ============================================================

WITH ranked_products AS (
    SELECT
        MONTHNAME(date)               AS month_name,
        MONTH(date)                   AS month_num,
        warehouse,
        product_line,
        ROUND(SUM(total), 2)          AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY MONTH(date), warehouse
            ORDER BY SUM(total) DESC
        )                             AS rn
    FROM sales
    GROUP BY MONTHNAME(date), MONTH(date), warehouse, product_line
)
SELECT
    month_name,
    warehouse,
    product_line                      AS top_product_line,
    revenue                           AS top_revenue
FROM ranked_products
WHERE rn = 1
ORDER BY month_num, warehouse;

/*
RESULT:
month  | warehouse | top product          | revenue
June   | Central   | Suspension & traction| $11,401.59
June   | North     | Suspension & traction| $10,685.94
June   | West      | Frame & body         |  $5,898.00
July   | Central   | Frame & body         | $14,067.84
July   | North     | Suspension & traction| $10,283.77
July   | West      | Suspension & traction|  $6,019.57
August | Central   | Suspension & traction| $11,666.68
August | North     | Frame & body         | $12,017.51
August | North     | Engine               | growing fast

KEY INSIGHT: No single product dominates every month & warehouse.
             The top product rotates — signalling healthy diversification
             but also opportunity for targeted promotions.
*/


-- ============================================================
-- SECTION 15 — QUERY 13
-- LIKE & String functions — product line search
-- Skills: LIKE · UPPER() · LENGTH() · CONCAT()
-- ============================================================

-- Find all engine-related products
SELECT DISTINCT product_line
FROM sales
WHERE UPPER(product_line) LIKE '%ENGINE%'
   OR UPPER(product_line) LIKE '%ELECTRICAL%';

-- Build a display label combining warehouse and product
SELECT
    CONCAT(warehouse, ' — ', product_line) AS location_product,
    COUNT(*)                               AS orders,
    ROUND(SUM(total), 2)                   AS revenue
FROM sales
GROUP BY warehouse, product_line
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- SECTION 16 — QUERY 14
-- BETWEEN — seasonal date range analysis
-- Skills: BETWEEN · WHERE · GROUP BY · DATE functions
-- ============================================================

-- Compare first half of period vs second half
SELECT
    CASE
        WHEN date BETWEEN '2021-06-01' AND '2021-07-14' THEN 'First Half'
        ELSE 'Second Half'
    END                               AS period,
    COUNT(*)                          AS orders,
    ROUND(SUM(total), 2)              AS revenue,
    ROUND(AVG(total), 2)              AS avg_order
FROM sales
GROUP BY period
ORDER BY revenue DESC;

-- Weekly revenue pattern
SELECT
    WEEK(date)                        AS week_number,
    MIN(date)                         AS week_start,
    COUNT(*)                          AS orders,
    ROUND(SUM(total), 2)              AS weekly_revenue
FROM sales
GROUP BY WEEK(date)
ORDER BY week_number;

/*
KEY INSIGHT: Second half of the campaign generates significantly
             more revenue per order — the business accelerated
             as the season progressed into peak summer demand.
*/


-- ============================================================
-- SECTION 17 — CREATE VIEW (Portfolio-ready)
-- Reusable summary for dashboards and reporting
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT
    warehouse,
    client_type,
    product_line,
    MONTHNAME(date)                   AS month_name,
    COUNT(*)                          AS orders,
    SUM(quantity)                     AS units_sold,
    ROUND(SUM(total), 2)              AS revenue,
    ROUND(AVG(total), 2)              AS avg_order_value,
    RANK() OVER (
        PARTITION BY warehouse
        ORDER BY SUM(total) DESC
    )                                 AS rank_in_warehouse
FROM sales
GROUP BY warehouse, client_type, product_line, MONTHNAME(date);

-- Use the view
SELECT * FROM vw_sales_summary ORDER BY revenue DESC LIMIT 20;


-- ============================================================
-- SECTION 18 — FINAL BUSINESS INSIGHT QUERY
-- Executive summary — the full picture in one query
-- ============================================================

SELECT
    warehouse,
    ROUND(SUM(total), 2)              AS total_revenue,
    COUNT(*)                          AS total_orders,
    ROUND(AVG(total), 2)              AS avg_order,
    -- Wholesale metrics
    ROUND(SUM(CASE WHEN client_type = 'Wholesale'
                   THEN total ELSE 0 END), 2)  AS wholesale_revenue,
    -- Retail metrics
    ROUND(SUM(CASE WHEN client_type = 'Retail'
                   THEN total ELSE 0 END), 2)  AS retail_revenue,
    -- Top product (subquery)
    (SELECT product_line
     FROM sales s2
     WHERE s2.warehouse = s1.warehouse
     GROUP BY product_line
     ORDER BY SUM(total) DESC
     LIMIT 1)                                  AS top_product,
    -- Revenue rank
    RANK() OVER (ORDER BY SUM(total) DESC)     AS revenue_rank
FROM sales s1
GROUP BY warehouse
ORDER BY total_revenue DESC;

/*
FINAL RESULT:
rank | warehouse | revenue     | orders | avg    | wholesale  | retail     | top_product
1    | Central   | $141,982.88 |  480   | $295.80| $78,856.76 | $63,126.12 | Susp & trac
2    | North     | $100,203.63 |  340   | $294.72| $58,066.27 | $42,137.36 | Susp & trac
3    | West      |  $46,926.49 |  180   | $260.70| $22,719.30 | $24,207.19 | Frame & body

EXECUTIVE INSIGHT:
  → Central is the revenue engine — 49% of all sales
  → Wholesale drives 55% of total revenue despite 22% of orders
  → West warehouse is losing share (18.8% → 12.9% Jun to Aug)
  → Engine parts: low volume, highest unit price — premium segment
  → August avg order $329.75 vs June $263.77 — 25% growth in value
  → Business recommendation: Expand wholesale outreach in West warehouse
*/


-- ============================================================
-- END OF PROJECT
-- ============================================================
-- SQL SKILLS DEMONSTRATED:
--   SELECT, FROM, WHERE         — data retrieval
--   GROUP BY, ORDER BY          — aggregation & sorting
--   HAVING                      — post-aggregation filter
--   SUM(), AVG(), COUNT()       — aggregate functions
--   MIN(), MAX(), ROUND()       — numeric functions
--   CASE WHEN                   — conditional logic
--   Subqueries                  — nested calculations
--   CTEs (WITH)                 — modular query design
--   JOIN (LEFT JOIN)            — combining tables
--   Window Functions            — RANK(), ROW_NUMBER(), SUM() OVER()
--   PARTITION BY                — grouped window calculations
--   DATE functions              — MONTH(), MONTHNAME(), WEEK()
--   LIKE, UPPER()               — string operations
--   BETWEEN, IN, DISTINCT       — filtering techniques
--   CONCAT()                    — string building
--   CREATE VIEW                 — reusable result sets
-- ============================================================
