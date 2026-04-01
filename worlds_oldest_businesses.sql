-- ============================================================
--   WORLD'S OLDEST BUSINESSES — SQL EDA PROJECT
--   Skills: SELECT, FROM, WHERE, ORDER BY, GROUP BY, HAVING,
--           JOIN, Subqueries, IN, BETWEEN, DISTINCT,
--           COUNT(), AVG(), ROUND(), LIKE
--   Tables : businesses | categories | countries
-- ============================================================


-- ============================================================
-- SECTION 0 — TABLE SETUP (SQLite / MySQL compatible)
-- ============================================================

-- businesses table
CREATE TABLE IF NOT EXISTS businesses (
    business      TEXT,
    year_founded  INTEGER,
    category_code TEXT,
    country_code  TEXT
);

-- categories table
CREATE TABLE IF NOT EXISTS categories (
    category_code TEXT PRIMARY KEY,
    category      TEXT
);

-- countries table
CREATE TABLE IF NOT EXISTS countries (
    country_code TEXT PRIMARY KEY,
    country      TEXT,
    continent    TEXT
);


-- ============================================================
-- SECTION 1 — BASIC EXPLORATION
-- ============================================================

-- 1.1  Preview all tables
SELECT * FROM businesses  LIMIT 10;
SELECT * FROM categories;
SELECT * FROM countries   LIMIT 10;

-- 1.2  Total number of businesses in the dataset
SELECT COUNT(*) AS total_businesses
FROM businesses;

-- 1.3  Distinct continents represented
SELECT DISTINCT continent
FROM countries
ORDER BY continent;

-- 1.4  Distinct industries / categories
SELECT DISTINCT category
FROM categories
ORDER BY category;

-- 1.5  Year range of founding dates
SELECT
    MIN(year_founded) AS earliest_year,
    MAX(year_founded) AS latest_year,
    MAX(year_founded) - MIN(year_founded) AS year_span
FROM businesses;


-- ============================================================
-- SECTION 2 — TOP 10 OLDEST BUSINESSES  (JOIN + ORDER BY + LIMIT)
-- ============================================================

-- 2.1  Top 10 oldest businesses with country and category
SELECT
    b.business,
    b.year_founded,
    c.country,
    c.continent,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
ORDER BY b.year_founded ASC
LIMIT 10;

-- 2.2  The single oldest business in the world
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category,
    (2024 - b.year_founded) AS years_survived
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
ORDER BY b.year_founded ASC
LIMIT 1;

-- 2.3  How old is each business today?
SELECT
    b.business,
    b.year_founded,
    c.country,
    (2024 - b.year_founded) AS age_years
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
ORDER BY age_years DESC
LIMIT 10;


-- ============================================================
-- SECTION 3 — CATEGORY / INDUSTRY ANALYSIS  (GROUP BY + COUNT)
-- ============================================================

-- 3.1  Number of businesses per industry category
SELECT
    cat.category,
    COUNT(*) AS num_businesses
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
ORDER BY num_businesses DESC;

-- 3.2  Industries with more than 5 oldest businesses (HAVING)
SELECT
    cat.category,
    COUNT(*) AS num_businesses
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
HAVING COUNT(*) > 5
ORDER BY num_businesses DESC;

-- 3.3  Average founding year per industry
SELECT
    cat.category,
    COUNT(*)                          AS num_businesses,
    ROUND(AVG(b.year_founded), 0)     AS avg_year_founded,
    MIN(b.year_founded)               AS oldest_in_category
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
ORDER BY avg_year_founded ASC;

-- 3.4  What percentage of all businesses does each category represent?
SELECT
    cat.category,
    COUNT(*)                                           AS num_businesses,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(*) FROM businesses), 1)        AS pct_of_total
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
ORDER BY num_businesses DESC;


-- ============================================================
-- SECTION 4 — CONTINENTAL ANALYSIS  (GROUP BY + AVG + ROUND)
-- ============================================================

-- 4.1  Number of oldest businesses per continent
SELECT
    c.continent,
    COUNT(*)                        AS num_businesses
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
GROUP BY c.continent
ORDER BY num_businesses DESC;

-- 4.2  Continent stats — count, average founding year, oldest business year
SELECT
    c.continent,
    COUNT(*)                          AS num_businesses,
    ROUND(AVG(b.year_founded), 0)     AS avg_year_founded,
    MIN(b.year_founded)               AS oldest_year
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
GROUP BY c.continent
ORDER BY avg_year_founded ASC;

-- 4.3  Continents with more than 10 oldest businesses (HAVING)
SELECT
    c.continent,
    COUNT(*) AS num_businesses
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
GROUP BY c.continent
HAVING COUNT(*) > 10
ORDER BY num_businesses DESC;

-- 4.4  Oldest business on each continent
SELECT
    c.continent,
    b.business,
    b.year_founded,
    c.country
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
WHERE b.year_founded = (
    SELECT MIN(b2.year_founded)
    FROM businesses b2
    JOIN countries c2 ON b2.country_code = c2.country_code
    WHERE c2.continent = c.continent
)
ORDER BY b.year_founded ASC;


-- ============================================================
-- SECTION 5 — FILTERING WITH WHERE, BETWEEN, IN, LIKE
-- ============================================================

-- 5.1  Businesses founded before the year 1000 AD
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE b.year_founded < 1000
ORDER BY b.year_founded ASC;

-- 5.2  Businesses founded in the Medieval period (1000–1499) — BETWEEN
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE b.year_founded BETWEEN 1000 AND 1499
ORDER BY b.year_founded ASC;

-- 5.3  Businesses in specific industries — IN operator
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE cat.category IN (
    'Banking & Finance',
    'Distillers, Vintners, & Breweries',
    'Manufacturing & Production'
)
ORDER BY b.year_founded ASC;

-- 5.4  Businesses in European countries only (WHERE + continent filter)
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE c.continent = 'Europe'
ORDER BY b.year_founded ASC;

-- 5.5  Find all beverage / drink related businesses — LIKE
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE cat.category LIKE '%Brew%'
   OR cat.category LIKE '%Vintner%'
   OR cat.category LIKE '%Distill%'
ORDER BY b.year_founded ASC;


-- ============================================================
-- SECTION 6 — SUBQUERIES
-- ============================================================

-- 6.1  Businesses founded before the average founding year
SELECT
    b.business,
    b.year_founded,
    c.country
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
WHERE b.year_founded < (
    SELECT AVG(year_founded) FROM businesses
)
ORDER BY b.year_founded ASC
LIMIT 20;

-- 6.2  Which categories have at least one business older than 1000 AD?
SELECT DISTINCT cat.category
FROM categories cat
WHERE cat.category_code IN (
    SELECT b.category_code
    FROM businesses b
    WHERE b.year_founded < 1000
)
ORDER BY cat.category;

-- 6.3  Medieval manufacturing businesses (BETWEEN + IN + Subquery)
SELECT
    b.business,
    b.year_founded,
    c.country,
    cat.category
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
WHERE b.year_founded BETWEEN 1000 AND 1500
  AND b.category_code IN (
      SELECT category_code
      FROM categories
      WHERE category LIKE '%Manufactur%'
  )
ORDER BY b.year_founded;

-- 6.4  Countries that have more than the average number of oldest businesses
SELECT
    c.country,
    c.continent,
    COUNT(*) AS num_businesses
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
GROUP BY c.country, c.continent
HAVING COUNT(*) > (
    SELECT AVG(country_count)
    FROM (
        SELECT country_code, COUNT(*) AS country_count
        FROM businesses
        GROUP BY country_code
    ) sub
)
ORDER BY num_businesses DESC;


-- ============================================================
-- SECTION 7 — ADVANCED AGGREGATIONS  (COUNT, AVG, ROUND, DISTINCT)
-- ============================================================

-- 7.1  Summary statistics for the entire dataset
SELECT
    COUNT(*)                        AS total_businesses,
    COUNT(DISTINCT country_code)    AS unique_countries,
    COUNT(DISTINCT category_code)   AS unique_categories,
    MIN(year_founded)               AS oldest_year,
    MAX(year_founded)               AS newest_year,
    ROUND(AVG(year_founded), 0)     AS avg_founding_year
FROM businesses;

-- 7.2  Businesses per founding century
SELECT
    CASE
        WHEN year_founded < 1000 THEN 'Before 1000 CE'
        WHEN year_founded BETWEEN 1000 AND 1499 THEN '1000–1499'
        WHEN year_founded BETWEEN 1500 AND 1699 THEN '1500–1699'
        WHEN year_founded BETWEEN 1700 AND 1799 THEN '1700–1799'
        WHEN year_founded BETWEEN 1800 AND 1899 THEN '1800–1899'
        ELSE '1900 and later'
    END AS founding_era,
    COUNT(*) AS num_businesses
FROM businesses
GROUP BY founding_era
ORDER BY MIN(year_founded);

-- 7.3  Average age of businesses by category (most ancient industries first)
SELECT
    cat.category,
    COUNT(*)                              AS num_businesses,
    ROUND(AVG(2024 - b.year_founded), 0)  AS avg_age_years,
    MIN(b.year_founded)                   AS oldest_founded
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
ORDER BY avg_age_years DESC;

-- 7.4  How many countries have oldest businesses per continent?
SELECT
    c.continent,
    COUNT(DISTINCT b.country_code)   AS countries_with_old_biz,
    COUNT(*)                         AS total_businesses
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
GROUP BY c.continent
ORDER BY total_businesses DESC;


-- ============================================================
-- SECTION 8 — DATA STORYTELLING QUERIES
-- ============================================================

-- 8.1  The Survival Formula — top 5 industries by average age
SELECT
    cat.category                          AS industry,
    COUNT(*)                              AS businesses,
    ROUND(AVG(2024 - b.year_founded), 0)  AS avg_survival_years,
    MIN(b.year_founded)                   AS oldest_in_industry
FROM businesses b
JOIN categories cat ON b.category_code = cat.category_code
GROUP BY cat.category
ORDER BY avg_survival_years DESC
LIMIT 5;

-- 8.2  Africa vs Europe — founding year comparison
SELECT
    c.continent,
    COUNT(*)                          AS num_businesses,
    ROUND(AVG(b.year_founded), 0)     AS avg_year_founded,
    MIN(b.year_founded)               AS oldest_business_year,
    MAX(b.year_founded)               AS newest_business_year
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
WHERE c.continent IN ('Africa', 'Europe')
GROUP BY c.continent;

-- 8.3  Industrial Revolution effect — businesses founded 1800–1900
SELECT
    c.continent,
    COUNT(*) AS businesses_founded_1800_1900
FROM businesses b
JOIN countries c ON b.country_code = c.country_code
WHERE b.year_founded BETWEEN 1800 AND 1900
GROUP BY c.continent
ORDER BY businesses_founded_1800_1900 DESC;

-- 8.4  Full enriched view of all businesses (for reporting / dashboard)
SELECT
    b.business,
    b.year_founded,
    (2024 - b.year_founded)           AS age_years,
    cat.category,
    c.country,
    c.continent,
    CASE
        WHEN b.year_founded < 1000 THEN 'Ancient'
        WHEN b.year_founded BETWEEN 1000 AND 1499 THEN 'Medieval'
        WHEN b.year_founded BETWEEN 1500 AND 1699 THEN 'Renaissance'
        WHEN b.year_founded BETWEEN 1700 AND 1799 THEN 'Enlightenment'
        WHEN b.year_founded BETWEEN 1800 AND 1899 THEN 'Industrial'
        ELSE 'Modern'
    END AS era
FROM businesses b
JOIN countries   c   ON b.country_code  = c.country_code
JOIN categories  cat ON b.category_code = cat.category_code
ORDER BY b.year_founded ASC;

-- ============================================================
--   END OF FILE
-- ============================================================
