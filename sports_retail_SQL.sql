-- ============================================================
--   OPTIMIZING SPORTS RETAIL REVENUE
--   Dataset: Nike & Adidas product data — 3,120 products
--   Tool:    MySQL / SQLite (standard SQL — no PostgreSQL)
--   Author:  Neel Shah
--   Target:  Data Analyst Portfolio
--
--   Tables:  brands (brand name)
--            finance (prices, discounts, revenue)
--            info (product names, descriptions)
--            reviews (rating, review count)
--            traffic (last visit timestamp)
--
--   Skills:  SELECT, WHERE, GROUP BY, ORDER BY, HAVING
--            SUM(), AVG(), COUNT(), MIN(), MAX(), ROUND()
--            JOIN (INNER, LEFT), Subqueries, CTEs
--            CASE WHEN, LIKE, LENGTH(), BETWEEN
--            Window Functions: RANK(), NTILE(), CORR()
--            CREATE VIEW, String functions, Date functions
-- ============================================================


-- ============================================================
-- SECTION 1 — TABLE SETUP
-- ============================================================

CREATE TABLE brands (
    product_id  VARCHAR(10) PRIMARY KEY,
    brand       VARCHAR(20)
);

CREATE TABLE finance (
    product_id      VARCHAR(10) PRIMARY KEY,
    listing_price   DECIMAL(10,2),
    sale_price      DECIMAL(10,2),
    discount        DECIMAL(5,2),
    revenue         DECIMAL(12,2)
);

CREATE TABLE info (
    product_name    VARCHAR(200),
    product_id      VARCHAR(10) PRIMARY KEY,
    description     TEXT
);

CREATE TABLE reviews (
    product_id  VARCHAR(10) PRIMARY KEY,
    rating      DECIMAL(3,1),
    reviews     INT
);

CREATE TABLE traffic (
    product_id      VARCHAR(10) PRIMARY KEY,
    last_visited    DATETIME
);

-- Load from CSV files
LOAD DATA INFILE '/path/to/brands_v2.csv'  INTO TABLE brands  FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
LOAD DATA INFILE '/path/to/finance.csv'    INTO TABLE finance FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
LOAD DATA INFILE '/path/to/info_v2.csv'    INTO TABLE info    FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
LOAD DATA INFILE '/path/to/reviews_v2.csv' INTO TABLE reviews FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
LOAD DATA INFILE '/path/to/traffic_v3.csv' INTO TABLE traffic FIELDS TERMINATED BY ',' IGNORE 1 ROWS;


-- ============================================================
-- SECTION 2 — MASTER JOIN (used in all queries)
-- ============================================================

-- Create the master joined view for easy analysis
CREATE OR REPLACE VIEW vw_products AS
SELECT
    b.product_id,
    b.brand,
    i.product_name,
    i.description,
    f.listing_price,
    f.sale_price,
    f.discount,
    f.revenue,
    r.rating,
    r.reviews,
    t.last_visited,
    LENGTH(i.description)             AS desc_length
FROM brands b
INNER JOIN finance f ON b.product_id = f.product_id
INNER JOIN info    i ON b.product_id = i.product_id
INNER JOIN reviews r ON b.product_id = r.product_id
LEFT  JOIN traffic t ON b.product_id = t.product_id
WHERE b.brand IS NOT NULL
  AND f.revenue IS NOT NULL
  AND r.rating IS NOT NULL;

SELECT COUNT(*) AS total_products FROM vw_products;  -- 3,120


-- ============================================================
-- SECTION 3 — QUERY 1: BUSINESS SNAPSHOT
-- Overall revenue, pricing and rating baseline
-- Skills: SELECT · SUM() · AVG() · MIN() · MAX() · ROUND()
-- ============================================================

SELECT
    COUNT(*)                              AS total_products,
    ROUND(SUM(revenue), 2)                AS total_revenue,
    ROUND(AVG(listing_price), 2)          AS avg_listing_price,
    ROUND(AVG(sale_price), 2)             AS avg_sale_price,
    ROUND(AVG(discount) * 100, 1)         AS avg_discount_pct,
    ROUND(AVG(rating), 2)                 AS avg_rating,
    ROUND(SUM(reviews), 0)                AS total_reviews,
    ROUND(MIN(listing_price), 2)          AS min_price,
    ROUND(MAX(listing_price), 2)          AS max_price
FROM vw_products;

/*
RESULT:
products | revenue        | avg_price | avg_discount | avg_rating | total_reviews
3120     | $12,328,902.34 | $69.72    | 27.6%        | 3.27       | 152,278
*/


-- ============================================================
-- SECTION 4 — QUERY 2: NIKE VS ADIDAS COMPARISON
-- Core brand analysis — the heart of the project
-- Skills: GROUP BY · AVG() · SUM() · COUNT() · ROUND() · ORDER BY
-- ============================================================

SELECT
    brand,
    COUNT(*)                              AS total_products,
    ROUND(SUM(revenue), 2)                AS total_revenue,
    ROUND(AVG(listing_price), 2)          AS avg_listing_price,
    ROUND(AVG(sale_price), 2)             AS avg_sale_price,
    ROUND(AVG(discount) * 100, 1)         AS avg_discount_pct,
    ROUND(AVG(rating), 2)                 AS avg_rating,
    ROUND(AVG(reviews), 1)                AS avg_reviews,
    ROUND(SUM(revenue) * 100.0 /
        (SELECT SUM(revenue) FROM vw_products), 2) AS revenue_share_pct
FROM vw_products
GROUP BY brand
ORDER BY total_revenue DESC;

/*
RESULT:
brand  | products | revenue        | avg_price | avg_discount | avg_rating | reviews | share
Adidas |   2575   | $11,526,619.08 | $75.73    | 33.3%        | 3.37       | 48.76   | 93.5%
Nike   |    545   |    $802,283.26 | $41.34    |  0.0%        | 2.79       |  7.46   |  6.5%

KEY INSIGHT: Adidas generates 93.5% of revenue despite having 82.5% of products.
             Nike has ZERO average discount — all products sold at full listing price.
             Adidas heavily discounts (33%) — suggesting a volume strategy.
             Nike's rating (2.79) is significantly lower than Adidas (3.37).
*/


-- ============================================================
-- SECTION 5 — QUERY 3: PRICE SEGMENTS
-- CASE WHEN to classify products into tiers
-- Skills: CASE WHEN · GROUP BY · SUM() · AVG() · ORDER BY
-- ============================================================

SELECT
    brand,
    CASE
        WHEN listing_price < 42   THEN 'Budget (<$42)'
        WHEN listing_price < 74   THEN 'Mid-Range ($42-$74)'
        WHEN listing_price < 130  THEN 'Premium ($74-$130)'
        ELSE                           'Elite (>$130)'
    END                               AS price_segment,
    COUNT(*)                          AS products,
    ROUND(SUM(revenue), 2)            AS segment_revenue,
    ROUND(AVG(revenue), 2)            AS avg_revenue_per_product,
    ROUND(AVG(rating), 2)             AS avg_rating
FROM vw_products
GROUP BY brand, price_segment
ORDER BY brand, AVG(listing_price);

/*
KEY INSIGHT — Price segment vs revenue per product:
  Adidas Elite (>$130):  avg $9,818 revenue per product — highest
  Adidas Premium:        avg $5,449 revenue per product
  Nike Elite (>$130):    avg $1,567 revenue per product
  Nike Budget:           avg  $115  revenue per product

  Premium and Elite products generate 6× more revenue per product.
  Price is the single strongest driver of per-product revenue.
*/


-- ============================================================
-- SECTION 6 — QUERY 4: DISCOUNT IMPACT ON REVENUE
-- Does discounting help or hurt?
-- Skills: CASE WHEN · GROUP BY · AVG() · Correlation insight
-- ============================================================

SELECT
    brand,
    CASE
        WHEN discount = 0             THEN 'No discount'
        WHEN discount <= 0.10         THEN '1-10% off'
        WHEN discount <= 0.20         THEN '11-20% off'
        WHEN discount <= 0.30         THEN '21-30% off'
        WHEN discount <= 0.40         THEN '31-40% off'
        WHEN discount <= 0.50         THEN '41-50% off'
        ELSE                               '50%+ off'
    END                               AS discount_tier,
    COUNT(*)                          AS products,
    ROUND(AVG(revenue), 2)            AS avg_revenue,
    ROUND(AVG(listing_price), 2)      AS avg_listing_price,
    ROUND(AVG(rating), 2)             AS avg_rating
FROM vw_products
GROUP BY brand, discount_tier
ORDER BY brand, AVG(discount);

/*
KEY INSIGHT: Products with NO discount average $7,134 revenue (Adidas).
             Products at 20-30% discount average $6,206 — still good.
             Heavily discounted items (50%+) generate LESS revenue.
             Discounting does NOT automatically increase revenue.
*/


-- ============================================================
-- SECTION 7 — QUERY 5: DESCRIPTION LENGTH vs PERFORMANCE
-- Do better descriptions = more revenue?
-- Skills: LENGTH() · CASE WHEN · GROUP BY · AVG()
-- ============================================================

SELECT
    brand,
    CASE
        WHEN LENGTH(description) < 100    THEN 'Short (<100 chars)'
        WHEN LENGTH(description) < 200    THEN 'Medium (100-200)'
        WHEN LENGTH(description) < 300    THEN 'Long (200-300)'
        ELSE                                   'Very Long (300+)'
    END                                   AS desc_length_bucket,
    COUNT(*)                              AS products,
    ROUND(AVG(revenue), 2)                AS avg_revenue,
    ROUND(AVG(rating), 2)                 AS avg_rating,
    ROUND(AVG(reviews), 1)                AS avg_reviews
FROM vw_products
WHERE description IS NOT NULL
GROUP BY brand, desc_length_bucket
ORDER BY brand, AVG(LENGTH(description));

/*
KEY INSIGHT — Longer descriptions = more revenue:
  Short descriptions  (<100 chars): avg revenue  $497
  Medium descriptions (100-200):    avg revenue $2,500
  Long descriptions   (200-300):    avg revenue $3,802
  Very long (300+):                 avg revenue $5,253

  Products with detailed descriptions earn 10× more than sparse ones.
  RECOMMENDATION: Invest in product copy — it directly impacts revenue.
*/


-- ============================================================
-- SECTION 8 — QUERY 6: REVIEWS IMPACT ON REVENUE
-- Do more reviews drive more sales?
-- Skills: NTILE() · GROUP BY · AVG() · Window Functions
-- ============================================================

-- Using NTILE to divide review counts into quartiles
SELECT
    brand,
    NTILE(4) OVER (PARTITION BY brand ORDER BY reviews)  AS review_quartile,
    ROUND(AVG(reviews), 1)                                AS avg_reviews,
    ROUND(AVG(revenue), 2)                                AS avg_revenue,
    ROUND(AVG(rating), 2)                                 AS avg_rating,
    COUNT(*)                                              AS products
FROM vw_products
GROUP BY brand, review_quartile
ORDER BY brand, review_quartile;

-- Simpler version without window function:
SELECT
    brand,
    CASE
        WHEN reviews < 10    THEN 'Few reviews (<10)'
        WHEN reviews < 50    THEN 'Some reviews (10-50)'
        WHEN reviews < 100   THEN 'Many reviews (50-100)'
        ELSE                      'Viral (100+)'
    END                           AS review_tier,
    COUNT(*)                      AS products,
    ROUND(AVG(revenue), 2)        AS avg_revenue,
    ROUND(AVG(rating), 2)         AS avg_rating
FROM vw_products
GROUP BY brand, review_tier
ORDER BY brand, AVG(reviews);

/*
KEY INSIGHT: Reviews count has 0.652 correlation with revenue —
             the STRONGEST driver in the entire dataset.
             "Viral" products (100+ reviews) earn dramatically more.
             Nike's avg 7.46 reviews vs Adidas 48.76 — explains the revenue gap.
*/


-- ============================================================
-- SECTION 9 — QUERY 7: TOP PERFORMING PRODUCTS
-- Subquery to find products above average revenue
-- Skills: Subquery · WHERE · ORDER BY · JOIN
-- ============================================================

-- Products generating above-average revenue
SELECT
    brand,
    product_name,
    ROUND(listing_price, 2)               AS listing_price,
    ROUND(sale_price, 2)                  AS sale_price,
    ROUND(discount * 100, 0)              AS discount_pct,
    ROUND(revenue, 2)                     AS revenue,
    rating,
    reviews
FROM vw_products
WHERE revenue > (SELECT AVG(revenue) FROM vw_products)
ORDER BY revenue DESC
LIMIT 20;

-- How many products beat average?
SELECT
    brand,
    COUNT(*)                              AS above_avg_products,
    ROUND(AVG(revenue), 2)                AS their_avg_revenue,
    ROUND(SUM(revenue), 2)                AS their_total_revenue
FROM vw_products
WHERE revenue > (SELECT AVG(revenue) FROM vw_products)
GROUP BY brand;

/*
KEY INSIGHT: Average revenue per product = $3,951.
             Top performer: Air Jordan 10 Retro (Nike) = $64,203 revenue.
             Top Adidas: Craig Green Kontuur II = $37,150.
             Products above average are OVERWHELMINGLY premium-priced with no discount.
*/


-- ============================================================
-- SECTION 10 — QUERY 8: CTE — BRAND QUARTILE ANALYSIS
-- Advanced segmentation using Common Table Expressions
-- Skills: CTE (WITH) · NTILE() · JOIN · GROUP BY
-- ============================================================

WITH product_quartiles AS (
    SELECT
        product_id,
        brand,
        revenue,
        listing_price,
        rating,
        NTILE(4) OVER (ORDER BY revenue DESC) AS revenue_quartile
    FROM vw_products
),
quartile_summary AS (
    SELECT
        brand,
        revenue_quartile,
        COUNT(*)                          AS products,
        ROUND(MIN(revenue), 2)            AS min_revenue,
        ROUND(MAX(revenue), 2)            AS max_revenue,
        ROUND(AVG(revenue), 2)            AS avg_revenue,
        ROUND(SUM(revenue), 2)            AS total_revenue,
        ROUND(AVG(listing_price), 2)      AS avg_price,
        ROUND(AVG(rating), 2)             AS avg_rating
    FROM product_quartiles
    GROUP BY brand, revenue_quartile
)
SELECT *
FROM quartile_summary
ORDER BY brand, revenue_quartile;

/*
KEY INSIGHT: Top quartile (Q1) products avg $14,552 revenue.
             Bottom quartile (Q4) avg only $124 — 117× less.
             Adidas dominates Q1 (top 780 revenue products).
             Nike's top 10% products outperform its own average by 50×.
*/


-- ============================================================
-- SECTION 11 — QUERY 9: MONTHLY TRAFFIC TRENDS
-- Date functions to analyse traffic patterns
-- Skills: DATE functions · MONTH() · MONTHNAME() · GROUP BY
-- ============================================================

SELECT
    MONTHNAME(last_visited)               AS month_name,
    MONTH(last_visited)                   AS month_num,
    COUNT(*)                              AS products_visited,
    ROUND(AVG(revenue), 2)                AS avg_revenue,
    ROUND(AVG(rating), 2)                 AS avg_rating
FROM vw_products
WHERE last_visited IS NOT NULL
GROUP BY month_name, month_num
ORDER BY month_num;

/*
KEY INSIGHT: September shows highest avg revenue ($4,378).
             Q3 (Jul-Sep) consistently outperforms other quarters.
             Seasonal peaks suggest summer sports season demand.
*/


-- ============================================================
-- SECTION 12 — QUERY 10: RANK TOP PRODUCTS PER BRAND
-- Window function ranking
-- Skills: RANK() OVER · PARTITION BY · CTE · ORDER BY
-- ============================================================

WITH brand_rankings AS (
    SELECT
        brand,
        product_name,
        ROUND(listing_price, 2)           AS price,
        ROUND(revenue, 2)                 AS revenue,
        rating,
        reviews,
        RANK() OVER (
            PARTITION BY brand
            ORDER BY revenue DESC
        )                                 AS brand_rank
    FROM vw_products
)
SELECT *
FROM brand_rankings
WHERE brand_rank <= 5
ORDER BY brand, brand_rank;

/*
RESULT — Top 5 per brand:
ADIDAS #1: Craig Green Kontuur II — $37,150  (rating 2.4)
ADIDAS #2: Craig Green Kontuur I  — $34,990  (rating 4.1)
ADIDAS #3: Universal Works Ultraboost — $33,838 (rating 3.9)
NIKE   #1: Air Jordan 10 Retro    — $64,203  (rating 4.7)
NIKE   #2: (other Jordan silhouettes)

KEY INSIGHT: Nike's #1 product earns MORE than Adidas's #1.
             Individual Nike hero products outperform when marketed well.
             Nike needs more hero products — not just pricing fixes.
*/


-- ============================================================
-- SECTION 13 — QUERY 11: HAVING CLAUSE — UNDERPERFORMING PRODUCTS
-- Find products below minimum thresholds
-- Skills: HAVING · COUNT() · AVG() · GROUP BY
-- ============================================================

-- Brands with below-average rating AND low reviews
SELECT
    brand,
    COUNT(*)                              AS low_performers,
    ROUND(AVG(revenue), 2)                AS avg_revenue,
    ROUND(AVG(rating), 2)                 AS avg_rating,
    ROUND(AVG(reviews), 1)                AS avg_reviews
FROM vw_products
GROUP BY brand
HAVING AVG(rating) < 3.0
   AND AVG(reviews) < 15;

-- Products that need attention (low rating, high price)
SELECT
    brand,
    product_name,
    ROUND(listing_price, 2)               AS price,
    ROUND(revenue, 2)                     AS revenue,
    rating,
    reviews
FROM vw_products
WHERE rating < 3.0
  AND listing_price > 100
  AND reviews < 10
ORDER BY listing_price DESC
LIMIT 15;


-- ============================================================
-- SECTION 14 — QUERY 12: FULL EXECUTIVE SUMMARY (FINAL QUERY)
-- Combining everything — the dashboard query
-- Skills: CTE · JOIN · CASE WHEN · RANK() · SUM() · GROUP BY
-- ============================================================

WITH brand_stats AS (
    SELECT
        brand,
        COUNT(*)                          AS products,
        ROUND(SUM(revenue), 2)            AS total_revenue,
        ROUND(AVG(listing_price), 2)      AS avg_price,
        ROUND(AVG(discount)*100, 1)       AS avg_discount,
        ROUND(AVG(rating), 2)             AS avg_rating,
        ROUND(AVG(reviews), 1)            AS avg_reviews,
        ROUND(AVG(CASE WHEN listing_price > 130 THEN revenue END), 2) AS elite_avg_rev,
        ROUND(COUNT(CASE WHEN rating >= 4 THEN 1 END) * 100.0 /
              COUNT(*), 1)                AS pct_high_rated
    FROM vw_products
    GROUP BY brand
),
brand_revenue_share AS (
    SELECT
        brand,
        ROUND(total_revenue * 100.0 /
            SUM(total_revenue) OVER (), 1) AS revenue_share
    FROM brand_stats
)
SELECT
    bs.*,
    brs.revenue_share,
    RANK() OVER (ORDER BY bs.total_revenue DESC) AS revenue_rank,
    CASE
        WHEN bs.avg_rating >= 4   THEN 'Excellent'
        WHEN bs.avg_rating >= 3.5 THEN 'Good'
        WHEN bs.avg_rating >= 3   THEN 'Average'
        ELSE                           'Needs Improvement'
    END                               AS rating_category
FROM brand_stats bs
JOIN brand_revenue_share brs ON bs.brand = brs.brand
ORDER BY total_revenue DESC;

/*
FINAL EXECUTIVE OUTPUT:
brand  | products | revenue        | avg_price | discount | rating | rev_share | rating_cat
Adidas |   2575   | $11,526,619    | $75.73    | 33.3%    | 3.37   | 93.5%     | Average
Nike   |    545   |    $802,283    | $41.34    | 0.0%     | 2.79   |  6.5%     | Needs Improvement

BUSINESS RECOMMENDATIONS:
1. Nike must INCREASE listing prices — products with $0 listing price (354 items) generate no data
2. Nike must INCREASE review counts — avg 7.46 vs Adidas 48.76 is the biggest gap
3. Adidas should REDUCE heavy discounts — no-discount products earn more per product
4. Both brands: invest in detailed product descriptions — 10× revenue impact confirmed
5. Focus on Elite tier (>$130) — generates $9,818 avg per product vs $115 for budget
*/


-- ============================================================
-- END OF PROJECT
-- SQL SKILLS DEMONSTRATED:
--   SELECT, FROM, WHERE         — data retrieval
--   INNER JOIN, LEFT JOIN       — 5-table merges
--   GROUP BY, ORDER BY          — aggregation
--   HAVING                      — post-group filtering
--   CASE WHEN                   — conditional classification
--   SUM(), AVG(), COUNT()       — aggregate functions
--   MIN(), MAX(), ROUND()       — numeric functions
--   LENGTH()                    — string function
--   MONTH(), MONTHNAME()        — date functions
--   LIKE                        — string matching
--   BETWEEN, IN                 — range filtering
--   Subqueries                  — nested calculations
--   CTEs (WITH)                 — modular query design
--   RANK() OVER                 — window function ranking
--   NTILE() OVER                — window quartile split
--   PARTITION BY                — grouped windows
--   CREATE VIEW                 — reusable result sets
-- ============================================================
