-- ============================================================
--  UNICORN COMPANIES SQL ANALYSIS
--  Source: Crunchbase Emerging Unicorns Dataset
--  392 Companies | 33 Countries | 6 Regions | $265B Total
--  Database: PostgreSQL (compatible with MySQL / SQLite)
-- ============================================================


-- ============================================================
-- SECTION 1 — TABLE SETUP & DATA INGESTION
-- ============================================================

DROP TABLE IF EXISTS unicorn_companies;

CREATE TABLE unicorn_companies (
    id                SERIAL PRIMARY KEY,
    company_name      VARCHAR(200)    NOT NULL,
    country           VARCHAR(100)    NOT NULL,
    region            VARCHAR(100)    NOT NULL,
    lead_investors    TEXT,
    company_link      VARCHAR(500),
    post_money_value  VARCHAR(20),
    total_eq_funding  VARCHAR(20),
    -- Cleaned numeric columns (populated after load)
    valuation_m       DECIMAL(12, 2),
    funding_m         DECIMAL(12, 2),
    efficiency_ratio  DECIMAL(10, 4)
);

-- Load raw CSV (PostgreSQL)
COPY unicorn_companies (id, country, region, lead_investors, company_link,
                        img_src_placeholder, company_name,
                        post_money_value, total_eq_funding)
FROM '/path/to/emergingunicorn_companies.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ── Clean: strip '$', convert B/M/K to numeric millions ──
UPDATE unicorn_companies
SET valuation_m = CASE
    WHEN post_money_value LIKE '%B' THEN
        CAST(REPLACE(REPLACE(post_money_value,'$',''),'B','') AS DECIMAL) * 1000
    WHEN post_money_value LIKE '%M' THEN
        CAST(REPLACE(REPLACE(post_money_value,'$',''),'M','') AS DECIMAL)
    ELSE 0
END;

UPDATE unicorn_companies
SET funding_m = CASE
    WHEN total_eq_funding LIKE '%B' THEN
        CAST(REPLACE(REPLACE(total_eq_funding,'$',''),'B','') AS DECIMAL) * 1000
    WHEN total_eq_funding LIKE '%M' THEN
        CAST(REPLACE(REPLACE(total_eq_funding,'$',''),'M','') AS DECIMAL)
    WHEN total_eq_funding LIKE '%K' THEN
        CAST(REPLACE(REPLACE(total_eq_funding,'$',''),'K','') AS DECIMAL) / 1000
    ELSE 0
END;

UPDATE unicorn_companies
SET efficiency_ratio = CASE
    WHEN funding_m > 0 THEN ROUND(valuation_m / funding_m, 4)
    ELSE NULL
END;


-- ============================================================
-- SECTION 2 — EDA: BASIC EXPLORATION
-- ============================================================

-- 2.1  Dataset overview
SELECT
    COUNT(*)                          AS total_companies,
    COUNT(DISTINCT country)           AS countries,
    COUNT(DISTINCT region)            AS regions,
    ROUND(SUM(valuation_m) / 1000, 2) AS total_valuation_billions,
    ROUND(AVG(valuation_m), 1)        AS mean_valuation_m,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY valuation_m)
                                      AS median_valuation_m,
    ROUND(STDDEV(valuation_m), 1)     AS stddev_valuation_m,
    MAX(valuation_m)                  AS max_valuation_m,
    MIN(valuation_m)                  AS min_valuation_m
FROM unicorn_companies;

-- 2.2  Check for nulls
SELECT
    SUM(CASE WHEN company_name  IS NULL THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN country       IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN lead_investors IS NULL THEN 1 ELSE 0 END) AS null_investors,
    SUM(CASE WHEN valuation_m   IS NULL OR valuation_m = 0 THEN 1 ELSE 0 END) AS zero_valuation,
    SUM(CASE WHEN funding_m     IS NULL OR funding_m   = 0 THEN 1 ELSE 0 END) AS zero_funding
FROM unicorn_companies;


-- ============================================================
-- SECTION 3 — GEOGRAPHIC ANALYSIS
-- ============================================================

-- 3.1  Top 15 countries by unicorn count + avg valuation
SELECT
    country,
    region,
    COUNT(*)                                      AS unicorn_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(AVG(valuation_m), 1)                    AS avg_valuation_m,
    ROUND(SUM(valuation_m) / 1000, 2)             AS total_val_billions,
    RANK() OVER (ORDER BY COUNT(*) DESC)          AS country_rank
FROM unicorn_companies
GROUP BY country, region
ORDER BY unicorn_count DESC
LIMIT 15;

-- 3.2  Region summary with share of total
SELECT
    region,
    COUNT(*)                                          AS unicorn_count,
    ROUND(SUM(valuation_m) / 1000, 2)                AS total_val_billions,
    ROUND(AVG(valuation_m), 1)                        AS avg_valuation_m,
    ROUND(AVG(funding_m), 1)                          AS avg_funding_m,
    ROUND(SUM(valuation_m) * 100.0
          / SUM(SUM(valuation_m)) OVER (), 2)         AS pct_of_global_value,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (), 2)                 AS pct_of_count
FROM unicorn_companies
GROUP BY region
ORDER BY total_val_billions DESC;

-- 3.3  Within-region top performer (uses window function)
SELECT
    company_name,
    country,
    region,
    valuation_m,
    RANK() OVER (PARTITION BY region ORDER BY valuation_m DESC) AS rank_in_region
FROM unicorn_companies
QUALIFY rank_in_region = 1   -- top company per region
ORDER BY valuation_m DESC;

-- ── PostgreSQL alternative (no QUALIFY):
-- SELECT * FROM (
--     SELECT company_name, country, region, valuation_m,
--            RANK() OVER (PARTITION BY region ORDER BY valuation_m DESC) AS rnk
--     FROM unicorn_companies
-- ) t WHERE rnk = 1;


-- ============================================================
-- SECTION 4 — CAPITAL EFFICIENCY ANALYSIS
-- ============================================================

-- 4.1  Efficiency tiers with CASE
SELECT
    company_name,
    country,
    region,
    ROUND(valuation_m, 1)                                      AS valuation_m,
    ROUND(funding_m, 1)                                        AS funding_m,
    ROUND(efficiency_ratio, 2)                                 AS val_fund_ratio,
    CASE
        WHEN efficiency_ratio >= 10 THEN '🏆 Elite    (10x+)'
        WHEN efficiency_ratio >=  5 THEN '⭐ High     (5–10x)'
        WHEN efficiency_ratio >=  2 THEN '✅ Good     (2–5x)'
        WHEN efficiency_ratio >=  1 THEN '➖ Break-Even (1–2x)'
        WHEN efficiency_ratio >   0 THEN '⚠️ Below Par (<1x)'
        ELSE                             '❓ No Funding Data'
    END                                                        AS efficiency_tier
FROM unicorn_companies
WHERE funding_m > 0
ORDER BY efficiency_ratio DESC
LIMIT 25;

-- 4.2  Efficiency tier summary
SELECT
    CASE
        WHEN efficiency_ratio >= 10 THEN 'Elite (10x+)'
        WHEN efficiency_ratio >=  5 THEN 'High (5–10x)'
        WHEN efficiency_ratio >=  2 THEN 'Good (2–5x)'
        WHEN efficiency_ratio >=  1 THEN 'Break-Even'
        ELSE 'Below Par / No Data'
    END                             AS efficiency_tier,
    COUNT(*)                        AS company_count,
    ROUND(AVG(valuation_m), 1)      AS avg_valuation_m,
    ROUND(AVG(funding_m), 1)        AS avg_funding_m
FROM unicorn_companies
GROUP BY efficiency_tier
ORDER BY avg_valuation_m DESC;


-- ============================================================
-- SECTION 5 — JOIN QUERIES
-- ============================================================

-- 5.1  JOIN: Each company vs its regional average
SELECT
    u.company_name,
    u.country,
    u.region,
    u.valuation_m,
    r.region_avg_val,
    r.region_total_val,
    ROUND(u.valuation_m - r.region_avg_val, 1)             AS vs_region_avg_m,
    ROUND((u.valuation_m / r.region_avg_val - 1) * 100, 1) AS pct_above_region_avg
FROM unicorn_companies u
JOIN (
    SELECT
        region,
        ROUND(AVG(valuation_m), 1)        AS region_avg_val,
        ROUND(SUM(valuation_m) / 1000, 2) AS region_total_val,
        COUNT(*)                           AS region_count
    FROM unicorn_companies
    GROUP BY region
) r ON u.region = r.region
ORDER BY pct_above_region_avg DESC
LIMIT 20;

-- 5.2  JOIN: Company vs country average
SELECT
    u.company_name,
    u.country,
    u.valuation_m,
    c.country_avg_val,
    c.country_count,
    ROUND(u.valuation_m - c.country_avg_val, 1) AS vs_country_avg_m,
    CASE
        WHEN u.valuation_m > c.country_avg_val THEN 'Above Country Average'
        ELSE 'Below Country Average'
    END AS val_flag
FROM unicorn_companies u
JOIN (
    SELECT
        country,
        ROUND(AVG(valuation_m), 1) AS country_avg_val,
        COUNT(*)                    AS country_count
    FROM unicorn_companies
    GROUP BY country
    HAVING COUNT(*) >= 3              -- only countries with 3+ unicorns
) c ON u.country = c.country
ORDER BY u.country, u.valuation_m DESC;


-- ============================================================
-- SECTION 6 — WINDOW FUNCTIONS
-- ============================================================

-- 6.1  Full window function showcase per company
SELECT
    company_name,
    country,
    region,
    valuation_m,
    RANK()        OVER (PARTITION BY region  ORDER BY valuation_m DESC) AS rank_in_region,
    DENSE_RANK()  OVER (PARTITION BY country ORDER BY valuation_m DESC) AS dense_rank_country,
    NTILE(4)      OVER (PARTITION BY region  ORDER BY valuation_m DESC) AS quartile_region,
    NTILE(10)     OVER (ORDER BY valuation_m DESC)                       AS global_decile,
    ROUND(AVG(valuation_m) OVER (PARTITION BY region),  1)              AS region_avg,
    ROUND(AVG(valuation_m) OVER (PARTITION BY country), 1)              AS country_avg,
    ROUND(SUM(valuation_m) OVER (PARTITION BY region ORDER BY valuation_m DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 1)
                                                                         AS running_total_region
FROM unicorn_companies
ORDER BY region, rank_in_region
LIMIT 30;

-- 6.2  LAG/LEAD: Compare sequential companies by valuation
SELECT
    company_name,
    country,
    valuation_m,
    LAG(valuation_m)  OVER (ORDER BY valuation_m DESC)  AS prev_company_val,
    LEAD(valuation_m) OVER (ORDER BY valuation_m DESC)  AS next_company_val,
    ROUND(valuation_m - LAG(valuation_m)  OVER (ORDER BY valuation_m DESC), 1) AS diff_from_prev,
    ROUND(valuation_m - LEAD(valuation_m) OVER (ORDER BY valuation_m DESC), 1) AS diff_to_next
FROM unicorn_companies
ORDER BY valuation_m DESC
LIMIT 20;


-- ============================================================
-- SECTION 7 — CTE (COMMON TABLE EXPRESSIONS)
-- ============================================================

-- 7.1  CTE: Flag above/below average per country
WITH country_stats AS (
    SELECT
        country,
        ROUND(AVG(valuation_m), 1)  AS country_avg_val,
        ROUND(STDDEV(valuation_m), 1) AS country_stddev,
        COUNT(*)                     AS country_count
    FROM unicorn_companies
    GROUP BY country
),
flagged_companies AS (
    SELECT
        u.company_name,
        u.country,
        u.region,
        u.valuation_m,
        cs.country_avg_val,
        CASE
            WHEN u.valuation_m > cs.country_avg_val + cs.country_stddev THEN 'Top Performer'
            WHEN u.valuation_m > cs.country_avg_val                      THEN 'Above Average'
            WHEN u.valuation_m > cs.country_avg_val - cs.country_stddev  THEN 'Below Average'
            ELSE                                                               'Low Performer'
        END AS performance_band
    FROM unicorn_companies u
    JOIN country_stats cs ON u.country = cs.country
)
SELECT
    country,
    performance_band,
    COUNT(*)                     AS company_count,
    ROUND(AVG(valuation_m), 1)  AS avg_val_in_band
FROM flagged_companies
GROUP BY country, performance_band
ORDER BY country, performance_band;

-- 7.2  Recursive-style CTE: Cumulative valuation by region
WITH regional_totals AS (
    SELECT
        region,
        ROUND(SUM(valuation_m) / 1000, 2)  AS total_val_b,
        COUNT(*)                             AS co_count
    FROM unicorn_companies
    GROUP BY region
),
ranked AS (
    SELECT
        region,
        total_val_b,
        co_count,
        ROUND(total_val_b * 100.0 / SUM(total_val_b) OVER (), 2) AS pct_share,
        SUM(total_val_b) OVER (ORDER BY total_val_b DESC
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_val_b
    FROM regional_totals
)
SELECT * FROM ranked ORDER BY total_val_b DESC;


-- ============================================================
-- SECTION 8 — GROUPING SETS (Multi-level aggregation)
-- ============================================================

SELECT
    COALESCE(region,  '── ALL REGIONS ──')   AS region,
    COALESCE(country, '── ALL IN REGION ──') AS country,
    COUNT(*)                                  AS unicorn_count,
    ROUND(SUM(valuation_m) / 1000, 2)         AS total_val_billions,
    ROUND(AVG(valuation_m), 1)                AS avg_val_m,
    ROUND(AVG(efficiency_ratio), 2)           AS avg_efficiency
FROM unicorn_companies
GROUP BY GROUPING SETS (
    (region, country),   -- company country within region
    (region),            -- region subtotals
    ()                   -- grand total
)
ORDER BY
    GROUPING(region),
    GROUPING(country),
    total_val_billions DESC NULLS LAST;


-- ============================================================
-- SECTION 9 — INVESTOR ANALYSIS
-- ============================================================

-- 9.1  Most frequent lead investors (split needed in app layer)
SELECT
    lead_investors,
    COUNT(*)                    AS portfolio_cos,
    ROUND(SUM(valuation_m), 1)  AS portfolio_val_m,
    ROUND(AVG(valuation_m), 1)  AS avg_val_m
FROM unicorn_companies
WHERE lead_investors IS NOT NULL
GROUP BY lead_investors
ORDER BY portfolio_cos DESC
LIMIT 20;

-- 9.2  Companies with no disclosed investors
SELECT
    company_name,
    country,
    valuation_m,
    funding_m
FROM unicorn_companies
WHERE lead_investors IS NULL
ORDER BY valuation_m DESC;


-- ============================================================
-- SECTION 10 — FINAL SUMMARY REPORT QUERY
-- (Single query to answer: "Give me the full picture")
-- ============================================================

WITH region_stats AS (
    SELECT
        region,
        COUNT(*)                         AS cos_in_region,
        ROUND(AVG(valuation_m), 1)       AS region_avg_val,
        ROUND(SUM(valuation_m)/1000, 2)  AS region_total_val_b,
        ROUND(AVG(efficiency_ratio), 2)  AS region_avg_eff
    FROM unicorn_companies
    GROUP BY region
),
global_stats AS (
    SELECT
        ROUND(AVG(valuation_m), 1)       AS global_avg_val,
        ROUND(SUM(valuation_m)/1000, 2)  AS global_total_val_b,
        COUNT(*)                         AS global_count
    FROM unicorn_companies
),
company_enriched AS (
    SELECT
        u.company_name,
        u.country,
        u.region,
        u.valuation_m,
        u.funding_m,
        u.efficiency_ratio,
        rs.region_avg_val,
        gs.global_avg_val,
        RANK() OVER (ORDER BY u.valuation_m DESC)                    AS global_rank,
        RANK() OVER (PARTITION BY u.region ORDER BY u.valuation_m DESC) AS region_rank,
        ROUND((u.valuation_m / NULLIF(rs.region_avg_val, 0) - 1)*100, 1) AS pct_above_region,
        ROUND((u.valuation_m / NULLIF(gs.global_avg_val,  0) - 1)*100, 1) AS pct_above_global,
        CASE
            WHEN u.efficiency_ratio >= 10 THEN 'Elite'
            WHEN u.efficiency_ratio >=  5 THEN 'High'
            WHEN u.efficiency_ratio >=  2 THEN 'Good'
            WHEN u.efficiency_ratio >   0 THEN 'Standard'
            ELSE 'Bootstrapped'
        END AS efficiency_tier
    FROM unicorn_companies u
    CROSS JOIN global_stats gs
    JOIN region_stats rs ON u.region = rs.region
)
SELECT
    global_rank,
    region_rank,
    company_name,
    country,
    region,
    valuation_m,
    funding_m,
    efficiency_ratio,
    efficiency_tier,
    pct_above_region   AS vs_region_avg_pct,
    pct_above_global   AS vs_global_avg_pct
FROM company_enriched
ORDER BY global_rank
LIMIT 50;

-- ============================================================
-- END OF SCRIPT
-- Total queries: 18 | Concepts: JOIN, CTE, Window Functions,
-- GROUPING SETS, CASE, RANK, NTILE, LAG/LEAD, Aggregations
-- ============================================================
