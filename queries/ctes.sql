
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.4: COMMON TABLE EXPRESSIONS
-- ============================================


-- 1. BASIC CTE
-- Calculate total stock in each warehouse

WITH warehouse_stock AS (
    SELECT
        warehouse_id,
        SUM(quantity_on_hand) AS total_stock
    FROM inventory
    GROUP BY warehouse_id
)
SELECT
    w.warehouse_name,
    ws.total_stock
FROM warehouse_stock ws
JOIN warehouses w
    ON ws.warehouse_id = w.warehouse_id;


-- 2. CTE WITH FILTERING
-- Products with selling price above 100

WITH expensive_products AS (
    SELECT
        product_id,
        product_name,
        selling_price
    FROM products
    WHERE selling_price > 100
)
SELECT *
FROM expensive_products
ORDER BY selling_price DESC;


-- 3. MULTIPLE CTEs
-- Calculate inventory value per warehouse

WITH stock_value AS (
    SELECT
        warehouse_id,
        SUM(quantity_on_hand * average_unit_cost) AS total_value
    FROM inventory
    GROUP BY warehouse_id
),
warehouse_details AS (
    SELECT
        warehouse_id,
        warehouse_name,
        location
    FROM warehouses
)
SELECT
    wd.warehouse_name,
    wd.location,
    sv.total_value
FROM stock_value sv
JOIN warehouse_details wd
    ON sv.warehouse_id = wd.warehouse_id
ORDER BY sv.total_value DESC;


-- 4. CTE WITH GROUP BY AND HAVING
-- Categories with more than one product

WITH category_summary AS (
    SELECT
        category_id,
        COUNT(*) AS product_count,
        AVG(selling_price) AS average_price
    FROM products
    GROUP BY category_id
)
SELECT
    c.category_name,
    cs.product_count,
    ROUND(cs.average_price, 2) AS average_price
FROM category_summary cs
JOIN categories c
    ON cs.category_id = c.category_id
WHERE cs.product_count > 1;


-- 5. CTE FOR SALES ANALYSIS
-- Calculate total value of each sales order

WITH sales_summary AS (
    SELECT
        sales_order_id,
        SUM(quantity * unit_price) AS order_total
    FROM sales_order_items
    GROUP BY sales_order_id
)
SELECT
    so.sales_order_id,
    so.customer_name,
    so.status,
    ss.order_total
FROM sales_summary ss
JOIN sales_orders so
    ON ss.sales_order_id = so.sales_order_id
ORDER BY ss.order_total DESC;


-- 6. CTE FOR PURCHASE ANALYSIS
-- Calculate total purchase value per supplier

WITH supplier_purchases AS (
    SELECT
        po.supplier_id,
        SUM(poi.quantity_ordered * poi.unit_cost) AS purchase_value
    FROM purchase_orders po
    JOIN purchase_order_items poi
        ON po.purchase_order_id = poi.purchase_order_id
    GROUP BY po.supplier_id
)
SELECT
    s.supplier_name,
    NVL(sp.purchase_value, 0) AS purchase_value
FROM suppliers s
LEFT JOIN supplier_purchases sp
    ON s.supplier_id = sp.supplier_id
ORDER BY purchase_value DESC;


-- 7. MULTIPLE CTEs WITH JOINS
-- Calculate available stock and identify low-stock items

WITH available_inventory AS (
    SELECT
        inventory_id,
        product_id,
        warehouse_id,
        quantity_on_hand - quantity_reserved AS available_stock
    FROM inventory
),
stock_analysis AS (
    SELECT
        ai.product_id,
        ai.warehouse_id,
        ai.available_stock,
        p.reorder_level
    FROM available_inventory ai
    JOIN products p
        ON ai.product_id = p.product_id
)
SELECT
    p.product_name,
    w.warehouse_name,
    sa.available_stock,
    sa.reorder_level
FROM stock_analysis sa
JOIN products p
    ON sa.product_id = p.product_id
JOIN warehouses w
    ON sa.warehouse_id = w.warehouse_id
WHERE sa.available_stock <= sa.reorder_level
ORDER BY sa.available_stock;


-- 8. CTE WITH RANKING
-- Rank warehouses by total inventory value

WITH warehouse_values AS (
    SELECT
        w.warehouse_id,
        w.warehouse_name,
        SUM(i.quantity_on_hand * i.average_unit_cost) AS total_value
    FROM warehouses w
    JOIN inventory i
        ON w.warehouse_id = i.warehouse_id
    GROUP BY w.warehouse_id, w.warehouse_name
)
SELECT
    warehouse_name,
    total_value,
    RANK() OVER (ORDER BY total_value DESC) AS warehouse_rank
FROM warehouse_values;


-- 9. CTE FOR PRODUCT PERFORMANCE
-- Compare each product's price with overall average

WITH price_analysis AS (
    SELECT
        product_id,
        product_name,
        selling_price,
        AVG(selling_price) OVER () AS overall_avg_price
    FROM products
)
SELECT
    product_name,
    selling_price,
    ROUND(overall_avg_price, 2) AS overall_avg_price,
    CASE
        WHEN selling_price > overall_avg_price THEN 'ABOVE AVERAGE'
        WHEN selling_price < overall_avg_price THEN 'BELOW AVERAGE'
        ELSE 'AVERAGE'
    END AS price_category
FROM price_analysis;


-- 10. CTE FOR ORDER STATUS ANALYSIS
-- Count orders by status

WITH order_counts AS (
    SELECT
        status,
        COUNT(*) AS total_orders
    FROM sales_orders
    GROUP BY status
)
SELECT
    status,
    total_orders,
    ROUND(
        total_orders * 100.0 /
        SUM(total_orders) OVER (),
        2
    ) AS percentage
FROM order_counts
ORDER BY total_orders DESC;


-- 11. CTE FOR STOCK MOVEMENT ANALYSIS
-- Total quantity moved by movement type

WITH movement_summary AS (
    SELECT
        movement_type,
        COUNT(*) AS movement_count,
        SUM(quantity) AS total_quantity
    FROM stock_movements
    GROUP BY movement_type
)
SELECT
    movement_type,
    movement_count,
    total_quantity
FROM movement_summary
ORDER BY total_quantity DESC;


-- 12. CTE FOR SUPPLIER PERFORMANCE
-- Calculate ordered and received quantities

WITH supplier_performance AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        SUM(poi.quantity_ordered) AS total_ordered,
        SUM(poi.quantity_received) AS total_received
    FROM suppliers s
    JOIN purchase_orders po
        ON s.supplier_id = po.supplier_id
    JOIN purchase_order_items poi
        ON po.purchase_order_id = poi.purchase_order_id
    GROUP BY s.supplier_id, s.supplier_name
)
SELECT
    supplier_name,
    total_ordered,
    total_received,
    ROUND(
        total_received * 100.0 / NULLIF(total_ordered, 0),
        2
    ) AS fulfillment_percentage
FROM supplier_performance
ORDER BY fulfillment_percentage DESC;


-- 13. CTE FOR MULTI-WAREHOUSE PRODUCT AVAILABILITY
-- Total available stock of each product across all warehouses

WITH product_stock AS (
    SELECT
        product_id,
        SUM(quantity_on_hand - quantity_reserved) AS total_available
    FROM inventory
    GROUP BY product_id
)
SELECT
    p.product_name,
    NVL(ps.total_available, 0) AS total_available
FROM products p
LEFT JOIN product_stock ps
    ON p.product_id = ps.product_id
ORDER BY total_available DESC;


-- 14. CTE FOR CUSTOMER SALES
-- Calculate total spending per customer

WITH customer_spending AS (
    SELECT
        so.customer_name,
        SUM(soi.quantity * soi.unit_price) AS total_spending
    FROM sales_orders so
    JOIN sales_order_items soi
        ON so.sales_order_id = soi.sales_order_id
    GROUP BY so.customer_name
)
SELECT
    customer_name,
    total_spending,
    DENSE_RANK() OVER (
        ORDER BY total_spending DESC
    ) AS spending_rank
FROM customer_spending;


-- 15. CTE FOR REORDER ANALYSIS
-- Find products requiring replenishment

WITH stock_levels AS (
    SELECT
        i.product_id,
        i.warehouse_id,
        i.quantity_on_hand - i.quantity_reserved AS available_stock
    FROM inventory i
)
SELECT
    p.sku,
    p.product_name,
    w.warehouse_name,
    sl.available_stock,
    p.reorder_level
FROM stock_levels sl
JOIN products p
    ON sl.product_id = p.product_id
JOIN warehouses w
    ON sl.warehouse_id = w.warehouse_id
WHERE sl.available_stock <= p.reorder_level
AND p.is_active = 'Y';
