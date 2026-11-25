
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.5: WINDOW FUNCTIONS
-- ============================================


-- 1. ROW_NUMBER
-- Number products by selling price

SELECT
    product_name,
    selling_price,
    ROW_NUMBER() OVER (
        ORDER BY selling_price DESC
    ) AS row_num
FROM products;


-- 2. RANK
-- Rank products by selling price

SELECT
    product_name,
    selling_price,
    RANK() OVER (
        ORDER BY selling_price DESC
    ) AS price_rank
FROM products;


-- 3. DENSE_RANK
-- Rank products without skipping ranking numbers

SELECT
    product_name,
    selling_price,
    DENSE_RANK() OVER (
        ORDER BY selling_price DESC
    ) AS dense_price_rank
FROM products;


-- 4. PARTITION BY
-- Rank products within each category

SELECT
    p.product_name,
    c.category_name,
    p.selling_price,
    RANK() OVER (
        PARTITION BY p.category_id
        ORDER BY p.selling_price DESC
    ) AS category_rank
FROM products p
JOIN categories c
    ON p.category_id = c.category_id;


-- 5. ROW_NUMBER BY WAREHOUSE
-- Rank inventory records within each warehouse

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    ROW_NUMBER() OVER (
        PARTITION BY i.warehouse_id
        ORDER BY i.quantity_on_hand DESC
    ) AS stock_rank
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id;


-- 6. LAG
-- Compare current product price with previous product price

SELECT
    product_name,
    selling_price,
    LAG(selling_price) OVER (
        ORDER BY selling_price
    ) AS previous_price
FROM products;


-- 7. LEAD
-- Compare current product price with next product price

SELECT
    product_name,
    selling_price,
    LEAD(selling_price) OVER (
        ORDER BY selling_price
    ) AS next_price
FROM products;


-- 8. PRICE DIFFERENCE
-- Difference between current and previous product price

SELECT
    product_name,
    selling_price,
    selling_price - LAG(selling_price) OVER (
        ORDER BY selling_price
    ) AS price_difference
FROM products;


-- 9. FIRST_VALUE
-- Cheapest product in each category

SELECT
    product_name,
    category_id,
    selling_price,
    FIRST_VALUE(product_name) OVER (
        PARTITION BY category_id
        ORDER BY selling_price ASC
    ) AS cheapest_product
FROM products;


-- 10. LAST_VALUE
-- Most expensive product in each category

SELECT
    product_name,
    category_id,
    selling_price,
    LAST_VALUE(product_name) OVER (
        PARTITION BY category_id
        ORDER BY selling_price ASC
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND UNBOUNDED FOLLOWING
    ) AS most_expensive_product
FROM products;


-- 11. RUNNING TOTAL
-- Calculate cumulative sales value by order

SELECT
    sales_order_id,
    SUM(quantity * unit_price) AS order_value,
    SUM(SUM(quantity * unit_price)) OVER (
        ORDER BY sales_order_id
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_sales_total
FROM sales_order_items
GROUP BY sales_order_id;


-- 12. RUNNING TOTAL BY CUSTOMER
-- Calculate cumulative order value per customer

SELECT
    so.customer_name,
    so.sales_order_id,
    SUM(soi.quantity * soi.unit_price) AS order_value,
    SUM(SUM(soi.quantity * soi.unit_price)) OVER (
        PARTITION BY so.customer_name
        ORDER BY so.sales_order_id
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS customer_running_total
FROM sales_orders so
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY
    so.customer_name,
    so.sales_order_id;


-- 13. MOVING AVERAGE
-- Calculate moving average of product prices

SELECT
    product_name,
    selling_price,
    ROUND(
        AVG(selling_price) OVER (
            ORDER BY product_id
            ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS moving_average_price
FROM products;


-- 14. PERCENT_RANK
-- Calculate relative price position

SELECT
    product_name,
    selling_price,
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY selling_price
        ),
        4
    ) AS price_percent_rank
FROM products;


-- 15. CUME_DIST
-- Calculate cumulative distribution of product prices

SELECT
    product_name,
    selling_price,
    ROUND(
        CUME_DIST() OVER (
            ORDER BY selling_price
        ),
        4
    ) AS cumulative_distribution
FROM products;


-- 16. NTILE
-- Divide products into four price groups

SELECT
    product_name,
    selling_price,
    NTILE(4) OVER (
        ORDER BY selling_price
    ) AS price_group
FROM products;


-- 17. COUNT OVER
-- Count products in each category

SELECT
    product_name,
    category_id,
    COUNT(*) OVER (
        PARTITION BY category_id
    ) AS category_product_count
FROM products;


-- 18. SUM OVER
-- Calculate total stock per warehouse without grouping rows

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    SUM(i.quantity_on_hand) OVER (
        PARTITION BY i.warehouse_id
    ) AS warehouse_total_stock
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id;


-- 19. AVG OVER
-- Compare each product with warehouse average stock

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    ROUND(
        AVG(i.quantity_on_hand) OVER (
            PARTITION BY i.warehouse_id
        ),
        2
    ) AS warehouse_average_stock
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id;


-- 20. TOP 3 PRODUCTS PER CATEGORY

SELECT
    category_name,
    product_name,
    selling_price,
    price_rank
FROM (
    SELECT
        c.category_name,
        p.product_name,
        p.selling_price,
        ROW_NUMBER() OVER (
            PARTITION BY p.category_id
            ORDER BY p.selling_price DESC
        ) AS price_rank
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
)
WHERE price_rank <= 3;


-- 21. TOP PRODUCT PER WAREHOUSE

SELECT
    warehouse_name,
    product_name,
    quantity_on_hand
FROM (
    SELECT
        w.warehouse_name,
        p.product_name,
        i.quantity_on_hand,
        ROW_NUMBER() OVER (
            PARTITION BY i.warehouse_id
            ORDER BY i.quantity_on_hand DESC
        ) AS stock_rank
    FROM inventory i
    JOIN warehouses w
        ON i.warehouse_id = w.warehouse_id
    JOIN products p
        ON i.product_id = p.product_id
)
WHERE stock_rank = 1;


-- 22. SALES ORDER RANKING

SELECT
    so.sales_order_id,
    so.customer_name,
    SUM(soi.quantity * soi.unit_price) AS order_value,
    DENSE_RANK() OVER (
        ORDER BY SUM(soi.quantity * soi.unit_price) DESC
    ) AS sales_rank
FROM sales_orders so
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY
    so.sales_order_id,
    so.customer_name;


-- 23. PRODUCT STOCK SHARE
-- Calculate percentage contribution to total stock

SELECT
    p.product_name,
    SUM(i.quantity_on_hand) AS total_stock,
    ROUND(
        SUM(i.quantity_on_hand) * 100 /
        SUM(SUM(i.quantity_on_hand)) OVER (),
        2
    ) AS stock_percentage
FROM products p
JOIN inventory i
    ON p.product_id = i.product_id
GROUP BY p.product_name
ORDER BY stock_percentage DESC;


-- 24. WAREHOUSE INVENTORY VALUE RANKING

SELECT
    warehouse_name,
    inventory_value,
    RANK() OVER (
        ORDER BY inventory_value DESC
    ) AS value_rank
FROM (
    SELECT
        w.warehouse_name,
        SUM(i.quantity_on_hand * i.average_unit_cost)
            AS inventory_value
    FROM warehouses w
    JOIN inventory i
        ON w.warehouse_id = i.warehouse_id
    GROUP BY w.warehouse_name
);


-- 25. SALES CONTRIBUTION BY CUSTOMER

SELECT
    customer_name,
    total_spending,
    ROUND(
        total_spending * 100 /
        SUM(total_spending) OVER (),
        2
    ) AS sales_contribution_percentage
FROM (
    SELECT
        so.customer_name,
        SUM(soi.quantity * soi.unit_price) AS total_spending
    FROM sales_orders so
    JOIN sales_order_items soi
        ON so.sales_order_id = soi.sales_order_id
    GROUP BY so.customer_name
);
