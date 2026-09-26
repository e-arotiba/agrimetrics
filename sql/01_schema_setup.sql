-- 01_schema_setup.sql
-- AgriMetrics Farm Manager — MySQL schema
--
-- Data loading note: after running this script to create the tables,
-- the raw CSV files (data/raw/*.csv) were loaded into their matching
-- tables using MySQL Workbench's Table Data Import Wizard
-- (right-click table -> Table Data Import Wizard).

CREATE DATABASE IF NOT EXISTS agrimetrics_db;
USE agrimetrics_db;

-- Drop tables in reverse order of foreign keys if re-running
DROP TABLE IF EXISTS financials;
DROP TABLE IF EXISTS daily_logs;
DROP TABLE IF EXISTS batch_summary_metrics;
DROP TABLE IF EXISTS batches;

-- 1. Batches Table
CREATE TABLE batches (
    batch_id VARCHAR(50) PRIMARY KEY,
    start_date DATE,
    end_date DATE,
    initial_stock INT,
    breed_type VARCHAR(50),
    primary_feed VARCHAR(50),
    status VARCHAR(20)
);

-- 2. Daily Operational Logs Table
CREATE TABLE daily_logs (
    log_date DATE,
    batch_id VARCHAR(50),
    age_days INT,
    surviving_stock INT,
    mortality_count INT,
    feed_consumed_kg DECIMAL(10,2),
    total_weight_kg DECIMAL(10,2),
    CONSTRAINT fk_daily_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
);

-- 3. Financial Expenses Table
CREATE TABLE financials (
    expense_date DATE,
    batch_id VARCHAR(50),
    expense_category VARCHAR(100),
    cost_naira DECIMAL(15,2),
    CONSTRAINT fk_fin_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
);

-- 4. Batch Summary Metrics Table
CREATE TABLE batch_summary_metrics (
    batch_id VARCHAR(50) PRIMARY KEY,
    total_mortality INT,
    total_feed_consumed_kg DECIMAL(10,2),
    final_weight_kg DECIMAL(10,2),
    start_date DATE,
    end_date DATE,
    initial_stock INT,
    breed_type VARCHAR(50),
    primary_feed VARCHAR(50),
    status VARCHAR(20),
    mortality_rate_pct DECIMAL(5,2),
    fcr DECIMAL(5,2),
    CONSTRAINT fk_summary_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
);
