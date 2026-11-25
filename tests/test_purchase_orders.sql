-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 7.2: PURCHASE ORDER TESTS
-- ============================================================

SET SERVEROUTPUT ON;


-- 1. TEST PURCHASE ORDER RECORDS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_orders;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase orders exist.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: No purchase orders found.');
    END IF;
END;
/


-- 2. TEST PURCHASE ORDER ITEM RECORDS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_order_items;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase order items exist.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: No purchase order items found.');
    END IF;
END;
/


-- 3. TEST PURCHASE ORDER REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_order_items poi
    LEFT JOIN purchase_orders po
        ON poi.purchase_order_id = po.purchase_order_id
    WHERE po.purchase_order_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All purchase items reference valid orders.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid purchase order references found.');
    END IF;
END;
/


-- 4. TEST PURCHASE ORDER QUANTITIES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_order_items
    WHERE quantity_ordered <= 0
       OR quantity_received < 0
       OR quantity_received > quantity_ordered;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase quantities are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid purchase quantities found.');
    END IF;
END;
/


-- 5. TEST PURCHASE UNIT COSTS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_order_items
    WHERE unit_cost <= 0;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase unit costs are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid purchase unit costs found.');
    END IF;
END;
/


-- 6. TEST PURCHASE ORDER TOTAL FUNCTION
DECLARE
    v_order_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT purchase_order_id
    INTO v_order_id
    FROM purchase_orders
    WHERE ROWNUM = 1;

    SELECT NVL(SUM(quantity_ordered * unit_cost), 0)
    INTO v_expected
    FROM purchase_order_items
    WHERE purchase_order_id = v_order_id;

    v_actual := get_purchase_order_total(v_order_id);

    IF ABS(v_expected - v_actual) < 0.0001 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase order total function works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Purchase order total is incorrect.');
    END IF;
END;
/


-- 7. TEST OUTSTANDING PURCHASE QUANTITY FUNCTION
DECLARE
    v_order_id NUMBER;
    v_expected NUMBER;
    v_actual NUMBER;
BEGIN
    SELECT purchase_order_id
    INTO v_order_id
    FROM purchase_orders
    WHERE ROWNUM = 1;

    SELECT NVL(SUM(quantity_ordered - quantity_received), 0)
    INTO v_expected
    FROM purchase_order_items
    WHERE purchase_order_id = v_order_id;

    v_actual := get_outstanding_purchase_quantity(v_order_id);

    IF v_expected = v_actual THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Outstanding quantity function works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Outstanding quantity is incorrect.');
    END IF;
END;
/


-- 8. TEST PURCHASE ORDER STATUS VALUES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_orders
    WHERE status NOT IN (
        'DRAFT',
        'APPROVED',
        'PARTIALLY_RECEIVED',
        'RECEIVED',
        'CANCELLED'
    );

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase order statuses are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid purchase order statuses found.');
    END IF;
END;
/


-- 9. TEST PURCHASE ORDER SUPPLIER REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_orders po
    LEFT JOIN suppliers s
        ON po.supplier_id = s.supplier_id
    WHERE s.supplier_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All purchase orders have valid suppliers.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid supplier references found.');
    END IF;
END;
/


-- 10. TEST PURCHASE ORDER WAREHOUSE REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM purchase_orders po
    LEFT JOIN warehouses w
        ON po.warehouse_id = w.warehouse_id
    WHERE w.warehouse_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All purchase orders have valid warehouses.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid warehouse references found.');
    END IF;
END;
/


-- 11. TEST PURCHASE RECEIPT PROCEDURE
-- Uses a savepoint and rolls back all changes.

DECLARE
    v_order_id NUMBER;
    v_status purchase_orders.status%TYPE;
    v_receivable_items NUMBER;
    v_procedure_executed BOOLEAN := FALSE;
BEGIN
    SELECT purchase_order_id
    INTO v_order_id
    FROM purchase_orders
    WHERE status IN ('APPROVED', 'PARTIALLY_RECEIVED')
      AND EXISTS (
          SELECT 1
          FROM purchase_order_items poi
          WHERE poi.purchase_order_id = purchase_orders.purchase_order_id
            AND poi.quantity_received < poi.quantity_ordered
      )
      AND ROWNUM = 1;

    SAVEPOINT before_purchase_receipt_test;

    receive_purchase_order(v_order_id);

    v_procedure_executed := TRUE;

    SELECT status
    INTO v_status
    FROM purchase_orders
    WHERE purchase_order_id = v_order_id;

    IF v_status = 'RECEIVED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase receipt procedure updated order status.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Purchase order status was not updated.');
    END IF;

    ROLLBACK TO before_purchase_receipt_test;

    IF v_procedure_executed THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Purchase receipt changes rolled back.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('SKIP: No receivable purchase order available.');
        ROLLBACK;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('FAIL: ' || SQLERRM);
END;
/


-- 12. TEST PURCHASE ORDER RECEIPT COMPLETION
SELECT
    po.purchase_order_id,
    s.supplier_name,
    po.status,
    SUM(poi.quantity_ordered) AS total_ordered,
    SUM(poi.quantity_received) AS total_received,
    SUM(poi.quantity_ordered - poi.quantity_received) AS outstanding_quantity,
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


-- 13. PURCHASE ORDER FINANCIAL REPORT
SELECT
    po.purchase_order_id,
    s.supplier_name,
    w.warehouse_name,
    po.status,
    SUM(poi.quantity_ordered * poi.unit_cost) AS ordered_value,
    SUM(poi.quantity_received * poi.unit_cost) AS received_value
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN warehouses w
    ON po.warehouse_id = w.warehouse_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY
    po.purchase_order_id,
    s.supplier_name,
    w.warehouse_name,
    po.status
ORDER BY po.purchase_order_id;


-- 14. SUPPLIER PURCHASE PERFORMANCE
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(DISTINCT po.purchase_order_id) AS total_orders,
    SUM(poi.quantity_ordered) AS total_ordered,
    SUM(poi.quantity_received) AS total_received,
    ROUND(
        SUM(poi.quantity_received) /
        NULLIF(SUM(poi.quantity_ordered), 0) * 100,
        2
    ) AS fulfillment_percentage
FROM suppliers s
JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id
JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
WHERE po.status <> 'CANCELLED'
GROUP BY
    s.supplier_id,
    s.supplier_name
ORDER BY fulfillment_percentage DESC;


-- 15. PURCHASE ORDER VALIDATION REPORT
SELECT
    po.purchase_order_id,
    po.status,
    COUNT(poi.purchase_item_id) AS item_count,
    SUM(poi.quantity_ordered) AS ordered_quantity,
    SUM(poi.quantity_received) AS received_quantity,
    SUM(poi.quantity_ordered * poi.unit_cost) AS order_value
FROM purchase_orders po
LEFT JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY
    po.purchase_order_id,
    po.status
ORDER BY po.purchase_order_id;