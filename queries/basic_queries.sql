
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.1: BASIC SQL QUERIES
-- ============================================


-- 1. DISPLAY ALL PRODUCTS

SELECT *
FROM products;


-- 2. DISPLAY SPECIFIC COLUMNS

SELECT
    product_id,
    sku,
    product_name,
    selling_price
FROM products;


-- 3. DISTINCT: DISPLAY UNIQUE PRODUCT CATEGORIES

SELECT DISTINCT category_id
FROM products;


-- 4. WHERE: PRODUCTS WITH PRICE ABOVE 100

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price > 100;


-- 5. AND: PRODUCTS WITH PRICE ABOVE 100
-- AND ACTIVE STATUS

SELECT
    product_name,
    selling_price,
    is_active
FROM products
WHERE selling_price > 100
AND is_active = 'Y';


-- 6. OR: PRODUCTS FROM SPECIFIC CATEGORIES

SELECT
    product_name,
    category_id
FROM products
WHERE category_id = 1
OR category_id = 2;


-- 7. IN: PRODUCTS FROM MULTIPLE CATEGORIES

SELECT
    product_name,
    category_id
FROM products
WHERE category_id IN (1, 2, 3);


-- 8. BETWEEN: PRODUCTS WITH PRICE RANGE

SELECT
    product_name,
    selling_price
FROM products
WHERE selling_price BETWEEN 50 AND 300;


-- 9. LIKE: SEARCH PRODUCTS BY NAME

SELECT
    product_name
FROM products
WHERE product_name LIKE '%Laptop%';


-- 10. ORDER BY: SORT PRODUCTS BY PRICE

SELECT
    product_name,
    selling_price
FROM products
ORDER BY selling_price DESC;


-- 11. FETCH FIRST: TOP 5 MOST EXPENSIVE PRODUCTS

SELECT
    product_name,
    selling_price
FROM products
ORDER BY selling_price DESC
FETCH FIRST 5 ROWS ONLY;


-- 12. COUNT: TOTAL NUMBER OF PRODUCTS

SELECT COUNT(*) AS total_products
FROM products;


-- 13. AVG: AVERAGE PRODUCT SELLING PRICE

SELECT
    ROUND(AVG(selling_price), 2) AS average_price
FROM products;


-- 14. MIN AND MAX: PRICE ANALYSIS

SELECT
    MIN(selling_price) AS minimum_price,
    MAX(selling_price) AS maximum_price
FROM products;


-- 15. SUM: TOTAL INVENTORY QUANTITY

SELECT
    SUM(quantity_on_hand) AS total_stock
FROM inventory;


-- 16. GROUP BY: PRODUCTS PER CATEGORY

SELECT
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY product_count DESC;


-- 17. GROUP BY: TOTAL STOCK PER WAREHOUSE

SELECT
    w.warehouse_name,
    SUM(i.quantity_on_hand) AS total_stock
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_name
ORDER BY total_stock DESC;


-- 18. HAVING: CATEGORIES WITH MORE THAN ONE PRODUCT

SELECT
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
GROUP BY c.category_name
HAVING COUNT(p.product_id) > 1;


-- 19. AVAILABLE STOCK

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_stock
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id
ORDER BY available_stock DESC;


-- 20. LOW STOCK PRODUCTS

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_stock,
    p.reorder_level
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand - i.quantity_reserved <= p.reorder_level
ORDER BY available_stock ASC;


-- 21. TOTAL SALES ORDER ITEMS VALUE

SELECT
    SUM(quantity * unit_price) AS total_sales_value
FROM sales_order_items;


-- 22. PURCHASE ORDER VALUE

SELECT
    SUM(quantity_ordered * unit_cost) AS total_purchase_value
FROM purchase_order_items;


-- 23. COUNT ORDERS BY STATUS

SELECT
    status,
    COUNT(*) AS order_count
FROM sales_orders
GROUP BY status
ORDER BY order_count DESC;


-- 24. PRODUCTS THAT ARE NOT ACTIVE

SELECT
    sku,
    product_name,
    selling_price
FROM products
WHERE is_active = 'N';


-- 25. STOCK VALUATION PER WAREHOUSE

SELECT
    w.warehouse_name,
    SUM(i.quantity_on_hand * i.average_unit_cost) AS inventory_value
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name
ORDER BY inventory_value DESC;
