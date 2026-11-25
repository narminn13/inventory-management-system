-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 6.3: PL/SQL TRIGGERS
-- ============================================================


-- 1. UPDATE INVENTORY LAST UPDATED TIMESTAMP
CREATE OR REPLACE TRIGGER trg_inventory_last_updated
BEFORE UPDATE ON inventory
FOR EACH ROW
BEGIN
    :NEW.last_updated := SYSDATE;
END;
/


-- 2. PREVENT NEGATIVE INVENTORY QUANTITY
CREATE OR REPLACE TRIGGER trg_prevent_negative_inventory
BEFORE INSERT OR UPDATE OF quantity_on_hand, quantity_reserved
ON inventory
FOR EACH ROW
BEGIN
    IF :NEW.quantity_on_hand < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20101,
            'Quantity on hand cannot be negative.'
        );
    END IF;

    IF :NEW.quantity_reserved < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20102,
            'Reserved quantity cannot be negative.'
        );
    END IF;

    IF :NEW.quantity_reserved > :NEW.quantity_on_hand THEN
        RAISE_APPLICATION_ERROR(
            -20103,
            'Reserved quantity cannot exceed quantity on hand.'
        );
    END IF;
END;
/


-- 3. PREVENT INVALID PRODUCT PRICES
CREATE OR REPLACE TRIGGER trg_validate_product_price
BEFORE INSERT OR UPDATE OF unit_price
ON products
FOR EACH ROW
BEGIN
    IF :NEW.unit_price <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20104,
            'Product price must be greater than zero.'
        );
    END IF;
END;
/


-- 4. PREVENT INVALID PURCHASE ORDER ITEM QUANTITIES
CREATE OR REPLACE TRIGGER trg_validate_purchase_item
BEFORE INSERT OR UPDATE OF quantity_ordered, quantity_received, unit_cost
ON purchase_order_items
FOR EACH ROW
BEGIN
    IF :NEW.quantity_ordered <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20105,
            'Purchase quantity must be greater than zero.'
        );
    END IF;

    IF :NEW.quantity_received < 0
       OR :NEW.quantity_received > :NEW.quantity_ordered THEN
        RAISE_APPLICATION_ERROR(
            -20106,
            'Received quantity must be between zero and ordered quantity.'
        );
    END IF;

    IF :NEW.unit_cost <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20107,
            'Purchase unit cost must be greater than zero.'
        );
    END IF;
END;
/


-- 5. PREVENT INVALID SALES ORDER ITEM QUANTITIES
CREATE OR REPLACE TRIGGER trg_validate_sales_item
BEFORE INSERT OR UPDATE OF quantity, unit_price
ON sales_order_items
FOR EACH ROW
BEGIN
    IF :NEW.quantity <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20108,
            'Sales quantity must be greater than zero.'
        );
    END IF;

    IF :NEW.unit_price <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20109,
            'Sales unit price must be greater than zero.'
        );
    END IF;
END;
/


-- 6. PREVENT INVALID STOCK TRANSFER QUANTITIES
CREATE OR REPLACE TRIGGER trg_validate_transfer_item
BEFORE INSERT OR UPDATE OF quantity_requested, quantity_received
ON stock_transfer_items
FOR EACH ROW
BEGIN
    IF :NEW.quantity_requested <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20110,
            'Transfer quantity must be greater than zero.'
        );
    END IF;

    IF :NEW.quantity_received < 0
       OR :NEW.quantity_received > :NEW.quantity_requested THEN
        RAISE_APPLICATION_ERROR(
            -20111,
            'Received transfer quantity must be between zero and requested quantity.'
        );
    END IF;
END;
/


-- 7. PREVENT TRANSFER BETWEEN THE SAME WAREHOUSE
CREATE OR REPLACE TRIGGER trg_validate_transfer_warehouses
BEFORE INSERT OR UPDATE OF source_warehouse_id, destination_warehouse_id
ON stock_transfers
FOR EACH ROW
BEGIN
    IF :NEW.source_warehouse_id = :NEW.destination_warehouse_id THEN
        RAISE_APPLICATION_ERROR(
            -20112,
            'Source and destination warehouses must be different.'
        );
    END IF;
END;
/


-- 8. PREVENT CHANGING PRODUCT PRICE TO ZERO OR NEGATIVE
CREATE OR REPLACE TRIGGER trg_validate_average_cost
BEFORE INSERT OR UPDATE OF average_unit_cost
ON inventory
FOR EACH ROW
BEGIN
    IF :NEW.average_unit_cost < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20113,
            'Average unit cost cannot be negative.'
        );
    END IF;
END;
/


-- 9. PREVENT DEACTIVATING PRODUCT WITH RESERVED STOCK
CREATE OR REPLACE TRIGGER trg_product_reserved_stock
BEFORE UPDATE OF is_active
ON products
FOR EACH ROW
DECLARE
    v_reserved_stock NUMBER;
BEGIN
    IF :NEW.is_active = 'N' AND :OLD.is_active = 'Y' THEN
        SELECT NVL(SUM(quantity_reserved), 0)
        INTO v_reserved_stock
        FROM inventory
        WHERE product_id = :OLD.product_id;

        IF v_reserved_stock > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20114,
                'Product cannot be deactivated while stock is reserved.'
            );
        END IF;
    END IF;
END;
/


-- 10. PREVENT DELETING INVENTORY WITH RESERVED STOCK
CREATE OR REPLACE TRIGGER trg_prevent_inventory_delete
BEFORE DELETE ON inventory
FOR EACH ROW
BEGIN
    IF :OLD.quantity_reserved > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20115,
            'Inventory with reserved stock cannot be deleted.'
        );
    END IF;
END;
/


-- ============================================================
-- TRIGGER STATUS CHECK
-- ============================================================

SELECT
    trigger_name,
    status,
    triggering_event,
    table_name
FROM user_triggers
WHERE trigger_name LIKE 'TRG_%'
ORDER BY trigger_name
;