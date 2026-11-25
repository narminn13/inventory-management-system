
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 4: INDEXES
-- ============================================

-- 1. PRODUCT SEARCH

CREATE INDEX idx_products_name
ON products (product_name);

CREATE INDEX idx_products_category
ON products (category_id);


-- 2. INVENTORY SEARCH

CREATE INDEX idx_inventory_product
ON inventory (product_id);

CREATE INDEX idx_inventory_warehouse
ON inventory (warehouse_id);


-- 3. PURCHASE ORDER SEARCH

CREATE INDEX idx_po_supplier
ON purchase_orders (supplier_id);

CREATE INDEX idx_po_warehouse_status
ON purchase_orders (warehouse_id, status);

CREATE INDEX idx_po_order_date
ON purchase_orders (order_date);


-- 4. SALES ORDER SEARCH

CREATE INDEX idx_so_warehouse_status
ON sales_orders (warehouse_id, status);

CREATE INDEX idx_so_order_date
ON sales_orders (order_date);


-- 5. STOCK MOVEMENT SEARCH

CREATE INDEX idx_sm_inventory_date
ON stock_movements (inventory_id, movement_date);

CREATE INDEX idx_sm_movement_type
ON stock_movements (movement_type);


-- 6. STOCK TRANSFER SEARCH

CREATE INDEX idx_transfer_source_status
ON stock_transfers (source_warehouse_id, status);

CREATE INDEX idx_transfer_destination
ON stock_transfers (destination_warehouse_id);


-- 7. VERIFY CREATED INDEXES

SELECT
    index_name,
    table_name,
    uniqueness,
    status
FROM user_indexes
WHERE table_name IN (
    'PRODUCTS',
    'INVENTORY',
    'PURCHASE_ORDERS',
    'SALES_ORDERS',
    'STOCK_MOVEMENTS',
    'STOCK_TRANSFERS'
)
ORDER BY table_name, index_name;
