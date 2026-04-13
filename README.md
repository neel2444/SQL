# 🌍 Industrial Carbon Emissions — SQL Analysis

## Project Overview
A full SQL analysis project on global industrial CO₂ emissions using
PostgreSQL. Written across 8 progressive queries covering 135,408 rows
of Kaggle data — from basic aggregations to advanced window functions.
The project tells a complete data story: which sectors, which countries,
and which events shaped global emissions from 2019 to 2023.

**Tool:** PostgreSQL  
**Dataset:** Kaggle — Global CO₂ Emissions · 135,408 rows · 14 countries
· 6 sectors · 2019–2023  
**Author:** Neel Shah | [LinkedIn](https://linkedin.com/in/neel-shah-654a1b27b)

---

## 📊 Dataset
| Column | Description |
|--------|-------------|
| country | 14 major emitting nations |
| sector | Power, Industry, Transport, Buildings, Agriculture, Aviation |
| year | 2019 – 2023 |
| value | CO₂ emissions in megatonnes (Mt) |

---

## 🔍 Key Findings

| Finding | Insight |
|---------|---------|
| ⚡ Power = biggest lever | Power sector = 37.6% of ALL global emissions |
| 🇨🇳 China's scale | China emits more than US + EU + India **combined** |
| 📉 COVID drop | 2020 saw the biggest single-year drop ever: **−5.4%** |
| 🇮🇳 India rising | India grew +7.7% since 2019 — overtook US in power emissions |
| ✈️ Aviation collapsed | Aviation −56.6% in 2020 vs Industry only −1.3% |
| 📈 Record high | 2022 hit a **new all-time high** — rebound was faster than the fall |

---

## 🗃️ SQL Skills Demonstrated

```sql
-- Example: RANK() window function — country ranking by sector
SELECT
    country,
    sector,
    SUM(value) AS total_emissions,
    RANK() OVER (
        PARTITION BY sector
        ORDER BY SUM(value) DESC
    ) AS sector_rank
FROM carbon_emissions
WHERE year = 2023
GROUP BY country, sector;
```

**Full skill list:**
SELECT · WHERE · GROUP BY · HAVING · ORDER BY · AVG() · SUM() ·
COUNT() · ROUND() · CASE WHEN · Subqueries · CTEs (WITH) ·
RANK() OVER · PARTITION BY · SUM() OVER · CREATE VIEW

---

## 📈 Query Progression

| Query | Question Asked | Skills Used |
|-------|---------------|-------------|
| 1 | Total emissions by country | SELECT, GROUP BY, ORDER BY |
| 2 | Which sector emits most? | GROUP BY, SUM(), % subquery |
| 3 | Year-on-year trend (COVID story) | GROUP BY year, CASE WHEN |
| 4 | Country × Sector matrix | GROUP BY two columns |
| 5 | Which countries are growing fastest? | Subquery year comparison |
| 6 | Rank countries within each sector | RANK() OVER, PARTITION BY |
| 7 | Cumulative emissions over time | SUM() OVER (running total) |
| 8 | India vs US head-to-head | CTE, JOIN, filtered comparison |

---

## 📊 Presentation
9-slide Deloitte-style PPTX with:
- Dataset overview and score guide
- Power sector dominance finding
- China scale analysis
- COVID year-on-year story
- India overtaking the US
- Aviation vs Industry comparison
- Conclusion and policy recommendations

---

## 💼 Business / Policy Recommendations
1. **Power sector is the #1 policy lever** — 37.6% of emissions, highest impact
2. **No net-zero without China** — emits more than 3 major blocs combined
3. **COVID proved rapid change is possible** — 5.4% drop in one year
4. **India needs targeted support** — fastest-growing major emitter at +7.7%
5. **Industrial decarbonisation needs direct policy** — barely responded to COVID

---

## 📁 Files in This Repository

├── carbon_emissions_SQL_project.sql      # 8 queries with full comments
├── carbon_sql_presentation.pptx          # 9-slide presentation
└── README.md



---

## 🚀 How to Run
1. Create a PostgreSQL database and the `carbon_emissions` table
   using the schema in Section 1 of the `.sql` file
2. Load the Kaggle dataset (link below) using the `COPY` command
3. Run queries top to bottom — each section is self-contained
4. Expected results are included in comments after each query

**Dataset source:**
[Kaggle — Global CO₂ Emissions by Sector](https://www.kaggle.com)
