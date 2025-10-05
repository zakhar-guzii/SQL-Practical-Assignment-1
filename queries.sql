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

WITH top_customers AS (
    -- CTE
    SELECT customer_id,
           COUNT(*) as order_count
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(*) > 1)
SELECT *
FROM (SELECT c.customer_id,
             c.first_name,
             c.last_name,
             c.city,
             COUNT(DISTINCT o.order_id)       as total_orders,
             SUM(oi.quantity * oi.unit_price) as total_spent,
             p.category,
             s.name                           as supplier_name
      FROM customers c
               INNER JOIN orders o ON c.customer_id = o.customer_id
               INNER JOIN order_items oi ON o.order_id = oi.order_id
               INNER JOIN products p ON oi.product_id = p.product_id
               INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE o.order_date >= '2024-01-01'
        -- Subquery в WHERE
        AND c.customer_id IN (SELECT customer_id
                              FROM top_customers)
        AND o.total_amount > (SELECT AVG(total_amount)
                              FROM orders)
      GROUP BY c.customer_id,
               c.first_name,
               c.last_name,
               c.city,
               p.category,
               s.name
      HAVING SUM(oi.quantity * oi.unit_price) > 100

      UNION ALL

      SELECT c.customer_id,
             c.first_name,
             c.last_name,
             c.city,
             COUNT(DISTINCT o.order_id)       as total_orders,
             SUM(oi.quantity * oi.unit_price) as total_spent,
             p.category,
             s.name                           as supplier_name
      FROM customers c
               INNER JOIN orders o ON c.customer_id = o.customer_id
               INNER JOIN order_items oi ON o.order_id = oi.order_id
               INNER JOIN products p ON oi.product_id = p.product_id
               INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE o.status = 'Delivered'
        AND p.price > (SELECT AVG(price)
                       FROM products)
      GROUP BY c.customer_id,
               c.first_name,
               c.last_name,
               c.city,
               p.category,
               s.name
      HAVING COUNT(DISTINCT o.order_id) >= 1) AS combined_results
ORDER BY total_spent DESC
LIMIT 20;