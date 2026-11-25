
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.2: SQL JOINS
-- ============================================


-- 1. INNER JOIN
-- Products with their category names

SELECT
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name
FROM products p
INNER JOIN categories c
    ON p.category_id = c.category_id;


-- 2. LEFT JOIN
-- All categories, including categories without products

SELECT
    c.category_name,
    p.product_name
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id;


-- 3. RIGHT JOIN
-- All products and their categories

SELECT
    p.product_name,
    c.category_name
FROM products p
RIGHT JOIN categories c
    ON p.category_id = c.category_id;


-- 4. FULL OUTER JOIN
-- All categories and products

SELECT
    c.category_name,
    p.product_name
FROM categories c
FULL OUTER JOIN products p
    ON c.category_id = p.category_id;


-- 5. MULTIPLE TABLE JOIN
-- Products, categories and inventory

SELECT
    p.product_name,
    c.category_name,
    w.warehouse_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_stock
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
JOIN inventory i
    ON p.product_id = i.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY p.product_name;


-- 6. PURCHASE ORDER DETAILS
-- Suppliers, purchase orders and warehouses

SELECT
    po.purchase_order_id,
    s.supplier_name,
    w.warehouse_name,
    po.order_date,
    po.status
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN warehouses w
    ON po.warehouse_id = w.warehouse_id;


-- 7. PURCHASE ORDER ITEMS
-- Purchase orders, products and suppliers

SELECT
    po.purchase_order_id,
    s.supplier_name,
    p.product_name,
    poi.quantity_ordered,
    poi.quantity_received,
    poi.unit_cost,
    poi.quantity_ordered * poi.unit_cost AS item_total
FROM purchase_order_items poi
JOIN purchase_orders po
    ON poi.purchase_order_id = po.purchase_order_id
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN products p
    ON poi.product_id = p.product_id;


-- 8. SALES ORDER DETAILS
-- Customers, orders and warehouses

SELECT
    so.sales_order_id,
    so.customer_name,
    w.warehouse_name,
    so.order_date,
    so.status
FROM sales_orders so
JOIN warehouses w
    ON so.warehouse_id = w.warehouse_id;


-- 9. SALES ORDER ITEMS
-- Sales orders and products

SELECT
    so.sales_order_id,
    so.customer_name,
    p.product_name,
    soi.quantity,
    soi.unit_price,
    soi.quantity * soi.unit_price AS item_total
FROM sales_order_items soi
JOIN sales_orders so
    ON soi.sales_order_id = so.sales_order_id
JOIN products p
    ON soi.product_id = p.product_id;


-- 10. LEFT JOIN WITH NULL
-- Products that have no inventory record

SELECT
    p.product_id,
    p.product_name,
    p.sku
FROM products p
LEFT JOIN inventory i
    ON p.product_id = i.product_id
WHERE i.inventory_id IS NULL;


-- 11. SELF JOIN
-- Compare products within the same category

SELECT
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    p1.category_id
FROM products p1
JOIN products p2
    ON p1.category_id = p2.category_id
WHERE p1.product_id < p2.product_id;


-- 12. STOCK TRANSFER DETAILS
-- Source and destination warehouses

SELECT
    st.transfer_id,
    source_w.warehouse_name AS source_warehouse,
    destination_w.warehouse_name AS destination_warehouse,
    st.transfer_date,
    st.status
FROM stock_transfers st
JOIN warehouses source_w
    ON st.source_warehouse_id = source_w.warehouse_id
JOIN warehouses destination_w
    ON st.destination_warehouse_id = destination_w.warehouse_id;


-- 13. STOCK TRANSFER ITEMS
-- Transfer details with product information

SELECT
    st.transfer_id,
    p.product_name,
    sti.quantity,
    sti.quantity_received,
    st.status
FROM stock_transfers st
JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id
JOIN products p
    ON sti.product_id = p.product_id;


-- 14. INVENTORY VALUE
-- Calculate stock value for each product and warehouse

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    i.average_unit_cost,
    i.quantity_on_hand * i.average_unit_cost AS stock_value
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY stock_value DESC;


-- 15. CUSTOMERS AND THEIR ORDER TOTALS

SELECT
    so.sales_order_id,
    so.customer_name,
    SUM(soi.quantity * soi.unit_price) AS order_total
FROM sales_orders so
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY
    so.sales_order_id,
    so.customer_name
ORDER BY order_total DESC;
