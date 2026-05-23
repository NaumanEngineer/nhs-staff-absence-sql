# 🏥 NHS Staff Absence SQL Analysis
### SQL-based workforce intelligence across 5 NHS Trusts — 75,824 absence records

![MySQL](https://img.shields.io/badge/MySQL-9.4-blue?style=flat-square&logo=mysql)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange?style=flat-square)
![NHS](https://img.shields.io/badge/NHS-Workforce%20Intelligence-005EB8?style=flat-square)
![Records](https://img.shields.io/badge/Records-75%2C824-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📋 Project Overview

A complete SQL analysis of NHS staff absence records across five NHS Trusts within an Integrated Care Board (ICB) for the full calendar year 2023. Using 15 SQL queries across 6 structured sessions, the analysis surfaces clinically actionable workforce intelligence from 75,824 individual absence events.

This project forms part of an 18-month NHS Health & Care AI learning roadmap and demonstrates SQL competency at NHS Band 7 analyst level.

---

## 📊 Key Statistics

| Metric | Value |
|--------|-------|
| Total absence records | **75,824** |
| Working days lost | **206,014** |
| Average absence duration | **2.72 days** |
| Trusts analysed | **5** (2 Acute, 1 Community, 1 Mental Health, 1 Primary Care) |
| Analysis period | **Full year 2023** |
| SQL queries | **15 across 6 sessions** |
| Database | **MySQL Server 9.4** |

---

## 🔍 Five Headline Findings

**1. Every trust exceeds its absence target by over 75%**
MHT worst at 10.33% against a 5.00% target — a system-wide workforce crisis, not individual trust failure.

**2. Winter generates 49% more absences than summer**
31.8% of annual absence is consumed in Q1 alone. Winter planning that begins in October is already too late.

**3. December spikes +56.6% month-on-month**
The steepest and most dangerous operational transition of the year — an annual cliff edge NHS ICBs must plan for in September.

**4. Same volume, different problems**
MHT (ranked 1st for absence rate) needs a wellbeing intervention. WGH (ranked 1st for unauthorised absence) needs governance enforcement. SQL decomposition reveals what aggregate figures hide.

**5. 206,014 working days lost**
Equivalent to removing 800 full-time staff from the NHS for an entire year — the hidden cost of absence that never appears in headline figures.

---

## 🗂️ Repository Structure

```
nhs-staff-absence-sql/
│
├── 📄 queries.sql                              # All 15 SQL queries (6 sessions)
├── 📊 nhs_staff_absence.csv                   # Synthetic absence dataset (75,824 rows)
├── 📋 NHS_Staff_Absence_Intelligence_Report.docx  # Full NHS-branded analysis report
└── 📖 README.md                               # This file
```

---

## 🚀 Getting Started

### Prerequisites
- MySQL Server 8.0+
- MySQL Workbench (or any SQL client)

### Setup

```sql
-- 1. Create the database
CREATE DATABASE nhs_absence;
USE nhs_absence;

-- 2. Create the table
CREATE TABLE staff_absence (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    trust_code VARCHAR(10),
    trust_name VARCHAR(100),
    trust_type VARCHAR(50),
    staff_group VARCHAR(50),
    absence_reason VARCHAR(50),
    duration_days INT,
    month INT,
    month_name VARCHAR(20),
    day_of_week VARCHAR(20),
    is_winter_month INT
);

-- 3. Import the CSV (update path as needed)
LOAD DATA INFILE '/path/to/nhs_staff_absence.csv'
INTO TABLE staff_absence
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Run queries from queries.sql
```

---

## 📈 SQL Sessions & Concepts Covered

| Session | Focus | Key Concepts |
|---------|-------|-------------|
| Session 1 | Exploratory analysis | SELECT, COUNT, GROUP BY, ORDER BY |
| Session 2 | Filtering | WHERE, AND, OR, IN, BETWEEN, NOT, != |
| Session 3 | Aggregations | SUM, AVG, MIN, MAX, HAVING, ROUND |
| Session 4 | Multi-table analysis | INNER JOIN, LEFT JOIN, aliases |
| Session 5 | Advanced analytics | RANK, PARTITION BY, LAG, SUM OVER, CASE WHEN, CTEs |
| Session 6 | Portfolio packaging | NHS intelligence report |

---

## 🔑 Selected Query Highlights

### Running total with percentage of annual
```sql
SELECT month, month_name,
    COUNT(*) AS monthly_absences,
    SUM(COUNT(*)) OVER (ORDER BY month) AS running_total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_annual
FROM staff_absence
GROUP BY month, month_name
ORDER BY month;
```

### Month-on-month change with LAG
```sql
SELECT month, month_name, COUNT(*) AS monthly_absences,
    COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY month) AS change,
    ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY month)) * 100.0 /
        LAG(COUNT(*)) OVER (ORDER BY month), 1) AS pct_change
FROM staff_absence
GROUP BY month, month_name
ORDER BY month;
```

### CTE-based intelligence summary
```sql
WITH trust_summary AS (
    SELECT sa.trust_code, tt.region, COUNT(*) AS trust_absences,
        ROUND(COUNT(*) * 100.0 / (tt.total_staff * 365), 2) AS absence_rate,
        SUM(CASE WHEN sa.absence_reason = 'Unauthorised' THEN 1 ELSE 0 END) AS unauthorised_count
    FROM staff_absence sa
    INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
    GROUP BY sa.trust_code, tt.region, tt.total_staff
)
SELECT trust_code, region, absence_rate, unauthorised_count,
    RANK() OVER (ORDER BY absence_rate DESC) AS absence_rank,
    RANK() OVER (ORDER BY unauthorised_count DESC) AS unauthorised_rank
FROM trust_summary ORDER BY absence_rank;
```

---

## 📋 Five Recommendations

1. **Commission MHT wellbeing review** — absence rate 10.33% driven by sickness and compassionate leave signals clinical burnout, not governance failure
2. **Investigate WGH unauthorised absence** — 2,849 unexplained events requires disciplinary review and return-to-work protocol
3. **Shift winter planning to September** — data proves October is already too late
4. **Review NHS absence targets** — all five trusts exceed targets by 75–109%, suggesting targets are disconnected from operational reality
5. **Deploy monthly SQL absence dashboard** — these 15 queries are reusable and suitable for automation via Power BI or reporting suite

---

## 🛠️ Technology Stack

| Tool | Purpose |
|------|---------|
| MySQL Server 9.4 | Database engine |
| MySQL Workbench | SQL editor and query execution |
| Python (pandas) | Synthetic dataset generation |
| Microsoft Word | Portfolio report production |

---

## 📄 Documentation

The full **NHS Staff Absence Intelligence Report** is included in this repository. It contains:
- Executive summary with five headline findings
- Clinical findings with supporting tables
- Complete SQL query library with syntax highlighting
- Five evidence-based recommendations with implementation timelines
- SQL competency appendix

---

## ⚠️ Data Notice

This project uses **synthetic data** generated to reflect realistic NHS operational patterns. No real patient, staff, or organisational data was used. The dataset was designed for learning and portfolio purposes only.

---

## 🎓 Learning Context

This project was completed as part of an 18-month NHS Health & Care AI Roadmap targeting Band 7/8a NHS data science and informatics roles. SQL Week (Sessions 1–6) follows completion of the NHS OPEL Level Predictor ML project.

**Related portfolio projects:**
- [NHS OPEL Level Predictor](https://github.com/NaumanEngineer/nhs-opel-predictor) — Machine learning, SHAP explainability, clinical governance

---

## 📞 Contact

**Author:** Nauman Engineer
**GitHub:** [NaumanEngineer](https://github.com/NaumanEngineer)
**Related project:** [NHS OPEL Predictor](https://github.com/NaumanEngineer/nhs-opel-predictor)

---

## 📜 License

This project is licensed under the MIT License.

---

*Part of the NHS Health & Care AI 18-Month Roadmap — SQL Week Portfolio Project*
