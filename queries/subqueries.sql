
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.3: SQL SUBQUERIES
-- ============================================


-- 1. SINGLE-ROW SUBQUERY
-- Products with price above average price

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price > (
    SELECT AVG(selling_price)
    FROM products
);


-- 2. PRODUCTS WITH MAXIMUM SELLING PRICE

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price = (
    SELECT MAX(selling_price)
    FROM products
);


-- 3. PRODUCTS WITH MINIMUM SELLING PRICE

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price = (
    SELECT MIN(selling_price)
    FROM products
);


-- 4. MULTIPLE-ROW SUBQUERY WITH IN
-- Products belonging to categories with more than one product

SELECT
    product_name,
    category_id
FROM products
WHERE category_id IN (
    SELECT category_id
    FROM products
    GROUP BY category_id
    HAVING COUNT(*) > 1
);


-- 5. NOT IN
-- Products that have never appeared in a sales order

SELECT
    product_id,
    product_name
FROM products
WHERE product_id NOT IN (
    SELECT product_id
    FROM sales_order_items
);


-- 6. EXISTS
-- Suppliers that have at least one purchase order

SELECT
    supplier_id,
    supplier_name
FROM suppliers s
WHERE EXISTS (
    SELECT 1
    FROM purchase_orders po
    WHERE po.supplier_id = s.supplier_id
);


-- 7. NOT EXISTS
-- Suppliers without purchase orders

SELECT
    supplier_id,
    supplier_name
FROM suppliers s
WHERE NOT EXISTS (
    SELECT 1
    FROM purchase_orders po
    WHERE po.supplier_id = s.supplier_id
);


-- 8. CORRELATED SUBQUERY
-- Products whose price is above their category average

SELECT
    p.product_name,
    p.selling_price,
    p.category_id
FROM products p
WHERE p.selling_price > (
    SELECT AVG(p2.selling_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
);


-- 9. CORRELATED SUBQUERY
-- Warehouses with inventory above the average inventory quantity
-- across warehouse-product records

SELECT
    w.warehouse_name
FROM warehouses w
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.warehouse_id = w.warehouse_id
    AND i.quantity_on_hand > (
        SELECT AVG(quantity_on_hand)
        FROM inventory
    )
);


-- 10. ANY
-- Products more expensive than at least one product in category 2

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price > ANY (
    SELECT selling_price
    FROM products
    WHERE category_id = 2
);


-- 11. ALL
-- Products more expensive than every product in category 2

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price > ALL (
    SELECT selling_price
    FROM products
    WHERE category_id = 2
);


-- 12. NESTED SUBQUERY
-- Products belonging to the category with the highest average price

SELECT
    product_name,
    selling_price,
    category_id
FROM products
WHERE category_id = (
    SELECT category_id
    FROM (
        SELECT
            category_id,
            AVG(selling_price) AS avg_price
        FROM products
        GROUP BY category_id
        ORDER BY avg_price DESC
    )
    WHERE ROWNUM = 1
);


-- 13. SUBQUERY IN SELECT
-- Show each product with its category's average price

SELECT
    p.product_name,
    p.selling_price,
    (
        SELECT ROUND(AVG(p2.selling_price), 2)
        FROM products p2
        WHERE p2.category_id = p.category_id
    ) AS category_avg_price
FROM products p;


-- 14. SUBQUERY IN FROM
-- Average selling price by category

SELECT
    category_id,
    average_price
FROM (
    SELECT
        category_id,
        AVG(selling_price) AS average_price
    FROM products
    GROUP BY category_id
)
WHERE average_price > 100;


-- 15. SALES ORDERS ABOVE AVERAGE ORDER VALUE

SELECT
    so.sales_order_id,
    so.customer_name,
    (
        SELECT SUM(soi.quantity * soi.unit_price)
        FROM sales_order_items soi
        WHERE soi.sales_order_id = so.sales_order_id
    ) AS order_total
FROM sales_orders so
WHERE (
    SELECT SUM(soi.quantity * soi.unit_price)
    FROM sales_order_items soi
    WHERE soi.sales_order_id = so.sales_order_id
) > (
    SELECT AVG(order_total)
    FROM (
        SELECT
            SUM(quantity * unit_price) AS order_total
        FROM sales_order_items
        GROUP BY sales_order_id
    )
);


-- 16. PRODUCTS WITH STOCK BELOW AVERAGE

SELECT
    p.product_name,
    i.quantity_on_hand,
    w.warehouse_name
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand < (
    SELECT AVG(quantity_on_hand)
    FROM inventory
);


-- 17. PURCHASE ORDERS WITH ABOVE-AVERAGE VALUE

SELECT
    po.purchase_order_id,
    po.status
FROM purchase_orders po
WHERE (
    SELECT SUM(poi.quantity_ordered * poi.unit_cost)
    FROM purchase_order_items poi
    WHERE poi.purchase_order_id = po.purchase_order_id
) > (
    SELECT AVG(order_value)
    FROM (
        SELECT
            SUM(quantity_ordered * unit_cost) AS order_value
        FROM purchase_order_items
        GROUP BY purchase_order_id
    )
);


-- 18. WAREHOUSES THAT CONTAIN LAPTOPS

SELECT
    warehouse_name
FROM warehouses w
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    JOIN products p
        ON i.product_id = p.product_id
    WHERE i.warehouse_id = w.warehouse_id
    AND p.product_name = 'Laptop'
);
