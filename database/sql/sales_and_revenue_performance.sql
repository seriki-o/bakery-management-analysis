-- SALES AND REVENUE PERFORMANCE

select * from orders;
select * from purchases;
select * from expenses;
select * from production_batches;
select * from batch_ingredients;
select * from payments;

-- Gross sales
select
    sum(oi.quantity * oi.unit_price) as gross_sales
from order_items oi
join orders o
    on oi.order_id = o.order_id
where o.order_status <> 'CANCELLED';

--Units sold
select
    sum(oi.quantity) as units_sold
from order_items oi
join orders o
    on oi.order_id = o.order_id;

-- Average order value
select
    cast(
        round(
            sum(total_amount) * 1.0 / nullif(count(order_id), 0),
            2
        ) as decimal(12, 2)
    ) as average_order_value
from orders
where order_status = 'COMPLETED';

--How are sales and revenue changing over the six-month period? 
select
    month(o.order_date) as [month],
    count(o.order_id) as total_orders,
    sum(o.total_amount) as total_revenue,
    cast(round(avg(o.total_amount), 2) as decimal(12, 2)) as average_revenue,
    cast(round(coalesce(p.production_cost, 0), 2) as decimal(12, 2)) as production_cost,
    coalesce(e.operating_expenses, 0) as operating_expenses,
    coalesce(p.production_cost, 0) +
        coalesce(e.operating_expenses, 0) as total_costs,
    sum(o.total_amount) -
        coalesce(p.production_cost, 0) -
        coalesce(e.operating_expenses, 0) as estimated_profit
from orders o
left join (
    select
        month(pb.production_date) as [month],
        sum(bi.quantity_used * bi.unit_cost) as production_cost
    from production_batches pb
    join batch_ingredients bi
        on pb.production_id = bi.production_id
    group by month(pb.production_date)
) p on month(o.order_date) = p.[month]
left join (
    select
        month([date]) as [month],
        sum(amount) as operating_expenses
    from expenses
    group by month([date])
) e on month(o.order_date) = e.[month]
group by
    month(o.order_date),
    p.production_cost,
    e.operating_expenses
order by [month];

-- Which products, sizes and varieties generate the most revenue?
select
    p.product_name,
    p.product_size,
    sum(oi.quantity) as units_sold,
    sum(oi.total) as total_revenue
from orders o
join order_items oi on oi.order_id = o.order_id
join products p on p.product_id = oi.product_id
where o.order_date >= '2026-01-01'
  and o.order_date < '2026-07-01'
  and lower(o.order_status) not in ('cancelled', 'canceled')
group by p.product_name, p.product_size
order by total_revenue desc;

-- How do online and walk-in sales compare
select
    o.channel,
    count(*) as total_orders,
    sum(o.total_amount) as gross_revenue,
    cast(avg(o.total_amount) as decimal(12, 2)) as average_order_value
from dbo.orders o
where o.order_date >= '2026-01-01'
  and o.order_date < '2026-07-01'
  and lower(o.order_status) not in ('cancelled', 'canceled')
group by o.channel
order by gross_revenue desc;


-- What are the busiest days, weeks and periods?

    --Daily Sales
    select
    o.order_date,
    count(*) as total_orders,
    sum(o.total_amount) as daily_revenue
    from dbo.orders o
    where o.order_date >= '2026-01-01'
      and o.order_date < '2026-07-01'
      and lower(o.order_status) not in ('cancelled', 'canceled')
    group by o.order_date
    order by total_orders desc;

    --Weekly Sales
    select
    year(o.order_date) as sales_year,
    datepart(iso_week, o.order_date) as sales_week,
    count(*) as total_orders,
    sum(o.total_amount) as weekly_revenue
    from dbo.orders o
    where o.order_date >= '2026-01-01'
      and o.order_date < '2026-07-01'
      and lower(o.order_status) not in ('cancelled', 'canceled')
    group by year(o.order_date), datepart(iso_week, o.order_date)
    order by total_orders desc;

-- How do discounts, cancellations and refunds affect net sales?
   --completed orders
   select
        lower(o.order_status) as order_status,
        count(*) as total_orders,
        sum(o.total_amount) as order_value
    from dbo.orders o
    where o.order_date >= '2026-01-01'
      and o.order_date < '2026-07-01'
    group by lower(o.order_status)
    order by total_orders desc;

    --Refunds
    select
        pa.adjustment_type,
        count(*) as total_adjustments,
        sum(pa.amount) as total_adjustment_amount
    from dbo.payment_adjustments pa
    where pa.adjustment_date >= '2026-01-01'
      and pa.adjustment_date < '2026-07-01'
    group by pa.adjustment_type
    order by total_adjustment_amount desc;

