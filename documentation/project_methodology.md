# Project Methodology and Implementation

## 1. Project Overview

This project was developed as an end-to-end data management and business intelligence solution for a hypothetical bakery transitioning from an online-only business model to a combination of online and walk-in sales.

The project explores how a relational database and analytical tools can support the management of bakery operations, including sales, production, inventory, procurement, expenses, employee access and operational record-keeping.

The implementation covers business requirements analysis, relational database design, SQL Server development, synthetic dataset preparation, Python-based data integration, data validation, SQL business analysis and Power BI reporting.

### Project Objectives

The main objectives were to:

- Design and implement a relational database for managing bakery operations.
- Organise operational records into related tables while maintaining data integrity.
- Develop Python scripts to load and integrate CSV datasets into SQL Server.
- Implement data validation and database testing procedures.
- Use SQL to investigate business performance across sales, products, inventory, procurement and production.
- Develop an interactive Power BI dashboard to communicate analytical findings.

### Project Technology Stack

| Technology | Purpose |
|---|---|
| Microsoft SQL Server | Relational database development and management |
| T-SQL | Database implementation, validation and business analysis |
| Python | Data loading and supporting utilities |
| Pandas | CSV data handling |
| PyODBC | Python-to-SQL Server connectivity |
| Power BI | Data modelling and interactive reporting |
| Draw.io | Entity Relationship Diagram development |
| Git and GitHub | Version control and project documentation |

---

## 2. Requirements Analysis

The database design was guided by the operational requirements of the hypothetical bakery.

The business scenario required a system capable of supporting both online and walk-in orders, recording production activities, monitoring ingredient movements, tracking purchases and expenses, and maintaining employee-related operational records.

The requirements also considered the need for different employee roles and access levels, alongside audit records for tracking selected operational activities.

These requirements informed the identification of database entities, their attributes and the relationships required to represent the bakery's operations.

### Identified Operational Requirements

The main operational areas considered during the design process included:

- **Sales management:** Recording online and walk-in orders, order items, payments and payment adjustments.
- **Product management:** Maintaining product information, ingredients and recipe requirements.
- **Production management:** Recording production batches, production methods and ingredient usage.
- **Inventory management:** Tracking ingredient movements and stock additions or deductions.
- **Procurement management:** Recording suppliers, purchases and purchased items.
- **Expense management:** Maintaining records of business operating expenses.
- **Employee management:** Organising employee records and assigning roles.
- **Operational traceability:** Maintaining audit records of selected activities.

These requirements formed the basis for the database structure and subsequent analytical work.

---

## 3. Database Design

Microsoft SQL Server was selected as the relational database management system.

The database, named `bakery_management`, was designed around 17 tables representing the main operational areas of the business.

### 3.1 Database Structure

The tables were organised into the following functional areas:

| Functional Area | Tables |
|---|---|
| Sales and orders | `orders`, `order_items`, `payments`, `payment_adjustments` |
| Products and recipes | `products`, `ingredients`, `recipes` |
| Production | `production_batches`, `batch_ingredients` |
| Inventory and procurement | `inventory_movements`, `purchases`, `purchase_items`, `suppliers` |
| Business operations | `expenses` |
| Employee management and access | `employees`, `roles` |
| Operational traceability | `audit_logs` |

Primary keys and foreign keys were used to establish relationships between related records and maintain referential integrity.

An Entity Relationship Diagram (ERD) was developed in Draw.io to represent the database structure and relationships between the tables.

### 3.2 Entity Relationship Diagram

![Entity Relationship Diagram](data_model/entity_relationship_diagram.png)

*Figure 1: Entity Relationship Diagram illustrating the 17 database tables and their relationships.*

The detailed database structure, relationships and design considerations are documented separately in [Database Design](data_model/database_design.md).

---

## 4. Database Implementation

The database schema was implemented in SQL Server using Data Definition Language (DDL).

The implementation involved:

- Creating the database tables.
- Defining columns and appropriate data types.
- Establishing primary and foreign key constraints.
- Applying relevant default values and other constraints.
- Defining identity columns for automatically generated identifiers.

A separate feature engineering script was also developed to introduce additional readable identifiers, including product codes, ingredient codes, order codes, batch codes and purchase codes.

These identifiers provide more meaningful references for operational records and reporting.

### 4.1 Database Implementation Evidence

<img width="261" height="404" alt="Screenshot 2026-11-17 023739" src="https://github.com/user-attachments/assets/de128b11-06e7-4023-b3e0-f425b101db3b" />

*Figure 2: Database implementation in SQL Server, showing the created database and its operational tables.*

---

## 5. Dataset Preparation

Since the project represents a hypothetical business, synthetic datasets were used instead of actual bakery transaction records.

The datasets represent six months of hypothetical bakery operations, covering the period from January 1 to June 30, 2026.

CSV files were prepared for the 17 database tables, with records structured to correspond to the database schema and relationships.

The datasets provide the source records used for database loading, validation, SQL analysis and Power BI reporting.

### 5.1 Dataset Organisation

The CSV files are organised within the repository's `data/dataset/` directory.

The datasets cover:

- Product and ingredient records.
- Employee and role information.
- Supplier and procurement records.
- Orders, order items and payment transactions.
- Production batches and ingredient usage.
- Inventory movements and expenses.
- Audit records.

### 5.2 Dataset Evidence

<img width="692" height="505" alt="Screenshot 2026-11-17 024101" src="https://github.com/user-attachments/assets/d01d11ef-e81f-4462-b54a-d1dfdc23cdea" />

*Figure 3: Sample synthetic dataset prepared for integration into the SQL Server database.*

The CSV files and their descriptions are available in the [`data/dataset`](../data/dataset/) directory. Additional information about the datasets is provided in the [Dataset Documentation](../data/README.md).

---

## 6. Data Integration and Loading

Python was used to automate the transfer of CSV records into SQL Server.

The loading process was implemented using Pandas for reading and handling CSV data and PyODBC for connecting to SQL Server and executing database operations.

Two loading scripts were developed to support different loading scenarios.

### 6.1 Initial Data Loading

The initial loading script was designed to populate an empty database.

Before loading records, the script retrieves database metadata to inspect table structures, column properties, identity columns and foreign key dependencies.

It also checks that the required tables exist and that the target tables are empty before proceeding.

Tables are loaded in dependency order to ensure that referenced records are inserted before dependent records.

Where CSV files contain explicit identity values, `IDENTITY_INSERT` is used to preserve the supplied identifiers.

The script uses batch execution to insert records and commits successful table loads. Errors trigger rollback handling for the affected operation.

### 6.2 Incremental Data Loading

A separate incremental loading script was developed to support subsequent imports without repeatedly inserting existing records.

The script compares incoming records against existing database records using available unique keys. Where suitable unique keys are unavailable, it uses a full-row comparison approach, excluding identity columns where appropriate.

Records already present in the database are skipped, while new records are inserted.

The incremental process is insert-only: it does not update or delete existing records.

This approach allows additional CSV records to be introduced without requiring the database to be emptied and reloaded.

### 6.3 Supporting Python Utilities

Additional Python utilities were developed to support the loading workflow:

| Script | Purpose |
|---|---|
| `test_connection.py` | Checks connectivity to the SQL Server database. |
| `inspect_database.py` | Retrieves and displays database table and column information. |
| `check_csv_columns.py` | Compares CSV column names against corresponding database table structures. |


## 7. Data Validation and Database Testing

SQL scripts were developed to examine the loaded data and test important database conditions.

The validation process was intended to identify inconsistencies that could affect subsequent analysis.

The scripts cover checks on loaded records and database structure, including relevant data consistency and integrity conditions.

Separate scripts were organised for data validation and database testing.

### 7.1 Validation Evidence

<img width="1085" height="556" alt="Screenshot 2026-11-17 025132" src="https://github.com/user-attachments/assets/02192aea-5826-4f0d-8e9a-ef76e678221f" />

*Figure 6: SQL validation checks performed on the populated bakery management database.*

The validation and testing scripts are available in [`database/validation`](../database/validation/).

---

## 8. SQL-Based Business Analysis

After the database was populated and validated, SQL Server was used to investigate the bakery's operational and financial performance.

The analysis was organised into four main areas.

### 8.1 Sales and Revenue Performance

This analysis examined sales activity and revenue patterns, including:

- Order volumes.
- Completed order values.
- Average order value.
- Monthly sales and revenue performance.

### 8.2 Product Performance and Profitability

This analysis examined product sales, quantities sold and product-level performance.

Where cost information was available, product costs and estimated profitability were
