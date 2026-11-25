-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 6.2: PL/SQL FUNCTIONS
-- ============================================================


-- 1. GET AVAILABLE STOCK FOR A PRODUCT IN A WAREHOUSE
CREATE OR REPLACE FUNCTION get_available_stock (
    p_product_id IN NUMBER,
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_available_stock NUMBER;
BEGIN
    SELECT NVL(quantity_on_hand - quantity_reserved, 0)
    INTO v_available_stock
    FROM inventory
    WHERE product_id = p_product_id
      AND warehouse_id = p_warehouse_id;

    RETURN v_available_stock;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/


-- 2. GET TOTAL STOCK ACROSS ALL WAREHOUSES
CREATE OR REPLACE FUNCTION get_total_stock (
    p_product_id IN NUMBER
)
RETURN NUMBER
AS
    v_total_stock NUMBER;
BEGIN
    SELECT NVL(SUM(quantity_on_hand), 0)
    INTO v_total_stock
    FROM inventory
    WHERE product_id = p_product_id;

    RETURN v_total_stock;
END;
/


-- 3. GET TOTAL AVAILABLE STOCK ACROSS ALL WAREHOUSES
CREATE OR REPLACE FUNCTION get_total_available_stock (
    p_product_id IN NUMBER
)
RETURN NUMBER
AS
    v_available_stock NUMBER;
BEGIN
    SELECT NVL(SUM(quantity_on_hand - quantity_reserved), 0)
    INTO v_available_stock
    FROM inventory
    WHERE product_id = p_product_id;

    RETURN v_available_stock;
END;
/


-- 4. CALCULATE INVENTORY VALUE IN A WAREHOUSE
CREATE OR REPLACE FUNCTION get_warehouse_inventory_value (
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_inventory_value NUMBER;
BEGIN
    SELECT NVL(
        SUM(i.quantity_on_hand * i.average_unit_cost),
        0
    )
    INTO v_inventory_value
    FROM inventory i
    WHERE i.warehouse_id = p_warehouse_id;

    RETURN v_inventory_value;
END;
/


-- 5. CALCULATE TOTAL INVENTORY VALUE
CREATE OR REPLACE FUNCTION get_total_inventory_value
RETURN NUMBER
AS
    v_total_value NUMBER;
BEGIN
    SELECT NVL(
        SUM(quantity_on_hand * average_unit_cost),
        0
    )
    INTO v_total_value
    FROM inventory;

    RETURN v_total_value;
END;
/


-- 6. CALCULATE SALES ORDER TOTAL
CREATE OR REPLACE FUNCTION get_sales_order_total (
    p_sales_order_id IN NUMBER
)
RETURN NUMBER
AS
    v_order_total NUMBER;
BEGIN
    SELECT NVL(
        SUM(quantity * unit_price),
        0
    )
    INTO v_order_total
    FROM sales_order_items
    WHERE sales_order_id = p_sales_order_id;

    RETURN v_order_total;
END;
/


-- 7. CALCULATE PURCHASE ORDER TOTAL
CREATE OR REPLACE FUNCTION get_purchase_order_total (
    p_purchase_order_id IN NUMBER
)
RETURN NUMBER
AS
    v_order_total NUMBER;
BEGIN
    SELECT NVL(
        SUM(quantity_ordered * unit_cost),
        0
    )
    INTO v_order_total
    FROM purchase_order_items
    WHERE purchase_order_id = p_purchase_order_id;

    RETURN v_order_total;
END;
/


-- 8. CALCULATE OUTSTANDING PURCHASE QUANTITY
CREATE OR REPLACE FUNCTION get_outstanding_purchase_quantity (
    p_purchase_order_id IN NUMBER
)
RETURN NUMBER
AS
    v_outstanding_quantity NUMBER;
BEGIN
    SELECT NVL(
        SUM(quantity_ordered - quantity_received),
        0
    )
    INTO v_outstanding_quantity
    FROM purchase_order_items
    WHERE purchase_order_id = p_purchase_order_id;

    RETURN v_outstanding_quantity;
END;
/


-- 9. CALCULATE SALES ORDER ITEM COUNT
CREATE OR REPLACE FUNCTION get_sales_order_item_count (
    p_sales_order_id IN NUMBER
)
RETURN NUMBER
AS
    v_item_count NUMBER;
BEGIN
    SELECT NVL(SUM(quantity), 0)
    INTO v_item_count
    FROM sales_order_items
    WHERE sales_order_id = p_sales_order_id;

    RETURN v_item_count;
END;
/


-- 10. CALCULATE PRODUCT REORDER QUANTITY
CREATE OR REPLACE FUNCTION get_reorder_quantity (
    p_product_id IN NUMBER,
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_reorder_quantity NUMBER;
BEGIN
    SELECT GREATEST(
        p.reorder_level - (i.quantity_on_hand - i.quantity_reserved),
        0
    )
    INTO v_reorder_quantity
    FROM products p
    JOIN inventory i
        ON p.product_id = i.product_id
    WHERE p.product_id = p_product_id
      AND i.warehouse_id = p_warehouse_id;

    RETURN v_reorder_quantity;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/


-- 11. GET PRODUCT AVERAGE UNIT COST IN A WAREHOUSE
CREATE OR REPLACE FUNCTION get_product_average_cost (
    p_product_id IN NUMBER,
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_average_cost NUMBER;
BEGIN
    SELECT average_unit_cost
    INTO v_average_cost
    FROM inventory
    WHERE product_id = p_product_id
      AND warehouse_id = p_warehouse_id;

    RETURN v_average_cost;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/


-- 12. GET TOTAL NUMBER OF PRODUCTS IN A WAREHOUSE
CREATE OR REPLACE FUNCTION get_warehouse_product_count (
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_product_count NUMBER;
BEGIN
    SELECT COUNT(DISTINCT product_id)
    INTO v_product_count
    FROM inventory
    WHERE warehouse_id = p_warehouse_id;

    RETURN v_product_count;
END;
/


-- 13. GET TOTAL RESERVED STOCK IN A WAREHOUSE
CREATE OR REPLACE FUNCTION get_warehouse_reserved_stock (
    p_warehouse_id IN NUMBER
)
RETURN NUMBER
AS
    v_reserved_stock NUMBER;
BEGIN
    SELECT NVL(SUM(quantity_reserved), 0)
    INTO v_reserved_stock
    FROM inventory
    WHERE warehouse_id = p_warehouse_id;

    RETURN v_reserved_stock;
END;
/


-- 14. GET TOTAL SALES REVENUE
CREATE OR REPLACE FUNCTION get_total_sales_revenue
RETURN NUMBER
AS
    v_total_revenue NUMBER;
BEGIN
    SELECT NVL(
        SUM(soi.quantity * soi.unit_price),
        0
    )
    INTO v_total_revenue
    FROM sales_order_items soi
    JOIN sales_orders so
        ON soi.sales_order_id = so.sales_order_id
    WHERE so.status IN ('CONFIRMED', 'FULFILLED');

    RETURN v_total_revenue;
END;
/


-- 15. GET TOTAL PURCHASE SPENDING
CREATE OR REPLACE FUNCTION get_total_purchase_spending
RETURN NUMBER
AS
    v_total_spending NUMBER;
BEGIN
    SELECT NVL(
        SUM(poi.quantity_received * poi.unit_cost),
        0
    )
    INTO v_total_spending
    FROM purchase_order_items poi
    JOIN purchase_orders po
        ON poi.purchase_order_id = po.purchase_order_id
    WHERE po.status <> 'CANCELLED';

    RETURN v_total_spending;
END;
/


-- ============================================================
-- FUNCTION TEST QUERIES
-- ============================================================

SELECT get_available_stock(1, 1) AS available_stock
FROM dual;

SELECT get_total_stock(1) AS total_stock
FROM dual;

SELECT get_total_available_stock(1) AS total_available_stock
FROM dual;

SELECT get_warehouse_inventory_value(1) AS warehouse_value
FROM dual;

SELECT get_total_inventory_value() AS total_inventory_value
FROM dual;

SELECT get_sales_order_total(1) AS sales_order_total
FROM dual;

SELECT get_purchase_order_total(1) AS purchase_order_total
FROM dual;

SELECT get_outstanding_purchase_quantity(1) AS outstanding_quantity
FROM dual;

SELECT get_sales_order_item_count(1) AS total_ordered_units
FROM dual;

SELECT get_reorder_quantity(1, 1) AS reorder_quantity
FROM dual;

SELECT get_product_average_cost(1, 1) AS average_cost
FROM dual;

SELECT get_warehouse_product_count(1) AS product_count
FROM dual;

SELECT get_warehouse_reserved_stock(1) AS reserved_stock
FROM dual;

SELECT get_total_sales_revenue() AS total_sales_revenue
FROM dual;

SELECT get_total_purchase_spending() AS total_purchase_spending
FROM dual;