-- ============================================================
-- 04_excel_export_query.sql
-- One row per batch, combining everything needed for the Excel
-- summary workbook (Phase 3): cost efficiency + FCR + mortality
-- + risk status, all in a single result set.
--
-- Verified against real data: 12 rows returned, matches the
-- individual Query 2 (cost per kg) and Query 3 (risk flagging)
-- results from 02_analysis_queries.sql exactly.
--
-- The ALERT/ATTENTION/OPTIMAL threshold below (avg_fcr * 1.05)
-- is kept in sync with Query 3 in 02_analysis_queries.sql — see
-- that file's revision history comment for why it's 1.05 and not
-- the earlier 1.005.
-- ============================================================

USE agrimetrics_db;

WITH benchmarks AS (
    SELECT AVG(fcr) AS avg_fcr, AVG(mortality_rate_pct) AS avg_mortality
    FROM batch_summary_metrics
)
SELECT
    b.batch_id,
    b.breed_type,
    m.initial_stock,
    m.final_weight_kg,
    COALESCE(SUM(f.cost_naira), 0) AS total_cost_naira,
    ROUND(COALESCE(SUM(f.cost_naira), 0) / NULLIF(m.final_weight_kg, 0), 2) AS cost_per_kg_naira,
    m.mortality_rate_pct,
    m.fcr,
    CASE
        WHEN m.fcr > bm.avg_fcr * 1.05 OR m.mortality_rate_pct > bm.avg_mortality * 1.5
            THEN 'ALERT'
        WHEN m.fcr > bm.avg_fcr
            THEN 'ATTENTION'
        ELSE 'OPTIMAL'
    END AS operational_status
FROM batches b
JOIN batch_summary_metrics m ON b.batch_id = m.batch_id
CROSS JOIN benchmarks bm
LEFT JOIN financials f ON b.batch_id = f.batch_id
GROUP BY b.batch_id, b.breed_type, m.initial_stock, m.final_weight_kg,
         m.mortality_rate_pct, m.fcr, bm.avg_fcr, bm.avg_mortality
ORDER BY b.batch_id;
