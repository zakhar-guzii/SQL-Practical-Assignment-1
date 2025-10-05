use ecommerce_db;

-- 1. select joining 5 tables

-- Отримати повну інформацію про все
select c.first_name,
       c.last_name,
       p.name                        as product_name,
       oi.quantity,
       oi.unit_price,
       (oi.quantity * oi.unit_price) as total_item_amount,
       s.name                        as supplier_name,
       s.rating                      as supplier_rating,
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
where status = 'Pending'
union
select order_id, customer_id, order_date, status
from orders
where status = 'Canceled';

-- CTEs, order by, where

-- Знайти покупців, що входить в топ 30% за витраченими коштами
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
         inner join best_buyers bb
                    on bb.customer_id = c.customer_id
where rp <= 0.3
order by bb.total_spend desc;


-- subquery, group by & having

-- Найкращий постачальник міста
select c.city,
       s.name           as supplier_name,
       sum(oi.quantity) as total_items
from customers c
         inner join orders o on o.customer_id = c.customer_id
         inner join order_items oi on oi.order_id = o.order_id
         inner join products p on p.product_id = oi.product_id
         inner join suppliers s on s.supplier_id = p.supplier_id
group by c.city, s.supplier_id
having sum(oi.quantity) = (select max(total_per_supplier)
                           from (select sum(oi2.quantity) as total_per_supplier
                                 from customers c2
                                          join orders o2 on o2.customer_id = c2.customer_id
                                          join order_items oi2 on oi2.order_id = o2.order_id
                                          join products p2 on p2.product_id = oi2.product_id
                                 where c2.city = c.city
                                 group by p2.supplier_id) as sub)
order by c.city;

-- king of queries

-- знайти топ клієнтів з найбільшими витрататами за останні 6 місяців,
-- разом з інформацією про те, що вони замовили за цей час,
-- найбільш популярний постачальників та категорії товарів

with recent_orders as (select o.order_id, -- всі замовлення, окрім скасованих
                              o.customer_id,
                              o.total_amount,
                              o.order_date,
                              o.status
                       from orders o
                       where o.order_date >= curdate() - interval 6 month
                         and o.status != 'Canceled'),
     customer_spending as (select r.customer_id, -- загальна сума витрат
                                  sum(r.total_amount) as total_spent,
                                  count(r.order_id)   as total_orders
                           from recent_orders r
                           group by r.customer_id)
    (select c.customer_id,
            concat(c.first_name, '', c.last_name) as full_name,
            c.email,
            cs.total_spent,
            cs.total_orders,
            o.order_id,
            o.order_date,
            p.name                                as product_name,
            p.category,
            s.name                                as supplier_name,
            (select s2.name
             from order_items oi2
                      join products p2 on oi2.product_id = p2.product_id
                      join suppliers s2 on p2.supplier_id = s2.supplier_id
                      join orders o2 on oi2.order_id = o2.order_id
             where o2.customer_id = c.customer_id
             group by s2.supplier_id
             order by count(*) desc
             limit 1)                             as top_supplier
     from customers c
              join customer_spending cs on c.customer_id = cs.customer_id
              join orders o on c.customer_id = o.customer_id
              join order_items oi on o.order_id = oi.order_id
              join products p on oi.product_id = p.product_id
              join suppliers s on p.supplier_id = s.supplier_id
     where cs.total_spent > 1000
     group by c.customer_id
     having count(distinct o.order_id) >= 2)
union all
(select c.customer_id,
        concat(c.first_name, ' ', c.last_name) as full_name,
        c.email,
        cs.total_spent,
        cs.total_orders,

        null                                   as order_id,
        null                                   as order_date,
        null                                   as product_name,
        null                                   as category,
        null                                   as supplier_name,
        null                                   as top_supplier
 from customers c
          join customer_spending cs on c.customer_id = cs.customer_id
 where cs.total_orders = 1)
order by total_spent desc
limit 15;
