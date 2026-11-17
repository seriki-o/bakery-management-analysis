-- Inventory and procurement Analysis

-- Which ingredients are consumed most quickly?
select
    i.ingredient_name,
    i.unit_of_measure,
    sum(abs(im.quantity_change)) as total_quantity_consumed
from inventory_movements im
join ingredients i
    on im.ingredient_id = i.ingredient_id
where im.movement_type = 'Production Consumption'
group by
    i.ingredient_name,
    i.unit_of_measure
order by total_quantity_consumed desc;

    -- Average monthly consumption
    select
    i.ingredient_name,
    i.unit_of_measure,
    round(sum(abs(im.quantity_change)) / 6.0, 2)
        as average_monthly_consumption
    from inventory_movements im
    join ingredients i
        on im.ingredient_id = i.ingredient_id
    where im.movement_type = 'Production Consumption'
    group by
        i.ingredient_name,
        i.unit_of_measure
    order by average_monthly_consumption desc;

-- Which ingredients are purchased most often and at what prices?

-- Purchase frequency and spending by ingredient
select
    i.ingredient_name,
    i.unit_of_measure,
    count(distinct p.purchase_id) as purchase_frequency,
    sum(pi.quantity) as total_quantity_purchased,
    cast(round(sum(pi.line_total), 2) as decimal(12,2))
        as total_spent
from purchase_items pi
join purchases p
    on pi.purchase_id = p.purchase_id
join ingredients i
    on pi.ingredient_id = i.ingredient_id
where p.purchase_status = 'RECEIVED'
group by
    i.ingredient_name,
    i.unit_of_measure
order by purchase_frequency desc;

    -- Average purchase prices by ingredient
    select
        i.ingredient_name,
        i.unit_of_measure,
        sum(pi.quantity) as total_quantity_purchased,
        cast(round(
            sum(pi.line_total) / nullif(sum(pi.quantity), 0), 2
        ) as decimal(12,2)) as weighted_average_unit_price,
        min(pi.unit_cost) as lowest_unit_price,
        max(pi.unit_cost) as highest_unit_price
    from purchase_items pi
    join purchases p
        on pi.purchase_id = p.purchase_id
    join ingredients i
        on pi.ingredient_id = i.ingredient_id
    where p.purchase_status = 'RECEIVED'
    group by
        i.ingredient_name,
        i.unit_of_measure
    order by weighted_average_unit_price desc;

    -- monthly purchase price trends
    select
        i.ingredient_name,
        year(p.purchase_date) as purchase_year,
        month(p.purchase_date) as purchase_month,
        sum(pi.quantity) as quantity_purchased,
        cast(round(
            sum(pi.line_total) / nullif(sum(pi.quantity), 0), 2
        ) as decimal(12,2)) as average_unit_price
    from purchase_items pi
    join purchases p
        on pi.purchase_id = p.purchase_id
    join ingredients i
        on pi.ingredient_id = i.ingredient_id
    where p.purchase_status = 'RECEIVED'
    group by
        i.ingredient_name,
        year(p.purchase_date),
        month(p.purchase_date)
    order by
        i.ingredient_name,
        purchase_year,
        purchase_month;


-- Are there ingredients that repeatedly fall below a sensible stock threshold?
select
    i.ingredient_name,
    i.unit_of_measure,
    sum(im.quantity_change) as current_stock
from ingredients i
left join inventory_movements im
    on i.ingredient_id = im.ingredient_id
group by
    i.ingredient_name,
    i.unit_of_measure
order by current_stock asc;


-- Are purchases aligned with actual consumption?

-- Monthly purchases vs production consumption
select
    i.ingredient_name,
    i.unit_of_measure,
    year(im.[date]) as movement_year,
    month(im.[date]) as movement_month,

    sum(case
        when im.movement_type = 'Purchase Receipt'
        then im.quantity_change
        else 0
    end) as quantity_received,

    sum(case
        when im.movement_type = 'Production Consumption'
        then abs(im.quantity_change)
        else 0
    end) as quantity_consumed,

    sum(case
        when im.movement_type = 'Purchase Receipt'
        then im.quantity_change
        when im.movement_type = 'Production Consumption'
        then im.quantity_change
        else 0
    end) as net_purchase_consumption_difference

from inventory_movements im
join ingredients i
    on im.ingredient_id = i.ingredient_id
where im.movement_type in (
    'Purchase Receipt',
    'Production Consumption'
)
group by
    i.ingredient_name,
    i.unit_of_measure,
    year(im.[date]),
    month(im.[date])
order by
    i.ingredient_name,
    movement_year,
    movement_month;

    -- Overall purchases vs production consumption
select
    i.ingredient_name,
    i.unit_of_measure,

    sum(case
        when im.movement_type = 'Purchase Receipt'
        then im.quantity_change
        else 0
    end) as total_quantity_received,

    sum(case
        when im.movement_type = 'Production Consumption'
        then abs(im.quantity_change)
        else 0
    end) as total_quantity_consumed,

    sum(case
        when im.movement_type = 'Purchase Receipt'
        then im.quantity_change
        when im.movement_type = 'Production Consumption'
        then im.quantity_change
        else 0
    end) as net_difference

from inventory_movements im
join ingredients i
    on im.ingredient_id = i.ingredient_id
where im.movement_type in (
    'Purchase Receipt',
    'Production Consumption'
)
group by
    i.ingredient_name,
    i.unit_of_measure
order by net_difference asc;


-- Are there unusual stock adjustments, wastage or unexplained movements?

-- Summarise the other movement types
select
    movement_type,
    count(*) as movement_count,
    sum(quantity_change) as total_quantity_change,
    sum(abs(quantity_change)) as total_movement_volume
from inventory_movements
where movement_type not in (
    'Purchase Receipt',
    'Production Consumption'
)
group by movement_type
order by movement_count desc;

-- Analyse waste by product
select
    p.product_name,
    count(*) as waste_records,
    sum(abs(im.quantity_change)) as total_quantity_wasted,
    min(im.[date]) as first_recorded_waste,
    max(im.[date]) as last_recorded_waste
from inventory_movements im
join products p
    on im.product_id = p.product_id
where im.movement_type = 'Production Waste'
group by
    p.product_name
order by total_quantity_wasted desc;

select
    movement_type,
    count(*) as movement_count,
    count(distinct reason) as distinct_reasons,
    sum(quantity_change) as total_quantity_change,
    sum(case
        when reason is null or ltrim(rtrim(reason)) = ''
        then 1
        else 0
    end) as missing_reasons
from inventory_movements
group by movement_type
order by movement_count desc;