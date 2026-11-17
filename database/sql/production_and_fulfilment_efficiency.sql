-- Production and Fulfilment Efficiency

-- Batch vs made-to-order production
select
    production_type,
    count(*) as production_runs,
    sum(quantity_produced) as total_quantity_produced,
    sum(quantity_accepted) as total_quantity_accepted,
    sum(quantity_wasted) as total_quantity_wasted
from production_batches
group by production_type
order by total_quantity_produced desc;

-- How does production volume compare with sales demand?
select
    p.product_name,
    sum(oi.quantity) as total_quantity_sold
from orders o
join order_items oi
    on o.order_id = oi.order_id
join products p
    on oi.product_id = p.product_id
where o.order_status = 'COMPLETED'
group by p.product_name
order by total_quantity_sold desc;

-- total_quantity_accepted
select
    p.product_name,
    sum(pb.quantity_produced) as total_quantity_produced,
    sum(pb.quantity_accepted) as total_quantity_accepted,
    sum(pb.quantity_wasted) as total_quantity_wasted
from production_batches pb
join products p
    on pb.product_id = p.product_id
group by p.product_name
order by total_quantity_accepted desc;

-- Are there batches with unusually high ingredient usage or rejected output?

-- identify unusually high ingredient usage by batch
select
    p.product_name,
    i.ingredient_name,
    i.unit_of_measure,
    count(*) as batches_recorded,
    cast(min(bi.quantity_used / nullif(pb.quantity_produced, 0))
        as decimal(12,4)) as lowest_usage_per_unit,
    cast(avg(bi.quantity_used / nullif(pb.quantity_produced, 0))
        as decimal(12,4)) as average_usage_per_unit,
    cast(max(bi.quantity_used / nullif(pb.quantity_produced, 0))
        as decimal(12,4)) as highest_usage_per_unit
from production_batches pb
join batch_ingredients bi
    on pb.production_id = bi.production_id
join products p
    on pb.product_id = p.product_id
join ingredients i
    on bi.ingredient_id = i.ingredient_id
where pb.quantity_produced > 0
group by
    p.product_name,
    i.ingredient_name,
    i.unit_of_measure
having count(*) > 1
order by
    max(bi.quantity_used / nullif(pb.quantity_produced, 0))
    - min(bi.quantity_used / nullif(pb.quantity_produced, 0)) desc;

-- which products have the highest rejection or waste rates?
select
    p.product_name,
    count(*) as production_runs,
    sum(pb.quantity_produced) as total_produced,
    sum(pb.quantity_accepted) as total_accepted,
    sum(pb.quantity_wasted) as total_wasted,
    cast(
        sum(pb.quantity_wasted) * 100.0
        / nullif(sum(pb.quantity_produced), 0)
        as decimal(5,2)
    ) as waste_rate_percentage
from production_batches pb
join products p
    on pb.product_id = p.product_id
group by p.product_name
order by waste_rate_percentage desc;

-- Audit logs
select
    table_name,
    audit_action,
    count(*) as total_records,
    min(time_stamp) as first_recorded,
    max(time_stamp) as last_recorded
from audit_logs
group by
    table_name,
    audit_action
order by table_name, total_records desc;