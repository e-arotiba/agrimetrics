-- AgriMetrics Farm Manager: Advanced Insights & Window Functions
-- Database: agrimetrics_db

USE agrimetrics_db;

-- 1. Age-Specific Mortality Vulnerability Window
-- Purpose: Identifies which week or day of life experiences the highest risk 
--          of death across all batches combined to optimize biosecurity protocols.

SELECT 
    CEIL(age_days / 7.0) AS production_week,
    age_days,
    SUM(mortality_count) AS total_mortality_count,
    ROUND(AVG(mortality_count), 2) AS avg_daily_mortality
FROM daily_logs
GROUP BY age_days, CEIL(age_days / 7.0)
ORDER BY total_mortality_count DESC;


-- 2. Performance Tiers Using Window Functions (`NTILE`)
-- Purpose: Automatically groups and categorizes batches into 4 efficiency quartiles 
--          based on their Feed Conversion Ratio (FCR).

SELECT 
    batch_id,
    breed_type,
    fcr,
    mortality_rate_pct,
    NTILE(4) OVER (ORDER BY fcr ASC) AS performance_tier
FROM batch_summary_metrics
ORDER BY fcr ASC;


-- 3. Cumulative Feed Spend vs. Weight Gain Ratio
-- Purpose: Isolates feed expenses specifically and links them to final harvest weight 
--          to evaluate cost efficiency per batch.

SELECT 
    b.batch_id,
    b.breed_type,
    m.final_weight_kg,
    ROUND(SUM(f.cost_naira), 2) AS total_feed_spend_naira,
    ROUND(SUM(f.cost_naira) / NULLIF(m.final_weight_kg, 0), 2) AS feed_cost_per_kg_naira
FROM batches b
JOIN batch_summary_metrics m ON b.batch_id = m.batch_id
JOIN financials f ON b.batch_id = f.batch_id
WHERE f.expense_category = 'Feed Purchase'
GROUP BY b.batch_id, b.breed_type, m.final_weight_kg
ORDER BY feed_cost_per_kg_naira ASC;
