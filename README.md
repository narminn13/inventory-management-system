# Inventory & Warehouse Management System

An Oracle SQL and PL/SQL database project designed to manage inventory operations across multiple warehouses.

## Project Overview

The Inventory & Warehouse Management System provides a structured database solution for managing products, suppliers, purchase orders, sales orders, warehouse inventory, and stock transfers.

The system focuses on inventory accuracy, stock availability, transaction consistency, and inventory valuation.

## Technologies

- Oracle SQL
- PL/SQL
- SQL Developer
- draw.io

## Database Structure

The database consists of 12 main tables:

| Table | Description |
|---|---|
| categories | Product categories |
| products | Product information |
| suppliers | Supplier details |
| warehouses | Warehouse information |
| inventory | Product quantities and costs per warehouse |
| purchase_orders | Purchase order records |
| purchase_order_items | Products included in purchase orders |
| sales_orders | Sales order records |
| sales_order_items | Products included in sales orders |
| stock_movements | Inventory movement history |
| stock_transfers | Transfers between warehouses |
| stock_transfer_items | Products included in transfers |

## Key Features

### Inventory Management
- Track product quantities across multiple warehouses.
- Calculate available stock by subtracting reserved quantities from on-hand quantities.
- Monitor inventory levels and identify products requiring replenishment.
- Maintain stock movement history.

### Purchase Management
- Manage suppliers and purchase orders.
- Track ordered and received quantities.
- Update inventory after purchase receipts.
- Calculate weighted average inventory cost.

### Sales Management
- Create and manage sales orders.
- Validate available stock before confirming orders.
- Reserve inventory for confirmed orders.
- Release reservations when orders are cancelled.
- Update inventory after order fulfillment.

### Warehouse Transfers
- Transfer products between warehouses.
- Validate available stock before dispatch.
- Track transfers through DRAFT, APPROVED, IN_TRANSIT, RECEIVED, and CANCELLED statuses.
- Support full-receipt transfers.

### Inventory Valuation
- Apply the weighted average costing method.
- Calculate inventory value per warehouse.
- Calculate total inventory value across warehouses.

## SQL Concepts

The project demonstrates:

- SELECT, WHERE, ORDER BY
- Aggregate functions
- GROUP BY and HAVING
- INNER JOIN and OUTER JOIN
- Subqueries and correlated subqueries
- Common Table Expressions (CTEs)
- Window functions
- Analytical queries
- Indexing
- Constraints

## PL/SQL Concepts

The project includes:

- Stored procedures
- Stored functions
- Database triggers
- Explicit cursors
- Exception handling
- Transactions
- COMMIT and ROLLBACK
- SAVEPOINT

## Business Rules

1. Available stock is calculated as on-hand quantity minus reserved quantity.
2. Inventory quantities cannot become negative.
3. Reserved quantities cannot exceed on-hand quantities.
4. Sales orders must pass stock validation before confirmation.
5. Confirmed sales orders reserve inventory.
6. Cancelled confirmed orders release their reservations.
7. Inventory costs are calculated using weighted average costing.
8. Stock transfers require different source and destination warehouses.
9. Transfers must be dispatched before they can be received.
10. Stock transfers support full receipts only.

## Project Structure

```text
inventory-management-system/
│
├── documentation/
│   └── business_requirements.md
│
├── erd/
│   └── inventory_erd.png
│
├── database/
│   ├── 01_create_tables.sql
│   ├── 02_insert_data.sql
│   └── 03_indexes.sql
│
├── queries/
│   ├── 01_basic_queries.sql
│   ├── 02_joins.sql
│   ├── 03_subqueries.sql
│   ├── 04_ctes.sql
│   ├── 05_window_functions.sql
│   └── 06_analytical_queries.sql
│
├── plsql/
│   ├── 01_procedures.sql
│   ├── 02_functions.sql
│   ├── 03_triggers.sql
│   └── 04_transactions.sql
│
└── tests/
    ├── test_inventory.sql
    ├── test_purchase_orders.sql
    └── test_stock_transfers.sql