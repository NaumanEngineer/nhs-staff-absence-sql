-- ============================================================
-- NHS Staff Absence SQL Query Library
-- 15 queries across 6 sessions
-- Database: nhs_absence | Table: staff_absence
-- Analysis period: January - December 2023
-- Records: 75,824 | Trusts: 5
-- ============================================================

USE nhs_absence;

-- ============================================================
-- SESSION 1 — EXPLORATORY QUERIES
-- ============================================================

-- Q1.1 Total record count
SELECT COUNT(*) AS total_records 
FROM staff_absence;

-- Q1.2 Absences by trust (volume)
SELECT 
    trust_code,
    trust_name,
    COUNT(*) AS total_absences
FROM staff_absence
GROUP BY trust_code, trust_name
ORDER BY total_absences DESC;

-- Q1.3 Absence reasons with percentage of total
SELECT 
    absence_reason,
    COUNT(*) AS total_absences,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staff_absence), 1) AS percentage
FROM staff_absence
GROUP BY absence_reason
ORDER BY total_absences DESC;

-- Q1.4 Seasonal pattern by month
SELECT 
    month,
    month_name,
    is_winter_month,
    COUNT(*) AS total_absences
FROM staff_absence
GROUP BY month, month_name, is_winter_month
ORDER BY month;

-- ============================================================
-- SESSION 2 — WHERE FILTERING
-- ============================================================

-- Q2.1 Long-term absences (greater than 5 days)
SELECT COUNT(*) AS long_absences
FROM staff_absence
WHERE duration_days > 5;

-- Q2.2 Sickness absences at WGH and NRI only
SELECT COUNT(*) AS sickness_wgh_nri
FROM staff_absence
WHERE absence_reason = 'Sickness'
AND trust_code IN ('WGH', 'NRI');

-- Q2.3 Unauthorised winter absences by trust and month
SELECT
    trust_code,
    month_name,
    COUNT(*) AS unauthorised_winter
FROM staff_absence
WHERE absence_reason = 'Unauthorised'
AND is_winter_month = 1
GROUP BY trust_code, month_name
ORDER BY trust_code, unauthorised_winter DESC;

-- Q2.4 Q1 nursing absences by trust, month and reason
SELECT
    trust_code,
    month_name,
    absence_reason,
    COUNT(*) AS nursing_absences
FROM staff_absence
WHERE staff_group = 'Nursing'
AND month BETWEEN 1 AND 3
GROUP BY trust_code, month_name, absence_reason
ORDER BY trust_code, month_name;

-- Q2.5 All non-sickness absences with percentage
SELECT
    trust_code,
    absence_reason,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staff_absence WHERE absence_reason != 'Sickness'), 1) AS pct_of_non_sickness
FROM staff_absence
WHERE absence_reason != 'Sickness'
GROUP BY trust_code, absence_reason
ORDER BY trust_code, total DESC;

-- ============================================================
-- SESSION 3 — GROUP BY & AGGREGATIONS
-- ============================================================

-- Q3.1 Average absence duration by trust
SELECT 
    trust_code,
    trust_name,
    ROUND(AVG(duration_days), 1) AS avg_duration_days,
    MIN(duration_days) AS shortest_absence,
    MAX(duration_days) AS longest_absence,
    COUNT(*) AS total_absences
FROM staff_absence
GROUP BY trust_code, trust_name
ORDER BY avg_duration_days DESC;

-- Q3.2 Total days lost by staff group
SELECT
    staff_group,
    COUNT(*) AS total_absences,
    SUM(duration_days) AS total_days_lost,
    ROUND(AVG(duration_days), 1) AS avg_duration
FROM staff_absence
GROUP BY staff_group
ORDER BY total_days_lost DESC;

-- Q3.3 Average absence duration by month
SELECT
    month,
    month_name,
    COUNT(*) AS total_absences,
    ROUND(AVG(duration_days), 2) AS avg_duration,
    SUM(duration_days) AS total_days_lost
FROM staff_absence
GROUP BY month, month_name
ORDER BY avg_duration DESC;

-- Q3.4 Trusts exceeding 5,000 sickness absences (HAVING)
SELECT
    trust_code,
    trust_name,
    COUNT(*) AS sickness_absences
FROM staff_absence
WHERE absence_reason = 'Sickness'
GROUP BY trust_code, trust_name
HAVING sickness_absences > 5000
ORDER BY sickness_absences DESC;

-- Q3.5 Full absence profile by trust and reason
SELECT
    trust_code,
    absence_reason,
    COUNT(*) AS total_absences,
    SUM(duration_days) AS total_days_lost,
    ROUND(AVG(duration_days), 1) AS avg_duration,
    MAX(duration_days) AS longest_absence
FROM staff_absence
GROUP BY trust_code, absence_reason
ORDER BY trust_code, total_absences DESC;

-- ============================================================
-- SESSION 4 — JOINS
-- ============================================================

-- Q4.1 Actual vs target absence rate (INNER JOIN)
SELECT
    sa.trust_code,
    sa.trust_name,
    tt.total_staff,
    tt.absence_target_pct,
    COUNT(*) AS total_absences,
    ROUND(COUNT(*) * 100.0 / (tt.total_staff * 365), 2) AS actual_absence_pct
FROM staff_absence sa
INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
GROUP BY sa.trust_code, sa.trust_name, tt.total_staff, tt.absence_target_pct
ORDER BY actual_absence_pct DESC;

-- Q4.2 All trusts with regional context (LEFT JOIN)
SELECT
    tt.trust_code,
    tt.region,
    tt.total_staff,
    tt.absence_target_pct,
    tt.training_days_target,
    COUNT(sa.trust_code) AS actual_absences
FROM trust_targets tt
LEFT JOIN staff_absence sa ON tt.trust_code = sa.trust_code
GROUP BY tt.trust_code, tt.region, tt.total_staff,
         tt.absence_target_pct, tt.training_days_target
ORDER BY actual_absences DESC;

-- Q4.3 Training days actual vs target with variance
SELECT
    tt.trust_code,
    tt.training_days_target,
    SUM(sa.duration_days) AS actual_training_days,
    SUM(sa.duration_days) - tt.training_days_target AS variance,
    ROUND(SUM(sa.duration_days) * 100.0 / tt.training_days_target, 1) AS pct_of_target
FROM staff_absence sa
INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
WHERE sa.absence_reason = 'Training'
GROUP BY tt.trust_code, tt.training_days_target
ORDER BY pct_of_target DESC;

-- Q4.4 Each trust as percentage of ICB total
SELECT
    trust_code,
    COUNT(*) AS trust_absences,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staff_absence), 2) AS pct_of_icb_total
FROM staff_absence
GROUP BY trust_code
ORDER BY pct_of_icb_total DESC;

-- ============================================================
-- SESSION 5 — WINDOW FUNCTIONS & CTEs
-- ============================================================

-- Q5.1 Rank trusts by absence rate within region (RANK + PARTITION BY)
SELECT
    trust_code,
    region,
    total_staff,
    total_absences,
    absence_rate,
    RANK() OVER (PARTITION BY region ORDER BY absence_rate DESC) AS regional_rank,
    RANK() OVER (ORDER BY absence_rate DESC) AS overall_rank
FROM (
    SELECT
        sa.trust_code,
        tt.region,
        tt.total_staff,
        COUNT(*) AS total_absences,
        ROUND(COUNT(*) * 100.0 / (tt.total_staff * 365), 2) AS absence_rate
    FROM staff_absence sa
    INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
    GROUP BY sa.trust_code, tt.region, tt.total_staff
) AS trust_summary
ORDER BY region, regional_rank;

-- Q5.2 Running total of absences by month (SUM OVER)
SELECT
    month,
    month_name,
    COUNT(*) AS monthly_absences,
    SUM(COUNT(*)) OVER (ORDER BY month) AS running_total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_annual
FROM staff_absence
GROUP BY month, month_name
ORDER BY month;

-- Q5.3 Month on month change using LAG
SELECT
    month,
    month_name,
    COUNT(*) AS monthly_absences,
    LAG(COUNT(*)) OVER (ORDER BY month) AS previous_month,
    COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY month) AS month_on_month_change,
    ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY month)) * 100.0 / 
    LAG(COUNT(*)) OVER (ORDER BY month), 1) AS pct_change
FROM staff_absence
GROUP BY month, month_name
ORDER BY month;

-- Q5.4 Trusts above ICB average absence rate (CASE WHEN + subquery)
SELECT
    trust_code,
    total_absences,
    absence_rate,
    icb_avg_rate,
    absence_rate - icb_avg_rate AS variance_from_avg,
    CASE
        WHEN absence_rate > icb_avg_rate THEN 'Above Average'
        WHEN absence_rate < icb_avg_rate THEN 'Below Average'
        ELSE 'At Average'
    END AS performance_status
FROM (
    SELECT
        sa.trust_code,
        COUNT(*) AS total_absences,
        ROUND(COUNT(*) * 100.0 / (tt.total_staff * 365), 2) AS absence_rate,
        ROUND(AVG(COUNT(*)) OVER () * 100.0 / AVG(tt.total_staff * 365) OVER (), 2) AS icb_avg_rate
    FROM staff_absence sa
    INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
    GROUP BY sa.trust_code, tt.total_staff
) AS trust_rates
ORDER BY absence_rate DESC;

-- Q5.5 Full absence intelligence summary (CTE)
WITH trust_summary AS (
    SELECT
        sa.trust_code,
        tt.region,
        COUNT(*) AS trust_absences,
        ROUND(COUNT(*) * 100.0 / (tt.total_staff * 365), 2) AS absence_rate,
        SUM(CASE WHEN sa.absence_reason = 'Unauthorised' THEN 1 ELSE 0 END) AS unauthorised_count
    FROM staff_absence sa
    INNER JOIN trust_targets tt ON sa.trust_code = tt.trust_code
    GROUP BY sa.trust_code, tt.region, tt.total_staff
)
SELECT
    ts.trust_code,
    ts.region,
    ts.trust_absences,
    ts.absence_rate,
    ts.unauthorised_count,
    RANK() OVER (ORDER BY ts.absence_rate DESC) AS absence_rank,
    RANK() OVER (ORDER BY ts.unauthorised_count DESC) AS unauthorised_rank
FROM trust_summary ts
ORDER BY absence_rank;

-- ============================================================
-- END OF QUERY LIBRARY
-- ============================================================
