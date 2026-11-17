
USE bakery_management;
GO

-- Drop existing tables in dependency order
DROP TABLE IF EXISTS payment_adjustments;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS inventory_movements;
DROP TABLE IF EXISTS batch_ingredients;
DROP TABLE IF EXISTS production_batches;
DROP TABLE IF EXISTS purchase_items;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS recipes;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS ingredients;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS roles;
GO

-- Products table
CREATE TABLE products(
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_name NVARCHAR(50) NOT NULL,
    product_size NVARCHAR(10) NOT NULL,
    selling_price DECIMAL(12,2) NOT NULL,
    is_active BIT DEFAULT 1
);

-- Roles table
CREATE TABLE roles(
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL,
    [description] VARCHAR(255) NOT NULL
);

-- Employees table
CREATE TABLE employees(
    employee_id INT IDENTITY(1000,10) PRIMARY KEY,
    full_name NVARCHAR(50) NOT NULL,
    username NVARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BIT DEFAULT 1,
    role_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

-- Ingredients table
CREATE TABLE ingredients(
    ingredient_id INT IDENTITY(1,1) PRIMARY KEY,
    ingredient_name NVARCHAR(50) NOT NULL,
    unit_of_measure NVARCHAR(15) NOT NULL,
    is_active BIT DEFAULT 1
);

-- Suppliers table
CREATE TABLE suppliers(
    supplier_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name NVARCHAR(50) NOT NULL,
    phone NVARCHAR(25) NOT NULL,
    email_address VARCHAR(254) NOT NULL
);

-- Recipes table
CREATE TABLE recipes(
    recipe_id INT IDENTITY(1,1) PRIMARY KEY,
    quantity_required DECIMAL(10,3) NOT NULL,
    unit_of_measure NVARCHAR(25) NOT NULL,
    is_active BIT DEFAULT 1,
    product_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);

-- Audit logs table
CREATE TABLE audit_logs(
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    audit_action NVARCHAR(50) NOT NULL,
    table_name NVARCHAR(50) NOT NULL,
    record_id INT,
    details NVARCHAR(500),
    employee_id INT NOT NULL,
    time_stamp DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Expenses table
CREATE TABLE expenses(
    expense_id INT IDENTITY(1,1) PRIMARY KEY,
    category NVARCHAR(50) NOT NULL,
    [description] NVARCHAR(255),
    [date] DATE,
    amount DECIMAL(12,2),
    employee_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Orders table
CREATE TABLE orders(
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    channel NVARCHAR(50) NOT NULL,
    order_status NVARCHAR(25),
    order_date DATE,
    total_amount DECIMAL(12,2),
    employee_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Order items table
CREATE TABLE order_items(
    order_item_id INT IDENTITY(1,1) PRIMARY KEY,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2),
    total DECIMAL(12,2),
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Purchases table
CREATE TABLE purchases(
    purchase_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id INT NOT NULL,
    employee_id INT NOT NULL,
    purchase_date DATE,
    total_amount DECIMAL(12,2),
    purchase_status NVARCHAR(25),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    delivery_date DATE
);

-- Purchase items table
CREATE TABLE purchase_items(
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    purchase_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    unit_cost DECIMAL(12,2),
    line_total DECIMAL(12,2),
    FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);

-- Production batches table
CREATE TABLE production_batches(
    production_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    production_type NVARCHAR(30) NOT NULL,
    employee_id INT NOT NULL,
    production_date DATE,
    quantity_produced INT NOT NULL,
    quantity_accepted INT NOT NULL,
    quantity_wasted INT NOT NULL,
    expiry_date DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Batch ingredients table
CREATE TABLE batch_ingredients(
    batch_ingredient_id INT IDENTITY(1,1) PRIMARY KEY,
    production_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity_used DECIMAL(10,3) NOT NULL,
    unit_cost DECIMAL(12,2),
    FOREIGN KEY (production_id) REFERENCES production_batches(production_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);

-- Inventory movements table
CREATE TABLE inventory_movements(
    movement_id INT IDENTITY(1,1) PRIMARY KEY,
    ingredient_id INT,
    product_id INT,
    employee_id INT NOT NULL,
    movement_type NVARCHAR(30) NOT NULL,
    quantity_change DECIMAL(10,3) NOT NULL,
    [date] DATETIME2 DEFAULT SYSDATETIME(),
    reason NVARCHAR(255),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CHECK (
        (ingredient_id IS NOT NULL AND product_id IS NULL)
        OR
        (ingredient_id IS NULL AND product_id IS NOT NULL)
    )
);

-- Payments table
CREATE TABLE payments(
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    employee_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method NVARCHAR(30) NOT NULL,
    payment_status NVARCHAR(25) NOT NULL,
    [date] DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Payment adjustments table
CREATE TABLE payment_adjustments(
    adjustment_id INT IDENTITY(1,1) PRIMARY KEY,
    payment_id INT NOT NULL,
    approved_by INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    adjustment_type NVARCHAR(30) NOT NULL,
    adjustment_date DATETIME2 DEFAULT SYSDATETIME(),
    reason NVARCHAR(255) NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
    FOREIGN KEY (approved_by) REFERENCES employees(employee_id)
);
GO




