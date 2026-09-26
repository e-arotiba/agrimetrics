# Assumptions & Data Quality Notes

## Revenue Assumption

The synthetic dataset does not include recorded revenue data. To enable profitability analysis, a selling price of **₦2,700/kg** live weight is assumed.

This figure is used consistently everywhere profitability is calculated: cost-per-kg estimates in the SQL/Excel layer, and Revenue, Profit, and Profit Margin on the Power BI dashboard's Batch Profitability page. It is an assumption, not a modeled or sourced market price, and is stated directly on the dashboard page itself as well as here.

## FCR Distribution

The real FCR values across the 12 batches span **1.53 to 2.08**, with a farm-wide average of **~1.84**, a meaningfully wide spread. An earlier version of this document incorrectly described this range as a narrow 2.26 to 2.28; that has been corrected here.

## FCR Conditional Formatting

The FCR column in the Excel Batch Scorecard uses a **3-band color system**, not a continuous color scale:

| Band | Range | Color |
|---|---|---|
| Efficient | fcr < 1.72 | Green |
| Watch | 1.72 to 1.95 | Amber |
| Inefficient | fcr > 1.97 | Red |

(Values between 1.95 and 1.97 fall outside all three bands by design, avoiding rule overlap at the boundary; no batch in the current dataset lands in that narrow gap.) This discrete banding was chosen over a continuous color scale because a gradient across the real 1.53 to 2.08 range doesn't map cleanly onto meaningful operational thresholds; fixed cutoffs communicate "efficient / watch / inefficient" more directly than a relative gradient would.

The mortality rate column (0.58% to 4.16%) uses its own separate 3-band system (under 1%, 1 to 1.85%, over 2.5%) as a supplementary visual layer, independent of the `operational_status` classification below. The upper cutoff (2.5%) intentionally mirrors the ALERT mortality benchmark used there.

## Risk Flagging Methodology (`operational_status`)

Batch risk flags are calculated using **data-relative benchmarks** (farm-wide averages) rather than hardcoded thresholds. This logic is implemented twice, independently: once in SQL (`02_analysis_queries.sql`, `04_excel_export_query.sql`) feeding the Excel scorecard, and again as a DAX calculated column in Power BI (`Operational Status` on `batch_summary_metrics`), so both outputs classify batches identically.

**Revision history:**
- **v1** used a fixed FCR threshold (`fcr > 2.0`), which flagged all 12 batches identically as ALERT. The threshold didn't match this farm's actual FCR range, so it provided zero differentiation.
- **v2** replaced the fixed threshold with a benchmark-relative one (`fcr > avg_fcr * 1.005`, a 0.5% buffer), calibrated against an earlier, incorrect belief that the real FCR range was narrow (2.26 to 2.28). Once corrected against the actual 1.53 to 2.08 range, this buffer turned out to be smaller than the data's own rounding precision (2 decimal places), so nearly every above-average batch skipped straight to ALERT, and the middle "ATTENTION" tier never fired for any of the 12 batches. Same failure mode as v1, reintroduced in a subtler form.
- **v3 (current)** widens the buffer to `avg_fcr * 1.05` (5%), calibrated against the real 1.53 to 2.08 range. This restores genuine three-tier differentiation: **4 OPTIMAL, 2 ATTENTION, 6 ALERT** across the 12 batches, consistent across both the SQL/Excel output and the Power BI dashboard.

Mortality risk uses a separate benchmark (`mortality_rate_pct > avg_mortality * 1.5`, approximately 2.5%) and was not affected by this issue. The mortality range is wide enough that a 1.5x multiplier differentiates meaningfully on its own.

## Workbook Data-Quality Notes

- The **"Cost Breakdown" pivot table** in `farm_summary_workbook.xlsx` was previously found to be built on a stale data cache, disagreeing with `financials.csv` by roughly ₦26M. It has since been rebuilt on a live named Table (`tbl_Financials`) and refreshed. The verified farm-wide total cost, matching `financials.csv`, the Batch Scorecard, and the Cost Breakdown grand total, is **₦79,744,322.68**.
- The `status` field (`Active` / `Completed`) in `batches.csv` and `batch_summary_metrics.csv` reflects whichever date the data-generation notebook was last run; it is not automatically kept current. Two batches (`BATCH-2026-010`, `BATCH-2026-011`) were found and corrected from a stale "Active" to "Completed." Re-verify this field against each batch's `end_date` before any future publish, if the dataset is regenerated or significant time has passed.
