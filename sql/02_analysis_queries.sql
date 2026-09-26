-- 02_analysis_queries.sql
-- AgriMetrics Farm Manager — Business Intelligence Queries
-- Database: agrimetrics_db

-- All 4 queries verified against real farm data (12 batches).

USE agrimetrics_db;

-- 1. Financial Cost Breakdown by Category
-- Purpose: Total spend per expense type and its share of overall cost.
SELECT
    expense_category,
    COUNT(*) AS total_transactions,
    ROUND(SUM(cost_naira), 2) AS total_expense_naira,
    ROUND((SUM(cost_naira) / (SELECT SUM(cost_naira) FROM financials)) * 100, 2) AS pct_of_total_cost
FROM financials
GROUP BY expense_category
ORDER BY total_expense_naira DESC;

-- 2. Batch Cost Efficiency & Cost-Per-KG
-- Purpose: Merges operational metrics with financial spend for true production cost per kg.
SELECT
    b.batch_id,
    b.breed_type,
    m.initial_stock,
    m.final_weight_kg,
    COALESCE(SUM(f.cost_naira), 0) AS total_batch_cost_naira,
    ROUND(COALESCE(SUM(f.cost_naira), 0) / NULLIF(m.final_weight_kg, 0), 2) AS cost_per_kg_naira
FROM batches b
JOIN batch_summary_metrics m ON b.batch_id = m.batch_id
LEFT JOIN financials f ON b.batch_id = f.batch_id
GROUP BY b.batch_id, b.breed_type, m.initial_stock, m.final_weight_kg
ORDER BY cost_per_kg_naira ASC;

-- 3. Operational Performance & Risk Flagging
-- Purpose: Flags batches that underperform relative to the farm's own average,
--          rather than a fixed industry threshold.
--
--          REVISION HISTORY:
--          v1 used a hardcoded "fcr > 2.0" threshold, which flagged 100% of
--          batches as ALERT because it didn't match this farm's actual FCR
--          distribution at all.
--          v2 switched to a data-relative benchmark (avg_fcr * 1.005, a 0.5%
--          buffer) — but this farm's real FCR range across the 12 batches is
--          1.53-2.08 (avg ~1.84), not the narrow 2.26-2.28 band the 0.5%
--          buffer was calibrated for. At this range, a 0.5% buffer is
--          smaller than the data's own rounding precision (2 decimal
--          places), so almost every above-average batch skipped straight to
--          ALERT and the ATTENTION tier never fired for any of the 12
--          batches — differentiation collapsed to a binary OPTIMAL/ALERT
--          split, the same failure mode v1 had, just shifted.
--          v3 (current) widens the buffer to avg_fcr * 1.05 (5%), which
--          reflects meaningful FCR variation at this farm's actual scale of
--          spread and restores a genuine three-tier split.
	WITH benchmarks AS (
		SELECT AVG(fcr) AS avg_fcr, AVG(mortality_rate_pct) AS avg_mortality
		FROM batch_summary_metrics
	)
	SELECT
		s.batch_id,
		s.breed_type,
		s.mortality_rate_pct,
		s.fcr,
		CASE
			WHEN s.fcr > b.avg_fcr * 1.05 OR s.mortality_rate_pct > b.avg_mortality * 1.5
				THEN 'ALERT: Inefficient / High Waste'
			WHEN s.fcr > b.avg_fcr
				THEN 'ATTENTION: Above Average FCR'
			ELSE 'OPTIMAL: At or Below Average'
		END AS operational_status
	FROM batch_summary_metrics s
	CROSS JOIN benchmarks b
	ORDER BY s.fcr DESC;

	-- 4. Weekly Operational Trend Aggregation
	-- Purpose: Rolls daily logs up into weekly production-cycle checkpoints.
	SELECT
		batch_id,
		CEIL(age_days / 7.0) AS production_week,
		SUM(mortality_count) AS weekly_mortality,
		ROUND(SUM(feed_consumed_kg), 2) AS total_weekly_feed_kg,
		MAX(total_weight_kg) AS end_of_week_weight_kg
	FROM daily_logs
	GROUP BY batch_id, CEIL(age_days / 7.0)
	ORDER BY batch_id, production_week;
