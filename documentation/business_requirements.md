
# Inventory & Warehouse Management System

## 1. Project Overview

The Inventory & Warehouse Management System is a relational database solution designed to manage products, suppliers, warehouses, procurement operations, customer orders, and inventory movements.

The system supports multiple warehouses and provides reliable inventory tracking, stock reservation, warehouse transfers, and inventory valuation.

The project is implemented using Oracle SQL and PL/SQL.

## 2. Business Objectives

- Manage products and product categories.
- Maintain supplier information.
- Support multiple warehouses.
- Track stock quantities across warehouses.
- Manage purchase and sales orders.
- Prevent unauthorized or invalid stock deductions.
- Support inter-warehouse stock transfers.
- Calculate inventory value using the Weighted Average Cost method.
- Maintain a complete history of inventory movements.
- Generate analytical reports.

## 3. Main Business Entities

### Product Management
- Products
- Categories

### Supplier Management
- Suppliers

### Warehouse Management
- Warehouses
- Inventory

### Procurement Management
- Purchase Orders
- Purchase Order Items

### Sales Management
- Sales Orders
- Sales Order Items

### Inventory Operations
- Stock Movements
- Stock Transfers
- Stock Transfer Items

## 4. Business Rules

### 4.1 Product Management

- Each product must belong to a category.
- Each product must have a unique SKU.
- Product prices cannot be negative.
- Inactive products cannot be included in new orders.

### 4.2 Inventory Management

- Each warehouse maintains its own inventory records.
- A product can exist in multiple warehouses.
- Inventory quantity cannot become negative.
- Every stock-changing operation must be recorded in the stock_movements table.
- Reserved stock must be distinguished from available stock.

Available Stock = On Hand Quantity - Reserved Quantity

### 4.3 Procurement Management

- Purchase orders must be associated with suppliers.
- Purchase orders contain one or more order items.
- Only approved purchase orders can receive goods.
- Received quantities must not exceed the outstanding order quantities.
- Receiving goods increases warehouse inventory.
- Inventory valuation must use the Weighted Average Cost method.

### 4.4 Sales Management

- Sales orders contain one or more products.
- Stock must be checked before order confirmation.
- Confirming an order reserves the required stock.
- Order fulfillment decreases on-hand inventory and releases the corresponding reservation.
- Canceling an order releases its reserved stock.

### 4.5 Warehouse Transfers

- Transfers must have different source and destination warehouses.
- Stock must be available before a transfer is approved.
- Approved transfers reserve stock in the source warehouse.
- Dispatched transfers are marked as IN_TRANSIT.
- In-transit stock must not be counted as available stock in the destination warehouse.
- Inventory increases in the destination warehouse only after receipt confirmation.
- Every transfer must be traceable.

### 4.6 Inventory Valuation

The system uses the Weighted Average Cost method.

Weighted Average Cost = 
(Total Existing Inventory Value + New Purchase Value) /
(Total Existing Quantity + New Purchase Quantity)

Inventory value is recalculated when new goods are received.

## 5. Inventory Movement Types

- PURCHASE_RECEIPT
- SALES_FULFILLMENT
- TRANSFER_OUT
- TRANSFER_IN
- SALES_RETURN
- PURCHASE_RETURN
- STOCK_ADJUSTMENT

## 6. Order Statuses

### Purchase Orders
- DRAFT
- APPROVED
- PARTIALLY_RECEIVED
- RECEIVED
- CANCELLED

### Sales Orders
- DRAFT
- CONFIRMED
- FULFILLED
- CANCELLED

### Stock Transfers
- DRAFT
- APPROVED
- IN_TRANSIT
- RECEIVED
- CANCELLED

## 7. Technical Requirements

- Oracle SQL
- PL/SQL
- Relational database design
- Primary and foreign key constraints
- Database normalization (1NF, 2NF, 3NF)
- Indexing
- Views
- Stored procedures
- Functions
- Triggers
- Transactions
- Analytical SQL queries

## 8. Expected Outcomes

The final system will provide a structured and reliable database architecture capable of supporting inventory operations across multiple warehouses.

It will demonstrate practical knowledge of relational database design, SQL, PL/SQL programming, transaction management, and business-oriented database development.
