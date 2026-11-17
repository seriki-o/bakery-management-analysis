# Dataset Documentation

## Overview

This directory contains the synthetic datasets used in the Bakery Management & Business Performance Analysis project.

The datasets represent six months of hypothetical bakery operations, covering sales, products, production, inventory, procurement, payments, expenses and employee records.

All datasets are stored in CSV format and were used as the source files for the SQL Server database.

## Data Source and Privacy

All datasets were synthetically generated for this portfolio project.

They do not contain actual business transactions, customer information or confidential business records.

The datasets were created to simulate realistic bakery operations and support database development, data integration, validation and business performance analysis.

## Dataset Contents

The `dataset/` folder contains 17 CSV files corresponding to the relational database tables.

| Dataset | Description |
|---|---|
| `roles.csv` | Employee roles and access categories |
| `employees.csv` | Employee records |
| `products.csv` | Product details and classifications |
| `ingredients.csv` | Ingredient information |
| `suppliers.csv` | Supplier records |
| `recipes.csv` | Ingredient requirements for products |
| `orders.csv` | Online and walk-in order records |
| `order_items.csv` | Products associated with individual orders |
| `payments.csv` | Payment transaction records |
| `payment_adjustments.csv` | Payment corrections and adjustments |
| `production_batches.csv` | Production batch records |
| `batch_ingredients.csv` | Ingredients used in production batches |
| `inventory_movements.csv` | Inventory additions and deductions |
| `purchases.csv` | Procurement transaction records |
| `purchase_items.csv` | Items associated with purchase records |
| `expenses.csv` | Business operating expenses |
| `audit_logs.csv` | Records of tracked operational activities |

## Reporting Period

The datasets cover the period:

**January 1, 2026 – June 30, 2026**

## Data Integration

The CSV files were imported into Microsoft SQL Server using Python.

Two separate loading processes were implemented:

- **Initial loading:** Imported the datasets into an initially empty database while preserving existing ID values and respecting foreign-key dependencies.
- **Incremental loading:** Identified existing records and inserted new records while skipping duplicates.

Pandas and PyODBC were used for CSV processing and SQL Server connectivity.

## Usage

The datasets support:

- Relational database development and testing.
- Initial and incremental data loading.
- Data validation and integrity checks.
- SQL-based business analysis.
- Power BI data modelling and dashboard development.

See the main project [README](../README.md) for the complete project overview and documentation.