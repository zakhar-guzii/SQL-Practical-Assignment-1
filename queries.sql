use ecommerce_db;

-- 1. select joining 5 tables

select
    c.first_name,
    c.last_name,
    p.name as product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) as total_item_amount,
    s.name as supplier_name,
    s.rating as supplier_rating,
    o.order_date,
    o.status
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join suppliers s on p.supplier_id = s.supplier_id
order by o.order_date desc;

-- addition: union

-- Таблиця замовлень, потребуючих додаткової уваги
select order_id, customer_id, order_date, status
from orders
where status  = 'Pending'
union
select order_id, customer_id, order_date, status
from orders
where status = 'Canceled';

-- CTEs, order by, where

-- Знайти покупців, що входить в топ 30% за витраченими коштами
with cust_totals as(
    select customer_id, sum(total_amount) as total_spend,
    count(*) as orders_count
    from orders
    group by customer_id
),
best_buyers as(
    select customer_id,
           total_spend,
           orders_count,
           percent_rank() over (order by total_spend desc) as rp
    from cust_totals
)
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    bb.total_spend,
    bb.orders_count
from customers c
inner join best_buyers bb
on bb.customer_id = c.customer_id
where rp <=0.3
order by bb.total_spend desc;

-- subquery


