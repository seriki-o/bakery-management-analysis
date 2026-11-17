# SQL Business Analysis

## Overview

SQL Server was used to analyse six months of synthetic bakery business data covering January to June 2026. The analysis focused on four major areas: sales and revenue performance, product performance and profitability, inventory and procurement, and production and fulfilment efficiency.

The objective was to examine business performance, identify operational patterns, evaluate resource utilisation and derive insights that could support management decision-making.

---

## 1. Sales and Revenue Performance

### Business Questions

- How did sales and revenue change over the reporting period?
- Which products, sizes and varieties generated the most revenue?
- How did online and walk-in sales compare?
- Which days and weeks recorded the highest sales activity?
- How did order cancellations, discounts and refunds affect sales performance?

### Analysis Performed

The analysis examined order values, units sold, average order value, monthly revenue, production costs and operating expenses.

Sales performance was also compared across product varieties, product sizes and order channels. Daily and weekly sales aggregations were used to examine transaction patterns and identify periods of higher sales activity.

Order statuses and payment adjustments were examined to understand cancellations and refunds.

### Key Findings

- **Total completed orders:** 4,055
- **Completed order value:** ₦20,259,700
- **Units sold:** 6,036
- **Average order value:** ₦4,996.22
- **Product range:** 14 products

The results provide a baseline for evaluating sales volume, revenue generation and customer purchasing activity.

The completed order value represents recorded sales from completed orders and should not be interpreted as cash received.

---

## 2. Product Performance and Profitability

### Business Questions

- Which products generated the highest sales revenue?
- Which products sold in the highest quantities?
- Which frequently purchased products generated relatively lower revenue?
- How did product varieties and sizes compare?
- How did estimated ingredient costs compare with selling prices?

### Analysis Performed

Product performance was evaluated using sales quantities, total revenue and average selling prices.

The analysis compared product varieties and sizes to identify differences in sales volume and revenue contribution.

Production records and batch ingredient costs were also examined to calculate ingredient costs per accepted production unit.

Recipe data and average ingredient costs were used to estimate ingredient costs per product and compare them with selling prices.

### Key Findings

The five highest-selling products by units sold were:

| Product | Units Sold |
|---|---:|
| Classic Banana Bread | 531 |
| Chocolate Chip Banana Bread | 498 |
| Chocolate and Coconut Banana Bread | 488 |
| White Chocolate Banana Bread | 482 |
| Chocolate Banana Bread | 480 |

Classic Banana Bread recorded the highest unit sales, followed by Chocolate Chip Banana Bread and Chocolate and Coconut Banana Bread.

The analysis also introduced estimated ingredient margins to compare product selling prices with their estimated recipe ingredient costs.

**Interpretation:** These comparisons provide a basis for evaluating product demand and ingredient cost exposure. However, estimated ingredient margins do not represent actual gross or net profit because other production and operating costs are not fully included.

---

## 3. Inventory and Procurement Analysis

### Business Questions

- Which ingredients were consumed most quickly?
- What were the average monthly ingredient consumption levels?
- Which ingredients were purchased most frequently?
- How did ingredient purchase prices change over time?
- Were procurement quantities aligned with production consumption?
- What inventory movements and waste records were observed?

### Analysis Performed

Ingredient consumption was analysed using inventory movement records classified as production consumption.

Average monthly consumption was calculated across the six-month reporting period.

Procurement analysis examined purchase frequency, quantities purchased, total spending, weighted average unit prices and monthly purchase price trends.

Inventory balances were calculated by aggregating recorded inventory movements. Purchase receipts were also compared with production consumption to examine the relationship between procurement and ingredient usage.

Additional analysis examined inventory movement types, recorded reasons and finished-product waste.

### Key Findings

**Total ingredient consumption**

| Ingredient | Quantity Consumed |
|---|---:|
| Bananas | 837,900 g |
| Flour | 628,425 g |
| Sugar | 418,950 g |
| Butter | 251,370 g |
| Water | 69,860 ml |
| Tigernuts | 21,760 g |

Bananas recorded the highest consumption volume, followed by flour, sugar and butter.

**Procurement spending**

| Ingredient | Total Purchase Spending |
|---|---:|
| Butter | ₦3,069,391.36 |
| Bananas | ₦1,318,520.35 |
| Flour | ₦1,309,454.65 |
| Sugar | ₦1,163,712.16 |
| Eggs | ₦1,072,059.50 |

Butter recorded the highest total procurement spending among these ingredients.

**Ingredient price movements**

The comparison of January and June weighted average purchase prices showed increases across several ingredients:

| Ingredient | Price Increase |
|---|---:|
| Tigernuts | 14.9% |
| Dark chocolate | 14.5% |
| Chocolate chips | 13.9% |
| Butter | 11.3% |
| White chocolate | 11.0% |
| Sugar | 8.0% |
| Flour | 7.5% |
| Bananas | 7.3% |
| Eggs | 7.0% |

These increases indicate rising ingredient procurement costs during the reporting period.

**Inventory and waste observations**

- Inventory balances varied considerably across ingredients.
- Purchase receipts and production consumption did not always match within the reporting period.
- The inventory records included opening stock, purchase receipts, production consumption, production output, sales and production waste.
- A total of 100 finished-product units were recorded as production waste across 99 waste records.
- Chocolate Chip Banana Bread recorded the highest waste quantity, with 12 units across 11 records.

The differences between purchases and consumption should not automatically be interpreted as shortages because opening and previously accumulated inventory balances also affect available stock.

---

## 4. Production and Fulfilment Efficiency

### Business Questions

- How did batch production compare with made-to-order production?
- How much product was produced, accepted and wasted?
- How did production output compare with completed sales demand?
- Were there significant variations in ingredient usage across production batches?
- Which products recorded the highest waste rates?
- What operational activities were captured in the audit logs?

### Analysis Performed

Production records were analysed by production type to compare the number of production runs, total output, accepted quantities and wasted units.

Production quantities were also compared across individual products and against completed sales quantities.

Ingredient usage per production unit was examined to identify variations between recorded production batches.

Waste rates were calculated using total wasted units divided by total produced units. Audit logs were also grouped by table and action to examine recorded system activity.

### Key Findings

**Production performance by production type**

| Metric | Batch | Made-to-Order | Total |
|---|---:|---:|---:|
| Production runs | 3,882 | 1,490 | 5,372 |
| Units produced | 4,599 | 1,537 | 6,136 |
| Accepted units | 4,520 | 1,516 | 6,036 |
| Wasted units | 79 | 21 | 100 |
| Waste rate | 1.72% | 1.37% | 1.63% |

Batch production accounted for approximately 74.95% of production runs, while made-to-order production accounted for 25.05%.

The overall production waste rate was 1.63%.

**Product waste analysis**

Chocolate Chip Banana Bread recorded the highest waste quantity, with 12 wasted units. Its waste rate was approximately 2.35%.

Other products with relatively higher waste rates included:

- Chocolate Banana Bread: 2.04%
- White Chocolate Banana Bread: 2.03%
- Marble Banana Bread: 1.96%
- Red Velvet Banana Bread: 1.90%

**Production and sales comparison**

Total accepted production output and completed units sold both amounted to 6,036 units across the reporting period.

This provides an aggregate comparison of production output and sales demand, although it does not establish that each product was sold immediately after production or that no unsold inventory remained.

---

## 5. SQL Techniques Applied

The analysis involved several SQL Server querying and data manipulation techniques, including:

| Technique | Application |
|---|---|
| SELECT and filtering | Retrieving relevant business records and filtering by status and reporting period. |
| JOINs | Combining related records across orders, products, production, inventory and procurement tables. |
| GROUP BY and aggregate functions | Calculating revenue, quantities, costs, purchase frequency and production totals. |
| CASE expressions | Separating inventory movement types and calculating conditional totals. |
| Common Table Expressions (CTEs) | Organising ingredient cost calculations and recipe-based profitability estimates. |
| Subqueries | Aggregating production costs and operating expenses before combining them with sales data. |
| Date functions | Analysing monthly, daily and weekly business activity. |
| NULLIF and COALESCE | Handling zero denominators and missing values in calculations. |
| Data type conversion and rounding | Formatting calculated financial metrics and numerical results. |
| MIN, MAX and AVG | Examining ingredient price ranges and production usage variations. |

---

## 6. Overall Analytical Findings

The combined SQL analysis provided insight into the bakery's sales performance, product demand, procurement spending, inventory movements and production operations.

Key observations included:

- The bakery recorded ₦20.26 million in completed order value across 4,055 completed orders.
- Classic Banana Bread was the highest-selling product by quantity.
- Butter accounted for the highest procurement spending among the highlighted ingredients.
- Several ingredient prices increased between January and June.
- Batch production represented the larger share of production activity.
- The overall recorded production waste rate was 1.63%.
- Chocolate Chip Banana Bread had the highest recorded product waste quantity.

These findings informed the development of the Power BI dashboard, which presents the results through five analytical pages covering management overview, sales and product performance, financial performance, inventory and procurement, and production and operations.

## 7. Analytical Limitations

The analysis was subject to several limitations in the available data:

- The dataset is synthetic and represents simulated bakery operations.
- Ingredient cost estimates do not include every expense associated with production.
- Estimated ingredient margins should not be interpreted as net profit.
- Minimum inventory thresholds were not defined, so formal low-stock alerts and stockout risk assessments could not be established.
- Production completion and delivery timestamps were unavailable, preventing fulfilment duration analysis.
- Aggregate production and sales totals do not establish the timing of individual product sales.
- Employee activity records provide traceability but do not independently measure employee productivity.

