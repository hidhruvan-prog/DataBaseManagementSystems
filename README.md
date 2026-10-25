# Database Management Systems – FoodExpress (Online Food Delivery System)

Database Management Systems coursework by **Dhruvan Karthik**.
All assignments are built on one project: **FoodExpress**, a food delivery platform that connects customers, restaurants and delivery agents. The database is implemented in **MySQL 8.0**.

## Earlier work

- [Food_Delivery_DBMS_Assignment_3.docx](Food_Delivery_DBMS_Assignment_3.docx): the proposed database design that Assignments 3–9 build on

## Assignment reports (PDF)

| # | Assignment | File |
|---|------------|------|
| 3 | Database Design Analysis – redundancy, anomalies, functional dependencies, normalization, improvements | [Assignment_3_Normalization.pdf](Assignment_3_Normalization.pdf) |
| 4 | Relational Database vs. NoSQL Database – comparative report | [Assignment_4_RDBMS_vs_NoSQL.pdf](Assignment_4_RDBMS_vs_NoSQL.pdf) |
| 5 | Database Creation and Table Implementation (DDL) | [Assignment_5_Database_Creation.pdf](Assignment_5_Database_Creation.pdf) |
| 6 | Implementation of Data Integrity Constraints | [Assignment_6_Integrity_Constraints.pdf](Assignment_6_Integrity_Constraints.pdf) |
| 7 | Sample Data Insertion | [Assignment_7_Sample_Data_Insertion.pdf](Assignment_7_Sample_Data_Insertion.pdf) |
| 8 | Basic SQL Queries and Aggregate Functions | [Assignment_8_Basic_SQL_Queries.pdf](Assignment_8_Basic_SQL_Queries.pdf) |
| 9 | Advanced SQL Queries Using Joins and Subqueries | [Assignment_9_Joins_and_Subqueries.pdf](Assignment_9_Joins_and_Subqueries.pdf) |

Each report contains explanations, the SQL statements, and the actual MySQL console output of every statement.

## Database schema

Nine tables in the finalized design (Assignment 3):

`customers` · `addresses` · `restaurants` · `menu_items` · `delivery_agents` · `orders` · `order_items` · `payments` · `reviews`

There are also two views for derived data: `v_order_totals` and `v_restaurant_ratings`.

## SQL scripts

Run them in this order with the MySQL client (MySQL 8.0.16 or later is needed for CHECK constraints):

| Script | Assignment | Purpose |
|--------|-----------|---------|
| [`sql/01_create_database.sql`](sql/01_create_database.sql) | 5 | Creates the `foodexpress` database, 9 tables (PK/FK) and 2 views |
| [`sql/02_constraints.sql`](sql/02_constraints.sql) | 6 | Adds UNIQUE, CHECK and DEFAULT constraints and 2 triggers |
| [`sql/03_constraint_tests.sql`](sql/03_constraint_tests.sql) | 6 | Verification tests. Run with `--force`; 25 statements are *meant* to fail |
| [`sql/04_sample_data.sql`](sql/04_sample_data.sql) | 7 | Inserts 442 rows of sample data |
| [`sql/05_basic_queries.sql`](sql/05_basic_queries.sql) | 8 | WHERE, ORDER BY, GROUP BY, HAVING, aggregates, DML |
| [`sql/06_advanced_queries.sql`](sql/06_advanced_queries.sql) | 9 | Joins, subqueries, CTEs and window functions |

```bash
mysql -u root -p < sql/01_create_database.sql
mysql -u root -p < sql/02_constraints.sql
mysql -u root -p --force < sql/03_constraint_tests.sql
mysql -u root -p < sql/04_sample_data.sql
mysql -u root -p foodexpress < sql/05_basic_queries.sql
mysql -u root -p foodexpress < sql/06_advanced_queries.sql
```

All names, phone numbers and e-mail addresses in the sample data are fictitious.
