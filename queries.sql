use ecommerce_db;

-- select joining 5 tables

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

-- union


