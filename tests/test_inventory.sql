-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 7.1: INVENTORY TESTS
-- ============================================================

SET SERVEROUTPUT ON;


-- 1. TEST INVENTORY TABLE
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM inventory;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Inventory table contains records.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Inventory table is empty.');
    END IF;
END;
/


-- 2. TEST NEGATIVE STOCK
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM inventory
    WHERE quantity_on_hand < 0;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: No negative stock quantities.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Negative stock quantities found.');
    END IF;
END;
/


-- 3. TEST RESERVED STOCK
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM inventory
    WHERE quantity_reserved < 0
       OR quantity_reserved > quantity_on_hand;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Reserved stock quantities are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid reserved stock quantities found.');
    END IF;
END;
/


-- 4. TEST DUPLICATE INVENTORY RECORDS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM (
        SELECT warehouse_id, product_id
        FROM inventory
        GROUP BY warehouse_id, product_id
        HAVING COUNT(*) > 1
    );

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: No duplicate warehouse-product records.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Duplicate inventory records found.');
    END IF;
END;
/


-- 5. TEST NEGATIVE AVERAGE COST
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM inventory
    WHERE average_unit_cost < 0;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Average unit costs are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Negative average unit costs found.');
    END IF;
END;
/


-- 6. TEST AVAILABLE STOCK CALCULATION
DECLARE
    v_inventory_id NUMBER;
    v_product_id NUMBER;
    v_warehouse_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT
        inventory_id,
        product_id,
        warehouse_id,
        quantity_on_hand - quantity_reserved
    INTO
        v_inventory_id,
        v_product_id,
        v_warehouse_id,
        v_expected
    FROM inventory
    WHERE ROWNUM = 1;

    v_actual := get_available_stock(
        v_product_id,
        v_warehouse_id
    );

    IF v_actual = v_expected THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Available stock function works correctly.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Available stock calculation is incorrect.');
    END IF;
END;
/


-- 7. TEST TOTAL STOCK FUNCTION
DECLARE
    v_product_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT product_id
    INTO v_product_id
    FROM inventory
    WHERE ROWNUM = 1;

    SELECT NVL(SUM(quantity_on_hand), 0)
    INTO v_expected
    FROM inventory
    WHERE product_id = v_product_id;

    v_actual := get_total_stock(v_product_id);

    IF v_actual = v_expected THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Total stock function works correctly.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Total stock calculation is incorrect.');
    END IF;
END;
/


-- 8. TEST TOTAL AVAILABLE STOCK FUNCTION
DECLARE
    v_product_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT product_id
    INTO v_product_id
    FROM inventory
    WHERE ROWNUM = 1;

    SELECT NVL(SUM(quantity_on_hand - quantity_reserved), 0)
    INTO v_expected
    FROM inventory
    WHERE product_id = v_product_id;

    v_actual := get_total_available_stock(v_product_id);

    IF v_actual = v_expected THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Total available stock function works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Total available stock is incorrect.');
    END IF;
END;
/


-- 9. TEST WAREHOUSE INVENTORY VALUE
DECLARE
    v_warehouse_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT warehouse_id
    INTO v_warehouse_id
    FROM inventory
    WHERE ROWNUM = 1;

    SELECT NVL(SUM(quantity_on_hand * average_unit_cost), 0)
    INTO v_expected
    FROM inventory
    WHERE warehouse_id = v_warehouse_id;

    v_actual := get_warehouse_inventory_value(v_warehouse_id);

    IF ABS(v_actual - v_expected) < 0.0001 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Warehouse inventory valuation works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Warehouse inventory valuation is incorrect.');
    END IF;
END;
/


-- 10. TEST TOTAL INVENTORY VALUE
DECLARE
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT NVL(SUM(quantity_on_hand * average_unit_cost), 0)
    INTO v_expected
    FROM inventory;

    v_actual := get_total_inventory_value();

    IF ABS(v_actual - v_expected) < 0.0001 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Total inventory valuation works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Total inventory valuation is incorrect.');
    END IF;
END;
/


-- 11. TEST REORDER QUANTITY
DECLARE
    v_product_id NUMBER;
    v_warehouse_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT
        i.product_id,
        i.warehouse_id,
        GREATEST(
            p.reorder_level -
            (i.quantity_on_hand - i.quantity_reserved),
            0
        )
    INTO
        v_product_id,
        v_warehouse_id,
        v_expected
    FROM inventory i
    JOIN products p
        ON i.product_id = p.product_id
    WHERE ROWNUM = 1;

    v_actual := get_reorder_quantity(
        v_product_id,
        v_warehouse_id
    );

    IF v_actual = v_expected THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Reorder quantity function works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Reorder quantity calculation is incorrect.');
    END IF;
END;
/


-- 12. TEST INVENTORY TRIGGER: NEGATIVE STOCK
DECLARE
    v_inventory_id NUMBER;
    v_trigger_fired BOOLEAN := FALSE;
BEGIN
    SELECT inventory_id
    INTO v_inventory_id
    FROM inventory
    WHERE ROWNUM = 1;

    SAVEPOINT before_negative_stock_test;

    BEGIN
        UPDATE inventory
        SET quantity_on_hand = -1
        WHERE inventory_id = v_inventory_id;

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20101 THEN
                v_trigger_fired := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    ROLLBACK TO before_negative_stock_test;

    IF v_trigger_fired THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Negative stock trigger works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Negative stock trigger did not fire.');
    END IF;
END;
/


-- 13. TEST INVENTORY TRIGGER: RESERVED STOCK
DECLARE
    v_inventory_id NUMBER;
    v_quantity_on_hand NUMBER;
    v_trigger_fired BOOLEAN := FALSE;
BEGIN
    SELECT inventory_id, quantity_on_hand
    INTO v_inventory_id, v_quantity_on_hand
    FROM inventory
    WHERE ROWNUM = 1;

    SAVEPOINT before_reserved_stock_test;

    BEGIN
        UPDATE inventory
        SET quantity_reserved = quantity_on_hand + 1
        WHERE inventory_id = v_inventory_id;

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20103 THEN
                v_trigger_fired := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    ROLLBACK TO before_reserved_stock_test;

    IF v_trigger_fired THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Reserved stock validation trigger works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Reserved stock validation trigger did not fire.');
    END IF;
END;
/


-- 14. TEST INVENTORY LAST UPDATED TRIGGER
DECLARE
    v_inventory_id NUMBER;
    v_old_date DATE;
    v_new_date DATE;
BEGIN
    SELECT inventory_id, last_updated
    INTO v_inventory_id, v_old_date
    FROM inventory
    WHERE ROWNUM = 1;

    SAVEPOINT before_timestamp_test;

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand
    WHERE inventory_id = v_inventory_id;

    SELECT last_updated
    INTO v_new_date
    FROM inventory
    WHERE inventory_id = v_inventory_id;

    ROLLBACK TO before_timestamp_test;

    IF v_new_date IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Inventory timestamp trigger works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Inventory timestamp was not updated.');
    END IF;
END;
/


-- 15. INVENTORY TEST SUMMARY
SELECT
    COUNT(*) AS inventory_records,
    SUM(quantity_on_hand) AS total_stock,
    SUM(quantity_reserved) AS reserved_stock,
    SUM(quantity_on_hand - quantity_reserved) AS available_stock,
    SUM(quantity_on_hand * average_unit_cost) AS total_inventory_value
FROM inventory;


-- 16. INVENTORY VALIDATION REPORT
SELECT
    i.inventory_id,
    p.product_name,
    w.warehouse_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_on_hand - i.quantity_reserved AS available_stock,
    i.average_unit_cost
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
ORDER BY w.warehouse_name, p.product_name;