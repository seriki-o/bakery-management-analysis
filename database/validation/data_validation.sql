
/* Duplicate transaction codes
Expected output; No rows returned */
select order_code, count(*) as total
from orders
group by order_code
having count(*) > 1;

/* Check for missing values
Expected output; No rows returned */
select *
from orders
where order_date is null
   or total_amount is null;

/* Check for invalid values
Expected output; No rows returned */
select *
from products
where selling_price < 0;

select *
from order_items
where quantity <= 0
   or unit_price < 0;

/* Check for orphan records
Expected output; No rows returned */
select oi.*
from order_items oi
left join orders o
    on oi.order_id = o.order_id
left join products p
    on oi.product_id = p.product_id
where o.order_id is null
   or p.product_id is null;

/* Check whether order totals match their items
Expected output; No rows returned */
select
    o.order_id,
    o.total_amount,
    sum(oi.quantity * oi.unit_price) as calculated_total
from orders o
join order_items oi
    on o.order_id = oi.order_id
group by o.order_id, o.total_amount
having abs(o.total_amount - sum(oi.quantity * oi.unit_price)) > 0.01;

/* Check for duplicate order items
Expected output; No rows returned */
select order_id, product_id, count(*) as total
from order_items
group by order_id, product_id
having count(*) > 1;

