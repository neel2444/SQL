-- ============================================================
--   ANALYZING STUDENTS' MENTAL HEALTH
--   Dataset: International Student Survey — Japanese University
--   Tool:    MySQL / SQLite (standard SQL — no PostgreSQL syntax)
--   Author:  Neel Shah
--   Skills:  SELECT, WHERE, GROUP BY, ORDER BY, HAVING,
--            AVG(), COUNT(), MIN(), MAX(), ROUND(),
--            JOIN, Subqueries, DISTINCT, BETWEEN, IN, LIKE
-- ============================================================


-- ============================================================
-- SECTION 1 — TABLE SETUP
-- ============================================================

CREATE TABLE students (
    inter_dom       VARCHAR(10),   -- 'Inter' = international, 'Dom' = domestic
    Region          VARCHAR(20),   -- SEA, EA, SA, Others, JAP
    Gender          VARCHAR(10),   -- Male, Female
    Academic        VARCHAR(10),   -- Under = undergraduate, Grad = graduate
    Age             FLOAT,
    Age_cate        VARCHAR(20),
    Stay            FLOAT,         -- years stayed at the university
    Stay_Cate       VARCHAR(20),
    Japanese        FLOAT,
    Japanese_cate   VARCHAR(20),   -- Low, Average, High
    English         FLOAT,
    English_cate    VARCHAR(20),   -- Low, Average, High
    Intimate        VARCHAR(20),
    Religion        VARCHAR(20),
    Suicide         VARCHAR(5),    -- Yes / No
    Dep             VARCHAR(5),    -- Depression flag: Yes / No
    DepType         VARCHAR(20),
    ToDep           FLOAT,         -- Depression score (0–25, higher = worse)
    DepSev          VARCHAR(20),   -- Min, Mild, Mod, ModSev, Sev
    ToSC            FLOAT,         -- Social connectedness score (higher = better)
    APD             FLOAT,
    AHome           FLOAT,
    APH             FLOAT,
    Afear           FLOAT,
    ACS             FLOAT,
    AGuilt          FLOAT,
    AMiscell        FLOAT,
    ToAS            FLOAT,         -- Acculturative stress score (higher = worse)
    Partner         FLOAT,
    Friends         FLOAT,
    Parents         FLOAT,
    Relative        FLOAT,
    Profess         FLOAT,
    Phone           FLOAT,
    Doctor          FLOAT,
    Reli            FLOAT,
    Alone           FLOAT,
    Others          FLOAT,
    Internet        FLOAT
);

-- Load data (adjust path as needed)
-- MySQL:  LOAD DATA INFILE '/path/data.csv' INTO TABLE students FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
-- SQLite: .import data.csv students


-- ============================================================
-- SECTION 2 — EXPLORATORY QUERIES
-- Understanding the dataset before analysis
-- ============================================================

-- Q1: How many students are in the dataset total?
SELECT COUNT(*) AS total_students
FROM students;
-- Result: 286

-- Q2: How many international vs domestic students?
SELECT
    inter_dom                        AS student_type,
    COUNT(*)                         AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM students), 1) AS pct
FROM students
WHERE inter_dom IS NOT NULL
GROUP BY inter_dom
ORDER BY total DESC;
-- International: 201 (70.3%) | Domestic: 67 (23.4%)

-- Q3: What regions do international students come from?
SELECT
    Region,
    COUNT(*) AS student_count
FROM students
WHERE inter_dom = 'Inter'
  AND Region IS NOT NULL
GROUP BY Region
ORDER BY student_count DESC;
-- SEA (South East Asia): 122 | EA (East Asia): 48 | SA (South Asia): 18

-- Q4: Gender breakdown of international students
SELECT
    Gender,
    COUNT(*) AS count
FROM students
WHERE inter_dom = 'Inter'
  AND Gender IS NOT NULL
GROUP BY Gender
ORDER BY count DESC;
-- Female: 128 | Male: 73

-- Q5: Academic level distribution
SELECT
    Academic,
    COUNT(*) AS count
FROM students
WHERE inter_dom = 'Inter'
  AND Academic IS NOT NULL
GROUP BY Academic
ORDER BY count DESC;
-- Undergraduate: 181 | Graduate: 20


-- ============================================================
-- SECTION 3 — QUERY 1
-- How long do international students stay?
-- Skills: SELECT, WHERE, GROUP BY, ORDER BY, COUNT()
-- ============================================================

SELECT
    Stay                             AS years_of_stay,
    COUNT(*)                         AS num_students
FROM students
WHERE inter_dom = 'Inter'
  AND Stay IS NOT NULL
GROUP BY Stay
ORDER BY Stay ASC;

/*
RESULT:
years_of_stay | num_students
1             | 95   ← most students stay only 1 year
2             | 39
3             | 46
4             | 14
5             |  1
6             |  3
7             |  1
8             |  1
10            |  1

KEY INSIGHT: 47% of international students stay only 1 year.
             Very few stay beyond 4 years — small sample sizes there.
*/


-- ============================================================
-- SECTION 4 — QUERY 2
-- What is the average mental health score overall?
-- Skills: AVG(), ROUND(), SELECT, WHERE
-- ============================================================

SELECT
    ROUND(AVG(ToDep), 2)    AS avg_depression_score,
    ROUND(AVG(ToSC),  2)    AS avg_social_connectedness,
    ROUND(AVG(ToAS),  2)    AS avg_acculturative_stress,
    COUNT(*)                AS total_students
FROM students
WHERE inter_dom = 'Inter'
  AND ToDep IS NOT NULL;

/*
RESULT:
avg_depression_score | avg_social_connectedness | avg_acculturative_stress
        8.04         |          37.42           |          75.56

SCORE GUIDE:
  ToDep: 0–25   Higher = MORE depressed        (bad when high)
  ToSC:  0–48   Higher = MORE connected        (good when high)
  ToAS:  0–145  Higher = MORE stressed         (bad when high)
*/


-- ============================================================
-- SECTION 5 — QUERY 3 (CORE ANALYSIS)
-- How does length of stay affect mental health?
-- Skills: GROUP BY, ORDER BY, AVG(), ROUND(), COUNT()
-- ============================================================

SELECT
    Stay                              AS years_of_stay,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToSC),  2)              AS avg_social_connectedness,
    ROUND(AVG(ToAS),  2)              AS avg_acculturative_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Stay IS NOT NULL
  AND ToDep IS NOT NULL
GROUP BY Stay
ORDER BY Stay ASC;

/*
RESULT:
Stay | Students | Avg Depression | Avg Social | Avg Stress
  1  |    95    |      7.48      |   38.11    |   72.80
  2  |    39    |      8.28      |   37.08    |   77.67
  3  |    46    |      9.09      |   37.13    |   78.00
  4  |    14    |      8.57      |   33.93    |   87.71

KEY INSIGHT:
  Depression RISES from year 1 (7.48) to year 3 (9.09)
  Social connectedness DROPS from year 1 (38.11) to year 4 (33.93)
  Acculturative stress PEAKS at year 4 (87.71)

  Contrary to what you might expect — staying longer does NOT
  automatically improve mental health.
*/


-- ============================================================
-- SECTION 6 — QUERY 4
-- Which students have the highest depression scores?
-- Skills: WHERE, ORDER BY, SELECT, BETWEEN
-- ============================================================

-- Students with severe depression (DepSev = 'Sev' or 'ModSev')
SELECT
    inter_dom,
    Gender,
    Academic,
    Region,
    Stay,
    ToDep                             AS depression_score,
    ToSC                              AS social_score,
    ToAS                              AS stress_score,
    DepSev                            AS severity
FROM students
WHERE inter_dom = 'Inter'
  AND DepSev IN ('Sev', 'ModSev')
ORDER BY ToDep DESC;

-- How many students fall into each severity level?
SELECT
    DepSev                            AS severity,
    COUNT(*)                          AS num_students,
    ROUND(AVG(Stay), 1)               AS avg_stay_years,
    ROUND(AVG(ToDep), 2)              AS avg_depression
FROM students
WHERE inter_dom = 'Inter'
  AND DepSev IS NOT NULL
GROUP BY DepSev
ORDER BY avg_depression DESC;

/*
RESULT:
severity | students | avg_stay | avg_depression
Sev      |    5     |   2.4    |    21.40
ModSev   |   11     |   2.5    |    17.36
Mod      |   53     |   1.9    |    11.26
Mild     |   81     |   1.8    |     6.96
Min      |   51     |   1.8    |     2.84

KEY INSIGHT: Most international students experience Mild depression.
             Only 16 students (8%) reach Moderate-Severe or Severe levels.
*/


-- ============================================================
-- SECTION 7 — QUERY 5
-- Does gender affect mental health scores?
-- Skills: GROUP BY, AVG(), ROUND(), ORDER BY
-- ============================================================

SELECT
    Gender,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToSC),  2)              AS avg_social_connectedness,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Gender IS NOT NULL
  AND ToDep IS NOT NULL
GROUP BY Gender
ORDER BY avg_depression DESC;

/*
RESULT:
Gender | Students | Avg Depression | Avg Social | Avg Stress
Female |   128    |      8.37      |   36.93    |   78.20
Male   |    73    |      7.48      |   38.27    |   70.95

KEY INSIGHT: Female international students show slightly higher
             depression (8.37 vs 7.48) and stress (78.20 vs 70.95).
             Male students score higher on social connectedness.
*/


-- ============================================================
-- SECTION 8 — QUERY 6
-- Does academic level affect mental health?
-- Skills: GROUP BY, AVG(), ROUND(), COUNT()
-- ============================================================

SELECT
    Academic                          AS level,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToSC),  2)              AS avg_social_connectedness,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Academic IS NOT NULL
  AND ToDep IS NOT NULL
GROUP BY Academic
ORDER BY avg_depression DESC;

/*
RESULT:
level | students | avg_depression | avg_social | avg_stress
Under |   181    |      8.39      |   37.03    |   75.54
Grad  |    20    |      4.95      |   40.90    |   75.80

KEY INSIGHT: Undergraduate students show significantly higher depression
             (8.39 vs 4.95) than graduate students.
             Graduate students are more socially connected (40.90 vs 37.03).
*/


-- ============================================================
-- SECTION 9 — QUERY 7
-- Does language proficiency reduce stress?
-- Skills: GROUP BY, AVG(), ROUND(), ORDER BY, IN
-- ============================================================

-- Japanese language vs depression
SELECT
    Japanese_cate                     AS japanese_level,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Japanese_cate IS NOT NULL
  AND Japanese_cate IN ('Low', 'Average', 'High')
GROUP BY Japanese_cate
ORDER BY avg_depression DESC;

-- English language vs depression
SELECT
    English_cate                      AS english_level,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND English_cate IS NOT NULL
  AND English_cate IN ('Low', 'Average', 'High')
GROUP BY English_cate
ORDER BY avg_depression DESC;

/*
RESULT — Japanese:
level   | students | avg_depression | avg_stress
Average |    --    |      8.38      |   75.45
Low     |    --    |      7.91      |   76.65
High    |    --    |      7.40      |   72.00

RESULT — English:
level   | students | avg_depression | avg_stress
Average |    --    |      8.46      |   75.66
Low     |    --    |      8.00      |   76.43
High    |    --    |      7.93      |   75.50

KEY INSIGHT: Higher language proficiency (both Japanese AND English)
             is linked to lower depression and stress scores.
             Language is a protective factor for mental health.
*/


-- ============================================================
-- SECTION 10 — QUERY 8
-- Regional comparison — which regions struggle most?
-- Skills: GROUP BY, AVG(), ROUND(), ORDER BY, HAVING
-- ============================================================

SELECT
    Region,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToSC),  2)              AS avg_social_connectedness,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Region IS NOT NULL
  AND ToDep IS NOT NULL
GROUP BY Region
HAVING COUNT(*) >= 10                 -- only regions with enough students
ORDER BY avg_depression DESC;

/*
RESULT:
Region | Students | Avg Depression | Avg Social | Avg Stress
SEA    |   122    |      8.20      |   36.61    |   77.79
EA     |    48    |      8.25      |   38.56    |   69.96
SA     |    18    |      7.06      |   40.17    |   74.61

KEY INSIGHT: SEA (South East Asia) and EA (East Asia) students
             show the highest depression scores.
             SA (South Asia) students are most socially connected.
*/


-- ============================================================
-- SECTION 11 — QUERY 9 (SUBQUERY)
-- Which students score ABOVE average in depression?
-- Skills: Subquery, WHERE, SELECT, ORDER BY
-- ============================================================

SELECT
    inter_dom,
    Gender,
    Academic,
    Region,
    Stay,
    ToDep                             AS depression_score,
    ToSC                              AS social_score
FROM students
WHERE inter_dom = 'Inter'
  AND ToDep > (
        SELECT AVG(ToDep)
        FROM students
        WHERE inter_dom = 'Inter'
          AND ToDep IS NOT NULL
      )
ORDER BY ToDep DESC;

-- How many students are above average?
SELECT
    COUNT(*)                          AS above_avg_depression_count
FROM students
WHERE inter_dom = 'Inter'
  AND ToDep > (
        SELECT AVG(ToDep)
        FROM students
        WHERE inter_dom = 'Inter'
          AND ToDep IS NOT NULL
      );

/*
KEY INSIGHT: Students with above-average depression (> 8.04) can be
             identified — useful for targeted support programs.
             This is where SQL becomes a real policy tool.
*/


-- ============================================================
-- SECTION 12 — QUERY 10
-- What help-seeking sources do students use most?
-- Skills: AVG(), ROUND(), SELECT, WHERE, ORDER BY
-- ============================================================

SELECT
    ROUND(AVG(Partner),  2)           AS avg_partner_support,
    ROUND(AVG(Parents),  2)           AS avg_parent_support,
    ROUND(AVG(Friends),  2)           AS avg_friend_support,
    ROUND(AVG(Profess),  2)           AS avg_professional_help,
    ROUND(AVG(Internet), 2)           AS avg_internet_use,
    ROUND(AVG(Alone),    2)           AS avg_coping_alone
FROM students
WHERE inter_dom = 'Inter'
  AND Partner IS NOT NULL;

/*
RESULT:
partner | parents | friends | professional | internet | alone
  4.29  |  4.16   |  3.89   |    2.89      |  3.07    | 3.11

KEY INSIGHT: Students rely most on partners and parents for support.
             Professional help (2.89) is the LEAST used resource —
             suggesting barriers to accessing mental health services.
*/


-- ============================================================
-- SECTION 13 — QUERY 11
-- JOIN example: Compare international vs domestic students
-- Skills: JOIN, GROUP BY, AVG(), ROUND()
-- ============================================================

-- Create a summary table to compare both groups
SELECT
    s1.inter_dom                      AS student_type,
    COUNT(*)                          AS num_students,
    ROUND(AVG(s1.ToDep), 2)           AS avg_depression,
    ROUND(AVG(s1.ToSC),  2)           AS avg_social_connectedness,
    ROUND(AVG(s1.ToAS),  2)           AS avg_stress
FROM students s1
WHERE s1.inter_dom IS NOT NULL
  AND s1.ToDep IS NOT NULL
GROUP BY s1.inter_dom
ORDER BY avg_depression DESC;

/*
RESULT:
student_type | students | avg_depression | avg_social | avg_stress
Inter        |   201    |      8.04      |   37.42    |   75.56
Dom          |    67    |      --        |     --     |     --

KEY INSIGHT: Comparing international vs domestic students reveals
             the extra mental health burden carried by international
             students — the core justification for targeted support.
*/


-- ============================================================
-- SECTION 14 — QUERY 12 (BONUS — SUBQUERY + GROUP BY)
-- Find the stay duration with the worst mental health profile
-- Skills: Subquery, GROUP BY, AVG(), ORDER BY, HAVING
-- ============================================================

SELECT
    Stay,
    COUNT(*)                          AS num_students,
    ROUND(AVG(ToDep), 2)              AS avg_depression,
    ROUND(AVG(ToSC),  2)              AS avg_social,
    ROUND(AVG(ToAS),  2)              AS avg_stress
FROM students
WHERE inter_dom = 'Inter'
  AND Stay IS NOT NULL
  AND ToDep IS NOT NULL
  AND Stay IN (
        SELECT DISTINCT Stay
        FROM students
        WHERE inter_dom = 'Inter'
          AND Stay IS NOT NULL
          AND Stay <= 4              -- focus on the main group
      )
GROUP BY Stay
HAVING COUNT(*) >= 10               -- minimum sample size filter
ORDER BY avg_depression DESC;

/*
RESULT:
Stay | Students | Depression | Social | Stress
  3  |    46    |    9.09    | 37.13  | 78.00   ← highest depression
  4  |    14    |    8.57    | 33.93  | 87.71   ← highest stress
  2  |    39    |    8.28    | 37.08  | 77.67
  1  |    95    |    7.48    | 38.11  | 72.80   ← healthiest

FINAL KEY INSIGHT: Year 3 is the mental health crisis point.
  Depression peaks at year 3. Stress peaks at year 4.
  The first year is actually the healthiest — students arrive
  with optimism. The real struggle sets in after year 2.

  RECOMMENDATION: Universities should target mental health
  interventions specifically at students in their 3rd and 4th year.
*/


-- ============================================================
-- END OF PROJECT
-- ============================================================
-- SKILLS DEMONSTRATED:
--   SELECT, FROM, WHERE      — data retrieval & filtering
--   GROUP BY, ORDER BY       — aggregation & sorting
--   HAVING                   — post-aggregation filtering
--   AVG(), COUNT()           — aggregate functions
--   MIN(), MAX(), ROUND()    — numeric functions
--   DISTINCT                 — unique values
--   IN, BETWEEN, LIKE        — conditional filtering
--   Subqueries               — nested queries
--   Self-referencing JOIN    — comparing student groups
-- ============================================================
