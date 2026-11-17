USE bakery_management;
GO

/*
    Bakery database tests
    Run this after create_tables.sql.

    These tests insert sample records. They do not delete existing records.
    Run against a development/test database, not a database containing
    important data.
*/

PRINT '1. Insert test roles';
INSERT INTO roles (role_name, [description])
VALUES
    ('Manager', 'Test manager role'),
    ('Cashier', 'Test cashier role'),
    ('Baker', 'Test baker role');

SELECT * FROM roles;


PRINT '2. Insert test employees';
INSERT INTO employees (full_name, username, password_hash, role_id)
VALUES
    ('Test Manager', 'test_manager', 'test_hash_not_for_real_auth', (SELECT role_id FROM roles WHERE role_name = 'Manager')),
    ('Test Cashier', 'test_cashier', 'test_hash_not_for_real_auth', (SELECT role_id FROM roles WHERE role_name = 'Cashier')),
    ('Test Baker', 'test_baker', 'test_hash_not_for_real_auth', (SELECT role_id FROM roles WHERE role_name = 'Baker'));

SELECT employee_id, full_name, username, role_id FROM employees;


PRINT '3. Insert test products and ingredients';
INSERT INTO products (product_name, product_size, selling_price)
VALUES
    ('Chocolate Banana Bread', 'Mini', 2500.00),
    ('Chocolate Banana Bread', 'Regular', 4500.00),
    ('Tigernut Drink', '30 cl', 1000.00);

SELECT * FROM products;

INSERT INTO ingredients (ingredient_name, unit_of_measure)
VALUES
    ('Flour', 'kg'),
    ('Sugar', 'kg'),
    ('Eggs', 'piece');

SELECT * FROM ingredients;



PRINT '4. Insert a test supplier';
INSERT INTO suppliers (supplier_name, phone, email_address)
VALUES ('Test Supplier', '08000000000', 'supplier@example.com');

select * from suppliers;



PRINT '5. Insert test recipes';
INSERT INTO recipes (quantity_required, unit_of_measure, product_id, ingredient_id)
VALUES
    (0.250, 'kg', (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'), (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Flour')),
    (0.100, 'kg', (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'), (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Sugar'));

SELECT * FROM recipes;

PRINT '6. Insert a test purchase and purchase item';
INSERT INTO purchases (supplier_id, employee_id, purchase_date, total_amount, purchase_status)
VALUES (
    (SELECT supplier_id FROM suppliers WHERE supplier_name = 'Test Supplier'),
    (SELECT employee_id FROM employees WHERE username = 'test_manager'),
    CAST(GETDATE() AS DATE),
    5000.00,
    'Received'
);
SELECT * FROM purchases;


INSERT INTO purchase_items (purchase_id, ingredient_id, quantity, unit_cost, line_total)
VALUES (
    (SELECT TOP (1) purchase_id FROM purchases ORDER BY purchase_id DESC),
    (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Flour'),
    2.000,
    2500.00,
    5000.00
);

SELECT * FROM purchase_items;


PRINT '7. Insert a production batch and ingredients used';
INSERT INTO production_batches
    (product_id, employee_id, production_date, quantity_produced, quantity_accepted, quantity_wasted, expiry_date)
VALUES (
    (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'),
    (SELECT employee_id FROM employees WHERE username = 'test_baker'),
    CAST(GETDATE() AS DATE),
    10, 9, 1, DATEADD(DAY, 3, CAST(GETDATE() AS DATE))
);
SELECT * FROM production_batches;

INSERT INTO batch_ingredients (production_id, ingredient_id, quantity_used, unit_cost)
VALUES (
    (SELECT TOP (1) production_id FROM production_batches ORDER BY production_id DESC),
    (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Flour'),
    1.500,
    2500.00
);
SELECT * FROM batch_ingredients;


PRINT '8. Insert a test order, order item and payment';
INSERT INTO orders (channel, order_status, order_date, total_amount, employee_id)
VALUES (
    'Walk-in',
    'Completed',
    SYSDATETIME(),
    5000.00,
    (SELECT employee_id FROM employees WHERE username = 'test_cashier')
);
SELECT * FROM orders;


INSERT INTO order_items (quantity, unit_price, total, order_id, product_id)
VALUES (
    2,
    2500.00,
    5000.00,
    (SELECT TOP (1) order_id FROM orders ORDER BY order_id DESC),
    (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini')
);
SELECT * FROM order_items;

INSERT INTO payments (order_id, employee_id, amount, payment_method, payment_status)
VALUES (
    (SELECT TOP (1) order_id FROM orders ORDER BY order_id DESC),
    (SELECT employee_id FROM employees WHERE username = 'test_cashier'),
    5000.00,
    'Cash',
    'Successful'
);
SELECT * FROM payments;

PRINT '9. Insert test inventory movements';
-- Ingredient received from supplier: positive quantity.
INSERT INTO inventory_movements
    (ingredient_id, product_id, employee_id, movement_type, quantity_change, reason)
VALUES (
    (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Flour'),
    NULL,
    (SELECT employee_id FROM employees WHERE username = 'test_manager'),
    'Purchase',
    2.000,
    'Test purchase received'
);

-- Finished products accepted from production: positive quantity.
INSERT INTO inventory_movements
    (ingredient_id, product_id, employee_id, movement_type, quantity_change, reason)
VALUES (
    NULL,
    (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'),
    (SELECT employee_id FROM employees WHERE username = 'test_baker'),
    'Production',
    9.000,
    'Test batch accepted'
);

-- Finished products sold: negative quantity.
INSERT INTO inventory_movements
    (ingredient_id, product_id, employee_id, movement_type, quantity_change, reason)
VALUES (
    NULL,
    (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'),
    (SELECT employee_id FROM employees WHERE username = 'test_cashier'),
    'Sale',
    -2.000,
    'Test order fulfilled'
);
SELECT * FROM inventory_movements;


PRINT '10. Insert an audit log and payment adjustment';
INSERT INTO audit_logs (audit_action, table_name, record_id, details, employee_id)
VALUES (
    'INSERT',
    'orders',
    (SELECT TOP (1) order_id FROM orders ORDER BY order_id DESC),
    'Test order created',
    (SELECT employee_id FROM employees WHERE username = 'test_cashier')
);
SELECT * FROM audit_logs;

INSERT INTO payment_adjustments
    (payment_id, approved_by, amount, adjustment_type, adjustment_date, reason)
VALUES (
    (SELECT TOP (1) payment_id FROM payments ORDER BY payment_id DESC),
    (SELECT employee_id FROM employees WHERE username = 'test_manager'),
    500.00,
    'Refund',
    SYSDATETIME(),
    'Test adjustment record; sample data only'
);

SELECT * FROM payment_adjustments;





PRINT '12. Check inventory movement rule: valid records should insert';
-- These two tests should fail due to the CHECK constraint.
-- TRY/CATCH lets the rest of the test script continue.

BEGIN TRY
    INSERT INTO inventory_movements
        (ingredient_id, product_id, employee_id, movement_type, quantity_change, reason)
    VALUES (
        (SELECT ingredient_id FROM ingredients WHERE ingredient_name = 'Flour'),
        (SELECT product_id FROM products WHERE product_name = 'Chocolate Banana Bread' AND product_size = 'Mini'),
        (SELECT employee_id FROM employees WHERE username = 'test_manager'),
        'Invalid test',
        1.000,
        'Expected failure: both IDs populated'
    );

    PRINT 'ERROR: Invalid movement with both IDs was accepted.';
END TRY
BEGIN CATCH
    PRINT 'PASS: Movement with both IDs populated was rejected.';
END CATCH;


BEGIN TRY
    INSERT INTO inventory_movements
        (ingredient_id, product_id, employee_id, movement_type, quantity_change, reason)
    VALUES (
        NULL,
        NULL,
        (SELECT employee_id FROM employees WHERE username = 'test_manager'),
        'Invalid test',
        1.000,
        'Expected failure: neither ID populated'
    );

    PRINT 'ERROR: Invalid movement with neither ID was accepted.';
END TRY
BEGIN CATCH
    PRINT 'PASS: Movement with neither ID populated was rejected.';
END CATCH;


PRINT '13. Check foreign key: nonexistent product should be rejected';
BEGIN TRY
    INSERT INTO order_items (quantity, unit_price, total, order_id, product_id)
    VALUES (
        1,
        1000.00,
        1000.00,
        (SELECT TOP (1) order_id FROM orders ORDER BY order_id DESC),
        -999
    );

    PRINT 'ERROR: Order item with nonexistent product was accepted.';
END TRY
BEGIN CATCH
    PRINT 'PASS: Order item with nonexistent product was rejected.';
END CATCH;

