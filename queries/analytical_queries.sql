-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 5.6: ANALYTICAL QUERIES
-- ============================================================


-- 1. Total inventory value by warehouse
SELECT
    w.warehouse_name,
    SUM(i.quantity_on_hand * p.unit_price) AS total_inventory_value
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
JOIN products p
    ON i.product_id = p.product_id
GROUP BY w.warehouse_name
ORDER BY total_inventory_value DESC;


-- 2. Inventory value by product category
SELECT
    c.category_name,
    SUM(i.quantity_on_hand * p.unit_price) AS category_inventory_value
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
JOIN inventory i
    ON p.product_id = i.product_id
GROUP BY c.category_name
ORDER BY category_inventory_value DESC;


-- 3. Total stock, reserved stock and available stock
SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_quantity
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY w.warehouse_name, p.product_name;


-- 4. Products with insufficient available stock
SELECT
    p.product_name,
    w.warehouse_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_quantity,
    p.reorder_level
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand - i.quantity_reserved < p.reorder_level
ORDER BY available_quantity;


-- 5. Products requiring replenishment by warehouse
SELECT
    w.warehouse_name,
    p.product_name,
    p.reorder_level,
    i.quantity_on_hand,
    GREATEST(
        p.reorder_level - (i.quantity_on_hand - i.quantity_reserved),
        0
    ) AS recommended_reorder_quantity
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand - i.quantity_reserved < p.reorder_level
ORDER BY recommended_reorder_quantity DESC;


-- 6. Purchase spending by supplier
SELECT
    s.supplier_name,
    COUNT(DISTINCT po.purchase_order_id) AS total_orders,
    SUM(poi.quantity_ordered * poi.unit_cost) AS total_purchase_value
FROM suppliers s
JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY s.supplier_name
ORDER BY total_purchase_value DESC;


-- 7. Purchase order value and receipt progress
SELECT
    po.purchase_order_id,
    s.supplier_name,
    po.status,
    SUM(poi.quantity_ordered * poi.unit_cost) AS ordered_value,
    SUM(poi.quantity_received * poi.unit_cost) AS received_value,
    ROUND(
        SUM(poi.quantity_received) /
        NULLIF(SUM(poi.quantity_ordered), 0) * 100,
        2
    ) AS receipt_percentage
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY
    po.purchase_order_id,
    s.supplier_name,
    po.status
ORDER BY po.purchase_order_id;


-- 8. Purchase order status distribution
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM purchase_orders),
        2
    ) AS percentage
FROM purchase_orders
GROUP BY status
ORDER BY order_count DESC;


-- 9. Supplier delivery completion rate
SELECT
    s.supplier_name,
    SUM(poi.quantity_ordered) AS total_ordered,
    SUM(poi.quantity_received) AS total_received,
    ROUND(
        SUM(poi.quantity_received) /
        NULLIF(SUM(poi.quantity_ordered), 0) * 100,
        2
    ) AS delivery_completion_percentage
FROM suppliers s
JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY s.supplier_name
ORDER BY delivery_completion_percentage DESC;


-- 10. Sales revenue by warehouse
SELECT
    w.warehouse_name,
    COUNT(DISTINCT so.sales_order_id) AS total_orders,
    SUM(soi.quantity * soi.unit_price) AS total_revenue
FROM warehouses w
JOIN sales_orders so
    ON w.warehouse_id = so.warehouse_id
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY w.warehouse_name
ORDER BY total_revenue DESC;


-- 11. Sales revenue by product
SELECT
    p.product_name,
    SUM(soi.quantity) AS units_sold,
    SUM(soi.quantity * soi.unit_price) AS total_revenue
FROM products p
JOIN sales_order_items soi
    ON p.product_id = soi.product_id
JOIN sales_orders so
    ON soi.sales_order_id = so.sales_order_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;


-- 12. Sales revenue by category
SELECT
    c.category_name,
    SUM(soi.quantity) AS units_sold,
    SUM(soi.quantity * soi.unit_price) AS total_revenue
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
JOIN sales_order_items soi
    ON p.product_id = soi.product_id
JOIN sales_orders so
    ON soi.sales_order_id = so.sales_order_id
GROUP BY c.category_name
ORDER BY total_revenue DESC;


-- 13. Sales order value and item count
SELECT
    so.sales_order_id,
    so.status,
    COUNT(soi.product_id) AS distinct_products,
    SUM(soi.quantity) AS total_units,
    SUM(soi.quantity * soi.unit_price) AS order_value
FROM sales_orders so
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY
    so.sales_order_id,
    so.status
ORDER BY order_value DESC;


-- 14. Sales order status distribution
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM sales_orders),
        2
    ) AS percentage
FROM sales_orders
GROUP BY status
ORDER BY order_count DESC;


-- 15. Average sales order value by warehouse
SELECT
    w.warehouse_name,
    COUNT(DISTINCT so.sales_order_id) AS total_orders,
    ROUND(
        SUM(soi.quantity * soi.unit_price) /
        NULLIF(COUNT(DISTINCT so.sales_order_id), 0),
        2
    ) AS average_order_value
FROM warehouses w
JOIN sales_orders so
    ON w.warehouse_id = so.warehouse_id
JOIN sales_order_items soi
    ON so.sales_order_id = soi.sales_order_id
GROUP BY w.warehouse_name
ORDER BY average_order_value DESC;


-- 16. Most frequently sold products
SELECT
    p.product_name,
    SUM(soi.quantity) AS total_units_sold
FROM products p
JOIN sales_order_items soi
    ON p.product_id = soi.product_id
JOIN sales_orders so
    ON soi.sales_order_id = so.sales_order_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC
FETCH FIRST 5 ROWS ONLY;


-- 17. Products with no sales
SELECT
    p.product_id,
    p.product_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales_order_items soi
    WHERE soi.product_id = p.product_id
);


-- 18. Stock transfer status analysis
SELECT
    status,
    COUNT(*) AS transfer_count
FROM stock_transfers
GROUP BY status
ORDER BY transfer_count DESC;


-- 19. Transfer quantities by source and destination
SELECT
    sw.warehouse_name AS source_warehouse,
    dw.warehouse_name AS destination_warehouse,
    COUNT(DISTINCT st.transfer_id) AS transfer_count,
    SUM(sti.quantity_requested) AS total_requested_quantity,
    SUM(sti.quantity_received) AS total_received_quantity
FROM stock_transfers st
JOIN warehouses sw
    ON st.source_warehouse_id = sw.warehouse_id
JOIN warehouses dw
    ON st.destination_warehouse_id = dw.warehouse_id
JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id
GROUP BY
    sw.warehouse_name,
    dw.warehouse_name
ORDER BY transfer_count DESC;


-- 20. Transfer completion percentage
SELECT
    st.transfer_id,
    st.status,
    SUM(sti.quantity_requested) AS requested_quantity,
    SUM(sti.quantity_received) AS received_quantity,
    ROUND(
        SUM(sti.quantity_received) /
        NULLIF(SUM(sti.quantity_requested), 0) * 100,
        2
    ) AS completion_percentage
FROM stock_transfers st
JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id
GROUP BY
    st.transfer_id,
    st.status
ORDER BY st.transfer_id;


-- 21. Stock movement analysis by movement type
SELECT
    movement_type,
    COUNT(*) AS movement_count,
    SUM(quantity) AS total_quantity_moved
FROM stock_movements
GROUP BY movement_type
ORDER BY total_quantity_moved DESC;


-- 22. Stock movement history by product
SELECT
    p.product_name,
    COUNT(sm.movement_id) AS movement_count,
    SUM(sm.quantity) AS total_quantity_moved
FROM products p
JOIN inventory i
    ON p.product_id = i.product_id
JOIN stock_movements sm
    ON i.inventory_id = sm.inventory_id
GROUP BY p.product_name
ORDER BY total_quantity_moved DESC;


-- 23. Warehouse stock distribution by category
SELECT
    w.warehouse_name,
    c.category_name,
    SUM(i.quantity_on_hand) AS total_quantity,
    SUM(i.quantity_on_hand * p.unit_price) AS inventory_value
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
JOIN products p
    ON i.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY
    w.warehouse_name,
    c.category_name
ORDER BY w.warehouse_name, inventory_value DESC;


-- 24. Overall inventory KPIs
SELECT
    COUNT(DISTINCT product_id) AS products_in_inventory,
    SUM(quantity_on_hand) AS total_units_on_hand,
    SUM(quantity_reserved) AS total_reserved_units,
    SUM(quantity_on_hand - quantity_reserved) AS total_available_units
FROM inventory;


-- 25. Overall purchasing vs sales comparison
WITH purchase_summary AS (
    SELECT
        SUM(poi.quantity_ordered * poi.unit_cost) AS total_purchase_value
    FROM purchase_orders po
    JOIN purchase_order_items poi
        ON po.purchase_order_id = poi.purchase_order_id
),
sales_summary AS (
    SELECT
        SUM(soi.quantity * soi.unit_price) AS total_sales_value
    FROM sales_orders so
    JOIN sales_order_items soi
        ON so.sales_order_id = soi.sales_order_id
)
SELECT
    ps.total_purchase_value,
    ss.total_sales_value,
    ss.total_sales_value - ps.total_purchase_value AS sales_purchase_difference
FROM purchase_summary ps
CROSS JOIN sales_summary ss;


-- 26. Products ranked by inventory value
SELECT
    product_name,
    total_quantity,
    inventory_value,
    DENSE_RANK() OVER (
        ORDER BY inventory_value DESC
    ) AS value_rank
FROM (
    SELECT
        p.product_name,
        SUM(i.quantity_on_hand) AS total_quantity,
        SUM(i.quantity_on_hand * p.unit_price) AS inventory_value
    FROM products p
    JOIN inventory i
        ON p.product_id = i.product_id
    GROUP BY p.product_name
)
ORDER BY value_rank;


-- 27. Warehouses with the highest reserved stock
SELECT
    w.warehouse_name,
    SUM(i.quantity_reserved) AS total_reserved_stock,
    SUM(i.quantity_on_hand) AS total_on_hand_stock,
    ROUND(
        SUM(i.quantity_reserved) /
        NULLIF(SUM(i.quantity_on_hand), 0) * 100,
        2
    ) AS reserved_stock_percentage
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_name
ORDER BY reserved_stock_percentage DESC;


-- 28. Products available in every warehouse
SELECT
    p.product_id,
    p.product_name,
    COUNT(DISTINCT i.warehouse_id) AS warehouse_count
FROM products p
JOIN inventory i
    ON p.product_id = i.product_id
WHERE i.quantity_on_hand - i.quantity_reserved > 0
GROUP BY
    p.product_id,
    p.product_name
HAVING COUNT(DISTINCT i.warehouse_id) = (
    SELECT COUNT(*)
    FROM warehouses
)
ORDER BY p.product_name;


-- 29. Suppliers with the highest purchase order volume
SELECT
    s.supplier_name,
    COUNT(DISTINCT po.purchase_order_id) AS purchase_order_count,
    SUM(poi.quantity_ordered) AS total_units_ordered
FROM suppliers s
JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY s.supplier_name
ORDER BY total_units_ordered DESC;


-- 30. Products with the largest gap between ordered and received quantities
SELECT
    p.product_name,
    SUM(poi.quantity_ordered) AS total_ordered,
    SUM(poi.quantity_received) AS total_received,
    SUM(poi.quantity_ordered - poi.quantity_received) AS outstanding_quantity
FROM products p
JOIN purchase_order_items poi
    ON p.product_id = poi.product_id
JOIN purchase_orders po
    ON poi.purchase_order_id = po.purchase_order_id
WHERE po.status <> 'CANCELLED'
GROUP BY p.product_name
HAVING SUM(poi.quantity_ordered - poi.quantity_received) > 0
ORDER BY outstanding_quantity DESC;