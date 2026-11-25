-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 6.4: PL/SQL TRANSACTIONS
-- ============================================================


-- 1. BASIC COMMIT TRANSACTION
-- Create a savepoint before making inventory changes.

SAVEPOINT before_inventory_update;

UPDATE inventory
SET quantity_on_hand = quantity_on_hand + 10
WHERE inventory_id = 1;

SELECT
    inventory_id,
    quantity_on_hand
FROM inventory
WHERE inventory_id = 1;

COMMIT;


-- 2. ROLLBACK TRANSACTION
-- Undo an inventory change.

SAVEPOINT before_rollback_test;

UPDATE inventory
SET quantity_on_hand = quantity_on_hand + 50
WHERE inventory_id = 1;

SELECT
    inventory_id,
    quantity_on_hand
FROM inventory
WHERE inventory_id = 1;

ROLLBACK TO before_rollback_test;

SELECT
    inventory_id,
    quantity_on_hand
FROM inventory
WHERE inventory_id = 1;

ROLLBACK;


-- 3. SAVEPOINT TRANSACTION
-- Roll back only the second update.

SAVEPOINT transaction_start;

UPDATE inventory
SET quantity_on_hand = quantity_on_hand + 5
WHERE inventory_id = 1;

SAVEPOINT first_update_done;

UPDATE inventory
SET quantity_on_hand = quantity_on_hand + 15
WHERE inventory_id = 2;

ROLLBACK TO first_update_done;

SELECT
    inventory_id,
    quantity_on_hand
FROM inventory
WHERE inventory_id IN (1, 2)
ORDER BY inventory_id;

ROLLBACK TO transaction_start;

ROLLBACK;


-- 4. ATOMIC SALES ORDER CONFIRMATION
-- If confirmation fails, all changes are rolled back.

DECLARE
    v_sales_order_id NUMBER := 1;
BEGIN
    SAVEPOINT sales_confirmation_start;

    confirm_sales_order(v_sales_order_id);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sales_confirmation_start;
        DBMS_OUTPUT.PUT_LINE(
            'Sales confirmation failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 5. ATOMIC SALES ORDER FULFILLMENT

DECLARE
    v_sales_order_id NUMBER := 1;
BEGIN
    SAVEPOINT sales_fulfillment_start;

    fulfill_sales_order(v_sales_order_id);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sales_fulfillment_start;
        DBMS_OUTPUT.PUT_LINE(
            'Sales fulfillment failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 6. ATOMIC PURCHASE ORDER RECEIPT

DECLARE
    v_purchase_order_id NUMBER := 1;
BEGIN
    SAVEPOINT purchase_receipt_start;

    receive_purchase_order(v_purchase_order_id);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO purchase_receipt_start;
        DBMS_OUTPUT.PUT_LINE(
            'Purchase receipt failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 7. ATOMIC STOCK TRANSFER DISPATCH

DECLARE
    v_transfer_id NUMBER := 1;
BEGIN
    SAVEPOINT transfer_dispatch_start;

    dispatch_stock_transfer(v_transfer_id);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO transfer_dispatch_start;
        DBMS_OUTPUT.PUT_LINE(
            'Transfer dispatch failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 8. ATOMIC STOCK TRANSFER RECEIPT

DECLARE
    v_transfer_id NUMBER := 1;
BEGIN
    SAVEPOINT transfer_receipt_start;

    receive_stock_transfer(v_transfer_id);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO transfer_receipt_start;
        DBMS_OUTPUT.PUT_LINE(
            'Transfer receipt failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 9. TRANSACTION WITH MULTIPLE OPERATIONS

DECLARE
    v_inventory_id NUMBER := 1;
BEGIN
    SAVEPOINT multi_operation_start;

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand + 20
    WHERE inventory_id = v_inventory_id;

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - 5
    WHERE inventory_id = v_inventory_id;

    INSERT INTO stock_movements (
        inventory_id,
        movement_type,
        quantity,
        reference_id,
        movement_date
    )
    VALUES (
        v_inventory_id,
        'STOCK_ADJUSTMENT',
        15,
        NULL,
        SYSDATE
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO multi_operation_start;
        DBMS_OUTPUT.PUT_LINE(
            'Transaction failed: ' || SQLERRM
        );
        ROLLBACK;
END;
/


-- 10. VERIFY INVENTORY TRANSACTION RESULTS

SELECT
    i.inventory_id,
    p.product_name,
    w.warehouse_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_quantity
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY i.inventory_id;


-- 11. VERIFY STOCK MOVEMENT HISTORY

SELECT
    sm.movement_id,
    p.product_name,
    w.warehouse_name,
    sm.movement_type,
    sm.quantity,
    sm.reference_id,
    sm.movement_date
FROM stock_movements sm
JOIN inventory i
    ON sm.inventory_id = i.inventory_id
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY sm.movement_date DESC;


-- 12. CHECK INVALID INVENTORY RECORDS

SELECT
    inventory_id,
    quantity_on_hand,
    quantity_reserved
FROM inventory
WHERE quantity_on_hand < 0
   OR quantity_reserved < 0
   OR quantity_reserved > quantity_on_hand;