-- Product Performance & profitability

-- Bestselling products
select top 20
    p.product_name,
    p.product_size,
    sum(oi.quantity) as units_sold,
    round(sum(oi.quantity * oi.unit_price), 2) as total_revenue
from order_items oi
join orders o
    on oi.order_id = o.order_id
join products p
    on oi.product_id = p.product_id
where o.order_status <> 'CANCELLED'
group by
    p.product_name,
    p.product_size
order by total_revenue desc;

--Products that sell frequently but generate relatively little revenue
select top 20
    p.product_name,
    p.product_size,
    sum(oi.quantity) as units_sold,
    round(sum(oi.quantity * oi.unit_price), 2) as total_revenue,
    round(
        sum(oi.quantity * oi.unit_price) / nullif(sum(oi.quantity), 0),
        2
    ) as average_selling_price
from order_items oi
join orders o
    on oi.order_id = o.order_id
join products p
    on oi.product_id = p.product_id
where o.order_status <> 'CANCELLED'
group by
    p.product_name,
    p.product_size
order by units_sold desc;

-- Compare flavours
select
    p.product_name,
    sum(oi.quantity) as units_sold,
    round(sum(oi.quantity * oi.unit_price), 2) as total_revenue
from order_items oi
join orders o
    on oi.order_id = o.order_id
join products p
    on oi.product_id = p.product_id
where o.order_status <> 'CANCELLED'
group by p.product_name
order by total_revenue desc;

-- Compare sizes
select
    p.product_size,
    sum(oi.quantity) as units_sold,
    round(sum(oi.quantity * oi.unit_price), 2) as total_revenue,
    round(
        sum(oi.quantity * oi.unit_price) * 1.0
        / nullif(sum(oi.quantity), 0),
        2
    ) as average_selling_price
from order_items oi
join orders o
    on oi.order_id = o.order_id
join products p
    on oi.product_id = p.product_id
where o.order_status <> 'CANCELLED'
group by p.product_size
order by total_revenue desc;

-- Estimated production cost and profitability
select
    p.product_name,
    p.product_size,
    sum(bi.quantity_used * bi.unit_cost) as ingredient_cost,
    sum(pb.quantity_accepted) as accepted_units,
    sum(pb.quantity_wasted) as wasted_units,
    cast(round(
        sum(bi.quantity_used * bi.unit_cost)
        / nullif(sum(pb.quantity_accepted), 0), 2
    ) as decimal(12,2)) as ingredient_cost_per_accepted_unit
from production_batches pb
join products p
    on pb.product_id = p.product_id
join batch_ingredients bi
    on pb.production_id = bi.production_id
group by
    p.product_name,
    p.product_size
order by ingredient_cost desc;

-- Compare selling price with ingredient cost
with ingredient_costs as (
    select
        ingredient_id,
        avg(unit_cost) as average_unit_cost
    from batch_ingredients
    group by ingredient_id
),
recipe_costs as (
    select
        p.product_id,
        p.product_name,
        p.product_size,
        p.selling_price,
        sum(r.quantity_required * ic.average_unit_cost) as estimated_ingredient_cost
    from recipes r
    join products p
        on r.product_id = p.product_id
    join ingredient_costs ic
        on r.ingredient_id = ic.ingredient_id
    where r.is_active = 1
    group by
        p.product_id,
        p.product_name,
        p.product_size,
        p.selling_price
)
select
    product_name,
    product_size,
    selling_price,
    cast(round(estimated_ingredient_cost, 2) as decimal(12,2))
        as estimated_ingredient_cost,
    cast(round(selling_price - estimated_ingredient_cost, 2) as decimal(12,2))
        as estimated_ingredient_margin,
    cast(round(
        100.0 * (selling_price - estimated_ingredient_cost)
        / nullif(selling_price, 0), 2
    ) as decimal(12,2)) as estimated_ingredient_margin_pct
from recipe_costs
order by estimated_ingredient_margin_pct;