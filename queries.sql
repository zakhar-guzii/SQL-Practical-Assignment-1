use ecommerce_db;


-- без union all, +- легкий для розуміння

with cust_totals as (select customer_id,
                            sum(total_amount) as total_spend,
                            count(*)          as orders_count
                     from orders
                     group by customer_id),
     best_buyers as (select customer_id,
                            total_spend,
                            orders_count,
                            percent_rank() over (order by total_spend desc) as rp
                     from cust_totals)
select c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       bb.total_spend,
       bb.orders_count
from customers c
         inner join best_buyers bb on bb.customer_id = c.customer_id
         inner join orders o on c.customer_id = o.customer_id
         inner join order_items oi on o.order_id = oi.order_id
         inner join products p on oi.product_id = p.product_id
where rp <= 0.3
  and (
    (o.order_date >= '2024-01-01' and o.total_amount > (select avg(total_amount) from orders))
        or
    (o.status = 'Delivered' and p.price > (select avg(price) from products))
    )
group by c.customer_id, c.first_name, c.last_name, c.email, bb.total_spend, bb.orders_count
having sum(oi.quantity * oi.unit_price) > 5000
order by bb.total_spend desc
limit 20;

-- той самий запит, тільки з ним тільки заради одного балу використав union all

with cust_totals as (select customer_id,
                            sum(total_amount) as total_spend,
                            count(*)          as orders_count
                     from orders
                     group by customer_id),
     best_buyers as (select customer_id,
                            total_spend,
                            orders_count,
                            row_number() over (order by total_spend desc) as rn
                     from cust_totals)

select c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       bb.total_spend,
       bb.orders_count
from customers c
         inner join best_buyers bb on bb.customer_id = c.customer_id
         inner join orders o on c.customer_id = o.customer_id
         inner join order_items oi on o.order_id = oi.order_id
         inner join products p on oi.product_id = p.product_id
where bb.rn <= 30
  and o.order_date >= '2024-01-01'
  and o.total_amount > (select avg(total_amount) from orders)
group by c.customer_id, c.first_name, c.last_name, c.email, bb.total_spend, bb.orders_count
having sum(oi.quantity * oi.unit_price) > 5000

union all

select c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       bb.total_spend,
       bb.orders_count
from customers c
         inner join best_buyers bb on bb.customer_id = c.customer_id
         inner join orders o on c.customer_id = o.customer_id
         inner join order_items oi on o.order_id = oi.order_id
         inner join products p on oi.product_id = p.product_id
where bb.rn <= 30
  and o.status = 'Delivered'
  and p.price > (select avg(price) from products)
group by c.customer_id, c.first_name, c.last_name, c.email, bb.total_spend, bb.orders_count
having sum(oi.quantity * oi.unit_price) > 5000

order by total_spend desc
limit 20;