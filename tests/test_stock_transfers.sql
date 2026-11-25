-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 7.3: STOCK TRANSFER TESTS
-- ============================================================

SET SERVEROUTPUT ON;


-- 1. TEST STOCK TRANSFER RECORDS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Stock transfer records exist.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: No stock transfers found.');
    END IF;
END;
/


-- 2. TEST STOCK TRANSFER ITEMS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfer_items;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Stock transfer items exist.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: No stock transfer items found.');
    END IF;
END;
/


-- 3. TEST TRANSFER WAREHOUSE REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers st
    LEFT JOIN warehouses w
        ON st.source_warehouse_id = w.warehouse_id
    WHERE w.warehouse_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All source warehouses are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid source warehouse references found.');
    END IF;
END;
/


-- 4. TEST DESTINATION WAREHOUSE REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers st
    LEFT JOIN warehouses w
        ON st.destination_warehouse_id = w.warehouse_id
    WHERE w.warehouse_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All destination warehouses are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid destination warehouse references found.');
    END IF;
END;
/


-- 5. TEST TRANSFER BETWEEN DIFFERENT WAREHOUSES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers
    WHERE source_warehouse_id = destination_warehouse_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Source and destination warehouses differ.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid warehouse transfer found.');
    END IF;
END;
/


-- 6. TEST TRANSFER QUANTITIES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfer_items
    WHERE quantity_requested <= 0
       OR quantity_received < 0
       OR quantity_received > quantity_requested;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Transfer quantities are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid transfer quantities found.');
    END IF;
END;
/


-- 7. TEST TRANSFER ITEM REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfer_items sti
    LEFT JOIN stock_transfers st
        ON sti.transfer_id = st.transfer_id
    WHERE st.transfer_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All transfer items reference valid transfers.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid transfer references found.');
    END IF;
END;
/


-- 8. TEST TRANSFER PRODUCT REFERENCES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfer_items sti
    LEFT JOIN products p
        ON sti.product_id = p.product_id
    WHERE p.product_id IS NULL;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All transfer products are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid product references found.');
    END IF;
END;
/


-- 9. TEST TRANSFER STATUS VALUES
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers
    WHERE status NOT IN (
        'DRAFT',
        'APPROVED',
        'IN_TRANSIT',
        'RECEIVED',
        'CANCELLED'
    );

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Transfer statuses are valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Invalid transfer statuses found.');
    END IF;
END;
/


-- 10. TEST FULL RECEIPT RULE FOR COMPLETED TRANSFERS
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM stock_transfers st
    WHERE st.status = 'RECEIVED'
      AND EXISTS (
          SELECT 1
          FROM stock_transfer_items sti
          WHERE sti.transfer_id = st.transfer_id
            AND sti.quantity_received <> sti.quantity_requested
      );

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('PASS: All completed transfers are fully received.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Incomplete received transfers found.');
    END IF;
END;
/


-- 11. TEST TRANSFER APPROVAL PROCEDURE
DECLARE
    v_transfer_id NUMBER;
    v_status stock_transfers.status%TYPE;
BEGIN
    SELECT transfer_id
    INTO v_transfer_id
    FROM stock_transfers
    WHERE status = 'DRAFT'
      AND ROWNUM = 1;

    SAVEPOINT before_approval_test;

    approve_stock_transfer(v_transfer_id);

    SELECT status
    INTO v_status
    FROM stock_transfers
    WHERE transfer_id = v_transfer_id;

    IF v_status = 'APPROVED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Transfer approval procedure works.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Transfer approval failed.');
    END IF;

    ROLLBACK TO before_approval_test;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('SKIP: No draft transfer available.');
        ROLLBACK;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('FAIL: ' || SQLERRM);
END;
/


-- 12. TEST TRANSFER DISPATCH AND RECEIPT
-- This test rolls back all changes after successful execution.

DECLARE
    v_transfer_id NUMBER;
    v_status stock_transfers.status%TYPE;
BEGIN
    SELECT transfer_id
    INTO v_transfer_id
    FROM stock_transfers
    WHERE status = 'APPROVED'
      AND ROWNUM = 1;

    SAVEPOINT before_transfer_lifecycle_test;

    dispatch_stock_transfer(v_transfer_id);

    SELECT status
    INTO v_status
    FROM stock_transfers
    WHERE transfer_id = v_transfer_id;

    IF v_status <> 'IN_TRANSIT' THEN
        RAISE_APPLICATION_ERROR(-20201, 'Transfer dispatch status is incorrect.');
    END IF;

    receive_stock_transfer(v_transfer_id);

    SELECT status
    INTO v_status
    FROM stock_transfers
    WHERE transfer_id = v_transfer_id;

    IF v_status = 'RECEIVED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Transfer dispatch and receipt procedures work.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: Transfer receipt status is incorrect.');
    END IF;

    ROLLBACK TO before_transfer_lifecycle_test;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('SKIP: No approved transfer available.');
        ROLLBACK;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('FAIL: ' || SQLERRM);
END;
/


-- 13. TRANSFER STATUS REPORT
SELECT
    status,
    COUNT(*) AS transfer_count
FROM stock_transfers
GROUP BY status
ORDER BY transfer_count DESC;


-- 14. TRANSFER QUANTITY REPORT
SELECT
    st.transfer_id,
    sw.warehouse_name AS source_warehouse,
    dw.warehouse_name AS destination_warehouse,
    st.status,
    SUM(sti.quantity_requested) AS requested_quantity,
    SUM(sti.quantity_received) AS received_quantity,
    SUM(sti.quantity_requested - sti.quantity_received)
        AS outstanding_quantity
FROM stock_transfers st
JOIN warehouses sw
    ON st.source_warehouse_id = sw.warehouse_id
JOIN warehouses dw
    ON st.destination_warehouse_id = dw.warehouse_id
JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id
GROUP BY
    st.transfer_id,
    sw.warehouse_name,
    dw.warehouse_name,
    st.status
ORDER BY st.transfer_id;


-- 15. TRANSFER MOVEMENT HISTORY
SELECT
    sm.movement_id,
    sm.reference_id AS transfer_id,
    p.product_name,
    w.warehouse_name,
    sm.movement_type,
    sm.quantity,
    sm.movement_date
FROM stock_movements sm
JOIN inventory i
    ON sm.inventory_id = i.inventory_id
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE sm.movement_type IN ('TRANSFER_OUT', 'TRANSFER_IN')
ORDER BY sm.movement_date DESC;


-- 16. TRANSFER VALIDATION SUMMARY
SELECT
    COUNT(DISTINCT st.transfer_id) AS total_transfers,
    COUNT(sti.transfer_item_id) AS total_transfer_items,
    NVL(SUM(sti.quantity_requested), 0) AS total_requested,
    NVL(SUM(sti.quantity_received), 0) AS total_received
FROM stock_transfers st
LEFT JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id;