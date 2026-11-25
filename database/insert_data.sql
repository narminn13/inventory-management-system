
-- ============================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 3: SAMPLE DATA
-- ============================================

-- 1. CATEGORIES

INSERT INTO categories (category_name, description)
VALUES ('Electronics', 'Electronic devices and equipment');

INSERT INTO categories (category_name, description)
VALUES ('Computer Accessories', 'Accessories for computers');

INSERT INTO categories (category_name, description)
VALUES ('Office Furniture', 'Furniture for office environments');

INSERT INTO categories (category_name, description)
VALUES ('Networking', 'Networking devices and equipment');

INSERT INTO categories (category_name, description)
VALUES ('Storage Devices', 'Data storage products');


-- 2. SUPPLIERS

INSERT INTO suppliers
(supplier_name, contact_person, email, phone, address, is_active)
VALUES
('TechSource Ltd', 'John Smith', 'contact@techsource.com',
 '+994501112233', 'Baku, Azerbaijan', 'Y');

INSERT INTO suppliers
(supplier_name, contact_person, email, phone, address, is_active)
VALUES
('Global Electronics', 'Michael Brown', 'info@globalelectronics.com',
 '+994502223344', 'Baku, Azerbaijan', 'Y');

INSERT INTO suppliers
(supplier_name, contact_person, email, phone, address, is_active)
VALUES
('Office Solutions', 'Sarah Wilson', 'sales@officesolutions.com',
 '+994503334455', 'Sumqayit, Azerbaijan', 'Y');

INSERT INTO suppliers
(supplier_name, contact_person, email, phone, address, is_active)
VALUES
('NetWorld Distribution', 'David Lee', 'info@networld.com',
 '+994504445566', 'Baku, Azerbaijan', 'Y');


-- 3. WAREHOUSES

INSERT INTO warehouses
(warehouse_name, location, capacity, is_active)
VALUES
('Main Warehouse', 'Baku', 10000, 'Y');

INSERT INTO warehouses
(warehouse_name, location, capacity, is_active)
VALUES
('North Branch', 'Sumqayit', 5000, 'Y');

INSERT INTO warehouses
(warehouse_name, location, capacity, is_active)
VALUES
('South Branch', 'Khirdalan', 4000, 'Y');


-- 4. PRODUCTS

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ELEC-001', 'Laptop',
       'Business laptop', 'UNIT', 1800, 5, 'Y'
FROM categories WHERE category_name = 'Electronics';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ACC-001', 'Wireless Mouse',
       'Wireless computer mouse', 'UNIT', 35, 20, 'Y'
FROM categories WHERE category_name = 'Computer Accessories';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ACC-002', 'Mechanical Keyboard',
       'Mechanical keyboard', 'UNIT', 85, 10, 'Y'
FROM categories WHERE category_name = 'Computer Accessories';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ELEC-002', 'Monitor',
       '24-inch LED monitor', 'UNIT', 250, 5, 'Y'
FROM categories WHERE category_name = 'Electronics';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'FURN-001', 'Office Chair',
       'Ergonomic office chair', 'UNIT', 220, 5, 'Y'
FROM categories WHERE category_name = 'Office Furniture';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'NET-001', 'Wireless Router',
       'Dual-band wireless router', 'UNIT', 120, 10, 'Y'
FROM categories WHERE category_name = 'Networking';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ACC-003', 'USB-C Hub',
       'Multiport USB-C hub', 'UNIT', 55, 15, 'Y'
FROM categories WHERE category_name = 'Computer Accessories';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ELEC-003', 'Printer',
       'Laser office printer', 'UNIT', 320, 5, 'Y'
FROM categories WHERE category_name = 'Electronics';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'STO-001', 'SSD 1TB',
       '1TB solid state drive', 'UNIT', 110, 10, 'Y'
FROM categories WHERE category_name = 'Storage Devices';

INSERT INTO products
(category_id, sku, product_name, description,
 unit_of_measure, selling_price, reorder_level, is_active)
SELECT category_id, 'ACC-004', 'Webcam',
       'Full HD webcam', 'UNIT', 75, 10, 'Y'
FROM categories WHERE category_name = 'Computer Accessories';


-- 5. INVENTORY

-- Main Warehouse

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 30, 2, 1350
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ELEC-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 100, 10, 20
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ACC-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 60, 0, 55
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ACC-002';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 25, 0, 180
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ELEC-002';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 15, 0, 160
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'FURN-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 40, 5, 85
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'NET-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 120, 0, 35
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ACC-003';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 12, 0, 250
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ELEC-003';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 50, 0, 75
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'STO-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 35, 0, 48
FROM warehouses w, products p
WHERE w.warehouse_name = 'Main Warehouse'
AND p.sku = 'ACC-004';


-- North Branch

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 10, 0, 1400
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'ELEC-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 40, 0, 22
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'ACC-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 30, 0, 58
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'ACC-002';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 8, 0, 185
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'ELEC-002';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 15, 0, 90
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'NET-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 20, 0, 80
FROM warehouses w, products p
WHERE w.warehouse_name = 'North Branch'
AND p.sku = 'STO-001';


-- South Branch

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 25, 0, 21
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'ACC-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 20, 0, 56
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'ACC-002';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 10, 0, 165
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'FURN-001';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 5, 0, 260
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'ELEC-003';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 10, 0, 50
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'ACC-004';

INSERT INTO inventory
(warehouse_id, product_id, quantity_on_hand,
 quantity_reserved, average_unit_cost)
SELECT w.warehouse_id, p.product_id, 50, 0, 33
FROM warehouses w, products p
WHERE w.warehouse_name = 'South Branch'
AND p.sku = 'ACC-003';


-- 6. PURCHASE ORDERS

INSERT INTO purchase_orders
(supplier_id, warehouse_id, order_date, expected_date, status)
SELECT s.supplier_id, w.warehouse_id,
       DATE '2026-10-01', DATE '2026-10-10', 'RECEIVED'
FROM suppliers s, warehouses w
WHERE s.supplier_name = 'TechSource Ltd'
AND w.warehouse_name = 'Main Warehouse';

INSERT INTO purchase_orders
(supplier_id, warehouse_id, order_date, expected_date, status)
SELECT s.supplier_id, w.warehouse_id,
       DATE '2026-11-01', DATE '2026-11-30', 'APPROVED'
FROM suppliers s, warehouses w
WHERE s.supplier_name = 'Global Electronics'
AND w.warehouse_name = 'North Branch';

INSERT INTO purchase_orders
(supplier_id, warehouse_id, order_date, expected_date, status)
SELECT s.supplier_id, w.warehouse_id,
       DATE '2026-11-05', DATE '2026-12-05', 'DRAFT'
FROM suppliers s, warehouses w
WHERE s.supplier_name = 'Office Solutions'
AND w.warehouse_name = 'South Branch';


-- 7. PURCHASE ORDER ITEMS

INSERT INTO purchase_order_items
(purchase_order_id, product_id, quantity_ordered,
 quantity_received, unit_cost)
SELECT po.purchase_order_id, p.product_id, 30, 30, 1350
FROM purchase_orders po, products p, suppliers s
WHERE po.supplier_id = s.supplier_id
AND s.supplier_name = 'TechSource Ltd'
AND p.sku = 'ELEC-001';

INSERT INTO purchase_order_items
(purchase_order_id, product_id, quantity_ordered,
 quantity_received, unit_cost)
SELECT po.purchase_order_id, p.product_id, 100, 100, 20
FROM purchase_orders po, products p, suppliers s
WHERE po.supplier_id = s.supplier_id
AND s.supplier_name = 'TechSource Ltd'
AND p.sku = 'ACC-001';

INSERT INTO purchase_order_items
(purchase_order_id, product_id, quantity_ordered,
 quantity_received, unit_cost)
SELECT po.purchase_order_id, p.product_id, 20, 0, 1400
FROM purchase_orders po, products p, suppliers s
WHERE po.supplier_id = s.supplier_id
AND s.supplier_name = 'Global Electronics'
AND p.sku = 'ELEC-001';

INSERT INTO purchase_order_items
(purchase_order_id, product_id, quantity_ordered,
 quantity_received, unit_cost)
SELECT po.purchase_order_id, p.product_id, 15, 0, 190
FROM purchase_orders po, products p, suppliers s
WHERE po.supplier_id = s.supplier_id
AND s.supplier_name = 'Global Electronics'
AND p.sku = 'ELEC-002';

INSERT INTO purchase_order_items
(purchase_order_id, product_id, quantity_ordered,
 quantity_received, unit_cost)
SELECT po.purchase_order_id, p.product_id, 10, 0, 170
FROM purchase_orders po, products p, suppliers s
WHERE po.supplier_id = s.supplier_id
AND s.supplier_name = 'Office Solutions'
AND p.sku = 'FURN-001';


-- 8. SALES ORDERS

INSERT INTO sales_orders
(customer_name, customer_email, warehouse_id, order_date, status)
SELECT 'Ali Mammadov', 'ali@example.com',
       warehouse_id, DATE '2026-11-10', 'CONFIRMED'
FROM warehouses
WHERE warehouse_name = 'Main Warehouse';

INSERT INTO sales_orders
(customer_name, customer_email, warehouse_id, order_date, status)
SELECT 'Leyla Karimova', 'leyla@example.com',
       warehouse_id, DATE '2026-11-12', 'FULFILLED'
FROM warehouses
WHERE warehouse_name = 'North Branch';

INSERT INTO sales_orders
(customer_name, customer_email, warehouse_id, order_date, status)
SELECT 'Murad Aliyev', 'murad@example.com',
       warehouse_id, DATE '2026-11-15', 'DRAFT'
FROM warehouses
WHERE warehouse_name = 'South Branch';


-- 9. SALES ORDER ITEMS

INSERT INTO sales_order_items
(sales_order_id, product_id, quantity, unit_price)
SELECT so.sales_order_id, p.product_id, 2, 1800
FROM sales_orders so, products p
WHERE so.customer_email = 'ali@example.com'
AND p.sku = 'ELEC-001';

INSERT INTO sales_order_items
(sales_order_id, product_id, quantity, unit_price)
SELECT so.sales_order_id, p.product_id, 10, 35
FROM sales_orders so, products p
WHERE so.customer_email = 'ali@example.com'
AND p.sku = 'ACC-001';

INSERT INTO sales_order_items
(sales_order_id, product_id, quantity, unit_price)
SELECT so.sales_order_id, p.product_id, 3, 85
FROM sales_orders so, products p
WHERE so.customer_email = 'leyla@example.com'
AND p.sku = 'ACC-002';

INSERT INTO sales_order_items
(sales_order_id, product_id, quantity, unit_price)
SELECT so.sales_order_id, p.product_id, 1, 250
FROM sales_orders so, products p
WHERE so.customer_email = 'leyla@example.com'
AND p.sku = 'ELEC-002';

INSERT INTO sales_order_items
(sales_order_id, product_id, quantity, unit_price)
SELECT so.sales_order_id, p.product_id, 1, 320
FROM sales_orders so, products p
WHERE so.customer_email = 'murad@example.com'
AND p.sku = 'ELEC-003';


-- 10. STOCK TRANSFERS

INSERT INTO stock_transfers
(source_warehouse_id, destination_warehouse_id,
 transfer_date, status, notes)
SELECT source_w.warehouse_id, destination_w.warehouse_id,
       DATE '2026-11-18', 'APPROVED',
       'Router transfer to North Branch'
FROM warehouses source_w, warehouses destination_w
WHERE source_w.warehouse_name = 'Main Warehouse'
AND destination_w.warehouse_name = 'North Branch';

INSERT INTO stock_transfers
(source_warehouse_id, destination_warehouse_id,
 transfer_date, status, notes)
SELECT source_w.warehouse_id, destination_w.warehouse_id,
       DATE '2026-11-20', 'DRAFT',
       'SSD transfer to South Branch'
FROM warehouses source_w, warehouses destination_w
WHERE source_w.warehouse_name = 'North Branch'
AND destination_w.warehouse_name = 'South Branch';


-- 11. STOCK TRANSFER ITEMS

INSERT INTO stock_transfer_items
(transfer_id, product_id, quantity, quantity_received)
SELECT st.transfer_id, p.product_id, 5, 0
FROM stock_transfers st, products p
WHERE st.notes = 'Router transfer to North Branch'
AND p.sku = 'NET-001';

INSERT INTO stock_transfer_items
(transfer_id, product_id, quantity, quantity_received)
SELECT st.transfer_id, p.product_id, 4, 0
FROM stock_transfers st, products p
WHERE st.notes = 'SSD transfer to South Branch'
AND p.sku = 'STO-001';


-- 12. INITIAL STOCK MOVEMENTS

INSERT INTO stock_movements
(inventory_id, movement_type, quantity,
 reference_type, reference_id, movement_date, notes)
SELECT i.inventory_id, 'STOCK_ADJUSTMENT',
       i.quantity_on_hand, 'INITIAL_STOCK', NULL,
       DATE '2026-10-01', 'Initial inventory balance'
FROM inventory i;


-- ============================================
-- COMMIT TRANSACTION
-- ============================================

COMMIT;
