-- ============================================================
-- INVENTORY & WAREHOUSE MANAGEMENT SYSTEM
-- STAGE 6.1: PL/SQL PROCEDURES
-- ============================================================


-- 1. RECEIVE PURCHASE ORDER ITEMS
CREATE OR REPLACE PROCEDURE receive_purchase_order (
    p_purchase_order_id IN NUMBER
)
AS
    v_status purchase_orders.status%TYPE;
    v_inventory_id inventory.inventory_id%TYPE;
    v_old_quantity inventory.quantity_on_hand%TYPE;
    v_old_cost inventory.average_unit_cost%TYPE;
    v_new_quantity NUMBER;
    v_new_cost NUMBER;
    v_received_any BOOLEAN := FALSE;
BEGIN
    SELECT status
    INTO v_status
    FROM purchase_orders
    WHERE purchase_order_id = p_purchase_order_id
    FOR UPDATE;

    IF v_status NOT IN ('APPROVED', 'PARTIALLY_RECEIVED') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Purchase order cannot be received.');
    END IF;

    FOR item_rec IN (
        SELECT
            poi.purchase_item_id,
            poi.product_id,
            poi.quantity_ordered,
            poi.quantity_received,
            poi.unit_cost,
            po.warehouse_id
        FROM purchase_order_items poi
        JOIN purchase_orders po
            ON poi.purchase_order_id = po.purchase_order_id
        WHERE poi.purchase_order_id = p_purchase_order_id
        FOR UPDATE OF poi.quantity_received
    )
    LOOP
        IF item_rec.quantity_received < item_rec.quantity_ordered THEN
            v_received_any := TRUE;

            SELECT inventory_id, quantity_on_hand, average_unit_cost
            INTO v_inventory_id, v_old_quantity, v_old_cost
            FROM inventory
            WHERE warehouse_id = item_rec.warehouse_id
              AND product_id = item_rec.product_id
            FOR UPDATE;

            v_new_quantity :=
                item_rec.quantity_ordered - item_rec.quantity_received;

            v_new_cost :=
                (
                    (v_old_quantity * v_old_cost) +
                    (v_new_quantity * item_rec.unit_cost)
                ) / NULLIF(v_old_quantity + v_new_quantity, 0);

            UPDATE inventory
            SET quantity_on_hand = quantity_on_hand + v_new_quantity,
                average_unit_cost = NVL(v_new_cost, item_rec.unit_cost),
                last_updated = SYSDATE
            WHERE inventory_id = v_inventory_id;

            UPDATE purchase_order_items
            SET quantity_received = quantity_ordered
            WHERE purchase_item_id = item_rec.purchase_item_id;

            INSERT INTO stock_movements (
                inventory_id,
                movement_type,
                quantity,
                reference_id,
                movement_date
            )
            VALUES (
                v_inventory_id,
                'PURCHASE_RECEIPT',
                v_new_quantity,
                p_purchase_order_id,
                SYSDATE
            );
        END IF;
    END LOOP;

    IF NOT v_received_any THEN
        RAISE_APPLICATION_ERROR(-20002, 'All purchase order items have already been received.');
    END IF;

    UPDATE purchase_orders
    SET status = 'RECEIVED'
    WHERE purchase_order_id = p_purchase_order_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Purchase order or inventory record not found.');
END;


-- 2. CONFIRM SALES ORDER AND RESERVE STOCK
CREATE OR REPLACE PROCEDURE confirm_sales_order (
    p_sales_order_id IN NUMBER
)
AS
    v_status sales_orders.status%TYPE;
    v_available_quantity NUMBER;
    v_inventory_id inventory.inventory_id%TYPE;
    v_is_active products.is_active%TYPE;
BEGIN
    SELECT status
    INTO v_status
    FROM sales_orders
    WHERE sales_order_id = p_sales_order_id
    FOR UPDATE;

    IF v_status <> 'DRAFT' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Only draft sales orders can be confirmed.');
    END IF;

    FOR item_rec IN (
        SELECT
            soi.product_id,
            soi.quantity,
            so.warehouse_id
        FROM sales_order_items soi
        JOIN sales_orders so
            ON soi.sales_order_id = so.sales_order_id
        WHERE soi.sales_order_id = p_sales_order_id
    )
    LOOP
        SELECT is_active
        INTO v_is_active
        FROM products
        WHERE product_id = item_rec.product_id;

        IF v_is_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Inactive products cannot be sold.');
        END IF;

        SELECT
            inventory_id,
            quantity_on_hand - quantity_reserved
        INTO
            v_inventory_id,
            v_available_quantity
        FROM inventory
        WHERE warehouse_id = item_rec.warehouse_id
          AND product_id = item_rec.product_id
        FOR UPDATE;

        IF v_available_quantity < item_rec.quantity THEN
            RAISE_APPLICATION_ERROR(-20012, 'Insufficient available stock.');
        END IF;

        UPDATE inventory
        SET quantity_reserved = quantity_reserved + item_rec.quantity,
            last_updated = SYSDATE
        WHERE inventory_id = v_inventory_id;
    END LOOP;

    UPDATE sales_orders
    SET status = 'CONFIRMED'
    WHERE sales_order_id = p_sales_order_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20013, 'Sales order, product or inventory record not found.');
END;

-- 3. FULFILL SALES ORDER
CREATE OR REPLACE PROCEDURE fulfill_sales_order (
    p_sales_order_id IN NUMBER
)
AS
    v_status sales_orders.status%TYPE;
    v_inventory_id inventory.inventory_id%TYPE;
    v_quantity_on_hand inventory.quantity_on_hand%TYPE;
    v_quantity_reserved inventory.quantity_reserved%TYPE;
BEGIN
    SELECT status
    INTO v_status
    FROM sales_orders
    WHERE sales_order_id = p_sales_order_id
    FOR UPDATE;

    IF v_status <> 'CONFIRMED' THEN
        RAISE_APPLICATION_ERROR(-20020, 'Only confirmed sales orders can be fulfilled.');
    END IF;

    FOR item_rec IN (
        SELECT
            soi.product_id,
            soi.quantity,
            so.warehouse_id
        FROM sales_order_items soi
        JOIN sales_orders so
            ON soi.sales_order_id = so.sales_order_id
        WHERE soi.sales_order_id = p_sales_order_id
    )
    LOOP
        SELECT
            inventory_id,
            quantity_on_hand,
            quantity_reserved
        INTO
            v_inventory_id,
            v_quantity_on_hand,
            v_quantity_reserved
        FROM inventory
        WHERE warehouse_id = item_rec.warehouse_id
          AND product_id = item_rec.product_id
        FOR UPDATE;

        IF v_quantity_on_hand < item_rec.quantity
           OR v_quantity_reserved < item_rec.quantity THEN
            RAISE_APPLICATION_ERROR(-20021, 'Invalid inventory quantity for fulfillment.');
        END IF;

        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - item_rec.quantity,
            quantity_reserved = quantity_reserved - item_rec.quantity,
            last_updated = SYSDATE
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
            'SALES_FULFILLMENT',
            item_rec.quantity,
            p_sales_order_id,
            SYSDATE
        );
    END LOOP;

    UPDATE sales_orders
    SET status = 'FULFILLED'
    WHERE sales_order_id = p_sales_order_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'Sales order or inventory record not found.');
END;


-- 4. CANCEL SALES ORDER AND RELEASE RESERVED STOCK
CREATE OR REPLACE PROCEDURE cancel_sales_order (
    p_sales_order_id IN NUMBER
)
AS
    v_status sales_orders.status%TYPE;
    v_inventory_id inventory.inventory_id%TYPE;
    v_quantity_reserved inventory.quantity_reserved%TYPE;
BEGIN
    SELECT status
    INTO v_status
    FROM sales_orders
    WHERE sales_order_id = p_sales_order_id
    FOR UPDATE;

    IF v_status NOT IN ('DRAFT', 'CONFIRMED') THEN
        RAISE_APPLICATION_ERROR(-20030, 'This sales order cannot be cancelled.');
    END IF;

    IF v_status = 'CONFIRMED' THEN
        FOR item_rec IN (
            SELECT
                soi.product_id,
                soi.quantity,
                so.warehouse_id
            FROM sales_order_items soi
            JOIN sales_orders so
                ON soi.sales_order_id = so.sales_order_id
            WHERE soi.sales_order_id = p_sales_order_id
        )
        LOOP
            SELECT inventory_id, quantity_reserved
            INTO v_inventory_id, v_quantity_reserved
            FROM inventory
            WHERE warehouse_id = item_rec.warehouse_id
              AND product_id = item_rec.product_id
            FOR UPDATE;

            IF v_quantity_reserved < item_rec.quantity THEN
                RAISE_APPLICATION_ERROR(-20031, 'Reserved stock is insufficient for cancellation.');
            END IF;

            UPDATE inventory
            SET quantity_reserved = quantity_reserved - item_rec.quantity,
                last_updated = SYSDATE
            WHERE inventory_id = v_inventory_id;
        END LOOP;
    END IF;

    UPDATE sales_orders
    SET status = 'CANCELLED'
    WHERE sales_order_id = p_sales_order_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'Sales order or inventory record not found.');
END;


-- 5. APPROVE STOCK TRANSFER
CREATE OR REPLACE PROCEDURE approve_stock_transfer (
    p_transfer_id IN NUMBER
)
AS
    v_status stock_transfers.status%TYPE;
BEGIN
    SELECT status
    INTO v_status
    FROM stock_transfers
    WHERE transfer_id = p_transfer_id
    FOR UPDATE;

    IF v_status <> 'DRAFT' THEN
        RAISE_APPLICATION_ERROR(-20040, 'Only draft transfers can be approved.');
    END IF;

    UPDATE stock_transfers
    SET status = 'APPROVED'
    WHERE transfer_id = p_transfer_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20041, 'Stock transfer not found.');
END;


-- 6. DISPATCH STOCK TRANSFER
CREATE OR REPLACE PROCEDURE dispatch_stock_transfer (
    p_transfer_id IN NUMBER
)
AS
    v_status stock_transfers.status%TYPE;
    v_inventory_id inventory.inventory_id%TYPE;
    v_quantity_on_hand inventory.quantity_on_hand%TYPE;
    v_quantity_reserved inventory.quantity_reserved%TYPE;
    v_source_warehouse_id stock_transfers.source_warehouse_id%TYPE;
BEGIN
    SELECT status, source_warehouse_id
    INTO v_status, v_source_warehouse_id
    FROM stock_transfers
    WHERE transfer_id = p_transfer_id
    FOR UPDATE;

    IF v_status <> 'APPROVED' THEN
        RAISE_APPLICATION_ERROR(-20050, 'Only approved transfers can be dispatched.');
    END IF;

    FOR item_rec IN (
        SELECT product_id, quantity_requested
        FROM stock_transfer_items
        WHERE transfer_id = p_transfer_id
    )
    LOOP
        SELECT
            inventory_id,
            quantity_on_hand,
            quantity_reserved
        INTO
            v_inventory_id,
            v_quantity_on_hand,
            v_quantity_reserved
        FROM inventory
        WHERE warehouse_id = v_source_warehouse_id
          AND product_id = item_rec.product_id
        FOR UPDATE;

        IF v_quantity_on_hand - v_quantity_reserved < item_rec.quantity_requested THEN
            RAISE_APPLICATION_ERROR(-20051, 'Insufficient available stock for transfer.');
        END IF;

        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - item_rec.quantity_requested,
            last_updated = SYSDATE
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
            'TRANSFER_OUT',
            item_rec.quantity_requested,
            p_transfer_id,
            SYSDATE
        );
    END LOOP;

    UPDATE stock_transfers
    SET status = 'IN_TRANSIT'
    WHERE transfer_id = p_transfer_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20052, 'Transfer or source inventory record not found.');
END;
/


-- 7. RECEIVE STOCK TRANSFER
-- Full receipt only: all requested quantities must be received.
CREATE OR REPLACE PROCEDURE receive_stock_transfer (
    p_transfer_id IN NUMBER
)
AS
    v_status stock_transfers.status%TYPE;
    v_source_warehouse_id stock_transfers.source_warehouse_id%TYPE;
    v_destination_warehouse_id stock_transfers.destination_warehouse_id%TYPE;
    v_source_cost inventory.average_unit_cost%TYPE;
    v_destination_inventory_id inventory.inventory_id%TYPE;
    v_destination_quantity inventory.quantity_on_hand%TYPE;
    v_destination_cost inventory.average_unit_cost%TYPE;
    v_new_cost NUMBER;
    v_transfer_cost NUMBER;
BEGIN
    SELECT
        status,
        source_warehouse_id,
        destination_warehouse_id
    INTO
        v_status,
        v_source_warehouse_id,
        v_destination_warehouse_id
    FROM stock_transfers
    WHERE transfer_id = p_transfer_id
    FOR UPDATE;

    IF v_status <> 'IN_TRANSIT' THEN
        RAISE_APPLICATION_ERROR(-20060, 'Only in-transit transfers can be received.');
    END IF;

    FOR item_rec IN (
        SELECT
            transfer_item_id,
            product_id,
            quantity_requested,
            quantity_received
        FROM stock_transfer_items
        WHERE transfer_id = p_transfer_id
        FOR UPDATE
    )
    LOOP
        IF item_rec.quantity_received <> 0 THEN
            RAISE_APPLICATION_ERROR(-20061, 'Transfer items have already been received.');
        END IF;

        SELECT average_unit_cost
        INTO v_source_cost
        FROM inventory
        WHERE warehouse_id = v_source_warehouse_id
          AND product_id = item_rec.product_id;

        BEGIN
            SELECT
                inventory_id,
                quantity_on_hand,
                average_unit_cost
            INTO
                v_destination_inventory_id,
                v_destination_quantity,
                v_destination_cost
            FROM inventory
            WHERE warehouse_id = v_destination_warehouse_id
              AND product_id = item_rec.product_id
            FOR UPDATE;

            v_transfer_cost := NVL(v_source_cost, 0);

            v_new_cost :=
                (
                    (v_destination_quantity * v_destination_cost) +
                    (item_rec.quantity_requested * v_transfer_cost)
                ) /
                NULLIF(
                    v_destination_quantity + item_rec.quantity_requested,
                    0
                );

            UPDATE inventory
            SET quantity_on_hand = quantity_on_hand + item_rec.quantity_requested,
                average_unit_cost = NVL(v_new_cost, v_transfer_cost),
                last_updated = SYSDATE
            WHERE inventory_id = v_destination_inventory_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO inventory (
                    warehouse_id,
                    product_id,
                    quantity_on_hand,
                    quantity_reserved,
                    average_unit_cost,
                    last_updated
                )
                VALUES (
                    v_destination_warehouse_id,
                    item_rec.product_id,
                    item_rec.quantity_requested,
                    0,
                    NVL(v_source_cost, 0),
                    SYSDATE
                )
                RETURNING inventory_id INTO v_destination_inventory_id;
        END;

        UPDATE stock_transfer_items
        SET quantity_received = quantity_requested
        WHERE transfer_item_id = item_rec.transfer_item_id;

        INSERT INTO stock_movements (
            inventory_id,
            movement_type,
            quantity,
            reference_id,
            movement_date
        )
        VALUES (
            v_destination_inventory_id,
            'TRANSFER_IN',
            item_rec.quantity_requested,
            p_transfer_id,
            SYSDATE
        );
    END LOOP;

    UPDATE stock_transfers
    SET status = 'RECEIVED'
    WHERE transfer_id = p_transfer_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20062, 'Transfer or inventory record not found.');
END;
