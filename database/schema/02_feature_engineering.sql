USE bakery_management;
GO


-- Feature enginerring to add easily readable codes 

ALTER TABLE dbo.products ADD product_code VARCHAR(20) NULL;
ALTER TABLE dbo.ingredients ADD ingredient_code VARCHAR(20) NULL;
ALTER TABLE dbo.orders ADD order_code VARCHAR(30) NULL;
ALTER TABLE dbo.production_batches ADD batch_code VARCHAR(30) NULL;
ALTER TABLE dbo.purchases ADD purchase_code VARCHAR(30) NULL;
ALTER TABLE dbo.recipes ADD recipe_code VARCHAR(20) NULL;
ALTER TABLE dbo.inventory_movements ADD movement_code VARCHAR(30) NULL;
ALTER TABLE dbo.payments ADD payment_code VARCHAR(30) NULL;
ALTER TABLE dbo.expenses ADD expense_code VARCHAR(30) NULL;
ALTER TABLE dbo.order_items ADD order_item_code VARCHAR(20) NULL;
ALTER TABLE dbo.purchase_items ADD purchase_item_code VARCHAR(20) NULL;
ALTER TABLE dbo.batch_ingredients ADD batch_ingredient_code VARCHAR(20) NULL;
ALTER TABLE dbo.payment_adjustments ADD adjustment_code VARCHAR(20) NULL;
ALTER TABLE dbo.audit_logs ADD audit_code VARCHAR(20) NULL;
GO



SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @CodeMap TABLE (
        table_name  SYSNAME,
        pk_column   SYSNAME,
        code_column SYSNAME,
        code_prefix VARCHAR(5),
        date_column SYSNAME NULL
    );

    INSERT INTO @CodeMap VALUES
        ('products',            'product_id',         'product_code',           'PRD-', NULL),
        ('ingredients',         'ingredient_id',      'ingredient_code',        'ING-', NULL),
        ('orders',              'order_id',            'order_code',             'ORD-', 'order_date'),
        ('production_batches',  'production_id',       'batch_code',             'BAT-', 'production_date'),
        ('purchases',           'purchase_id',         'purchase_code',          'PUR-', 'purchase_date'),
        ('recipes',             'recipe_id',           'recipe_code',            'REC-', NULL),
        ('inventory_movements', 'movement_id',         'movement_code',          'MOV-', 'date'),
        ('payments',            'payment_id',          'payment_code',           'PAY-', 'date'),
        ('expenses',            'expense_id',          'expense_code',           'EXP-', 'date'),
        ('order_items',         'order_item_id',       'order_item_code',        'OIT-', NULL),
        ('purchase_items',      'item_id',             'purchase_item_code',     'PIT-', NULL),
        ('batch_ingredients',   'batch_ingredient_id', 'batch_ingredient_code', 'BLI-', NULL),
        ('payment_adjustments', 'adjustment_id',       'adjustment_code',        'ADJ-', NULL),
        ('audit_logs',          'audit_id',            'audit_code',             'AUD-', NULL);

    DECLARE
        @Table SYSNAME,
        @PK SYSNAME,
        @Code SYSNAME,
        @Prefix VARCHAR(5),
        @Date SYSNAME,
        @SQL NVARCHAR(MAX);

    DECLARE code_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT table_name, pk_column, code_column,
               code_prefix, date_column
        FROM @CodeMap;

    OPEN code_cursor;

    FETCH NEXT FROM code_cursor
    INTO @Table, @PK, @Code, @Prefix, @Date;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Stop if a transaction date is missing.
        IF @Date IS NOT NULL
        BEGIN
            SET @SQL =
                N'IF EXISTS (
                    SELECT 1 FROM dbo.' + QUOTENAME(@Table) +
                N' WHERE ' + QUOTENAME(@Date) + N' IS NULL
                )
                THROW 50001, ''Missing transaction date in ' +
                REPLACE(@Table, '''', '''''') +
                N'. No migration should continue.'', 1;';

            EXEC sys.sp_executesql @SQL;
        END;

        IF @Date IS NULL
        BEGIN
            SET @SQL = N'
                ;WITH Numbered AS (
                    SELECT ' + QUOTENAME(@PK) + N' AS record_id,
                           ROW_NUMBER() OVER (
                               ORDER BY ' + QUOTENAME(@PK) + N'
                           ) AS seq
                    FROM dbo.' + QUOTENAME(@Table) + N'
                )
                UPDATE t
                SET ' + QUOTENAME(@Code) + N' =
                    @Prefix +
                    CASE WHEN n.seq < 1000
                         THEN RIGHT(''000'' + CONVERT(VARCHAR(20), n.seq), 3)
                         ELSE CONVERT(VARCHAR(20), n.seq)
                    END
                FROM dbo.' + QUOTENAME(@Table) + N' AS t
                JOIN Numbered AS n
                  ON t.' + QUOTENAME(@PK) + N' = n.record_id;';

            EXEC sys.sp_executesql
                @SQL, N'@Prefix VARCHAR(5)', @Prefix;
        END
        ELSE
        BEGIN
            SET @SQL = N'
                ;WITH Numbered AS (
                    SELECT ' + QUOTENAME(@PK) + N' AS record_id,
                           YEAR(' + QUOTENAME(@Date) + N') AS txn_year,
                           ROW_NUMBER() OVER (
                               PARTITION BY YEAR(' + QUOTENAME(@Date) + N')
                               ORDER BY ' + QUOTENAME(@PK) + N'
                           ) AS seq
                    FROM dbo.' + QUOTENAME(@Table) + N'
                )
                UPDATE t
                SET ' + QUOTENAME(@Code) + N' =
                    @Prefix +
                    CONVERT(VARCHAR(4), n.txn_year) + ''-'' +
                    CASE WHEN n.seq < 1000
                         THEN RIGHT(''000'' + CONVERT(VARCHAR(20), n.seq), 3)
                         ELSE CONVERT(VARCHAR(20), n.seq)
                    END
                FROM dbo.' + QUOTENAME(@Table) + N' AS t
                JOIN Numbered AS n
                  ON t.' + QUOTENAME(@PK) + N' = n.record_id;';

            EXEC sys.sp_executesql
                @SQL, N'@Prefix VARCHAR(5)', @Prefix;
        END;

        FETCH NEXT FROM code_cursor
        INTO @Table, @PK, @Code, @Prefix, @Date;
    END;

    CLOSE code_cursor;
    DEALLOCATE code_cursor;

    COMMIT TRANSACTION;

    PRINT 'All 14 custom-code columns updated successfully.';

END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'code_cursor') >= 0
        CLOSE code_cursor;

    IF CURSOR_STATUS('local', 'code_cursor') > -3
        DEALLOCATE code_cursor;

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO