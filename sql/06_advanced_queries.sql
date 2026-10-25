-- FoodExpress - Assignment 9 : advanced SQL queries using joins and subqueries
-- Run after 05_basic_queries.sql
USE foodexpress;

-- R1. Order register – the ten most recent orders (INNER and LEFT JOIN, 5 tables + view)
SELECT o.order_id,
       DATE_FORMAT(o.order_date, '%d-%b %H:%i') AS placed,
       c.full_name        AS customer,
       r.restaurant_name  AS restaurant,
       COALESCE(da.agent_name, '- not assigned -') AS rider,
       o.order_status,
       t.total_amount
FROM orders o
JOIN customers   c  ON c.customer_id   = o.customer_id
JOIN restaurants r  ON r.restaurant_id = o.restaurant_id
JOIN v_order_totals t ON t.order_id    = o.order_id
LEFT JOIN delivery_agents da ON da.agent_id = o.agent_id
ORDER BY o.order_date DESC
LIMIT 10;

-- R2. Itemized invoice for order 38 (joins across 6 tables)
SELECT o.order_id, c.full_name AS customer,
       CONCAT(a.address_line, ', ', a.city, ' ', a.pincode) AS deliver_to,
       r.restaurant_name, p.payment_method, p.payment_status
FROM orders o
JOIN customers   c ON c.customer_id   = o.customer_id
JOIN addresses   a ON a.address_id    = o.address_id
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
JOIN payments    p ON p.order_id      = o.order_id
WHERE o.order_id = 38;

SELECT m.item_name, oi.quantity, oi.price_at_order,
       oi.quantity * oi.price_at_order AS line_total
FROM order_items oi
JOIN menu_items m ON m.item_id = oi.item_id
WHERE oi.order_id = 38;

SELECT subtotal, delivery_fee, total_amount
FROM v_order_totals WHERE order_id = 38;

-- R3. Restaurant activity, including restaurants with no orders (LEFT JOIN + GROUP BY)
SELECT r.restaurant_name, r.city,
       COUNT(o.order_id)                          AS orders,
       COALESCE(SUM(o.order_status = 'Delivered'), 0) AS delivered,
       COALESCE(SUM(o.order_status = 'Cancelled'), 0) AS cancelled,
       COALESCE(ROUND(100 * SUM(o.order_status = 'Cancelled')
                      / COUNT(o.order_id), 1), 0)     AS cancel_pct
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY orders DESC;

-- R4. Registered customers who have never ordered (anti-join)
SELECT c.customer_id, c.full_name, c.email, c.registration_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- R5. Rider performance (LEFT JOIN, TIMESTAMPDIFF, aggregates)
SELECT da.agent_id, da.agent_name, da.city,
       COUNT(o.order_id)                                         AS deliveries,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_date, o.delivered_at)), 1)
                                                                 AS avg_minutes,
       MAX(TIMESTAMPDIFF(MINUTE, o.order_date, o.delivered_at))  AS slowest,
       ROUND(AVG(rv.agent_rating), 2)                            AS avg_rating
FROM delivery_agents da
LEFT JOIN orders o   ON o.agent_id  = da.agent_id AND o.order_status = 'Delivered'
LEFT JOIN reviews rv ON rv.order_id = o.order_id
GROUP BY da.agent_id, da.agent_name, da.city
ORDER BY deliveries DESC, avg_minutes;

-- R6. Dishes frequently ordered together (self join)
SELECT m1.item_name AS dish_1, m2.item_name AS dish_2,
       COUNT(*) AS times_together
FROM order_items a
JOIN order_items b ON b.order_id = a.order_id AND b.item_id > a.item_id
JOIN menu_items m1 ON m1.item_id = a.item_id
JOIN menu_items m2 ON m2.item_id = b.item_id
GROUP BY m1.item_name, m2.item_name
HAVING COUNT(*) >= 3
ORDER BY times_together DESC, dish_1;

-- R7. Restaurant leaderboard: revenue, average order value, rating and rank
SELECT r.restaurant_name,
       COUNT(*)                       AS delivered_orders,
       SUM(t.subtotal)                AS food_revenue,
       ROUND(AVG(t.total_amount), 2)  AS avg_order_value,
       vr.avg_rating, vr.review_count,
       RANK() OVER (ORDER BY SUM(t.subtotal) DESC) AS revenue_rank
FROM orders o
JOIN restaurants r          ON r.restaurant_id  = o.restaurant_id
JOIN v_order_totals t       ON t.order_id       = o.order_id
JOIN v_restaurant_ratings vr ON vr.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_name, vr.avg_rating, vr.review_count
ORDER BY revenue_rank;

-- R8. City-wise business summary with grand total (GROUP BY … WITH ROLLUP)
SELECT COALESCE(r.city, 'ALL CITIES')        AS city,
       COUNT(*)                                  AS orders,
       SUM(o.order_status = 'Delivered')         AS delivered,
       SUM(o.order_status = 'Cancelled')         AS cancelled,
       SUM(CASE WHEN p.payment_status = 'Completed' THEN p.amount ELSE 0 END) AS collected,
       SUM(CASE WHEN p.payment_status = 'Refunded'  THEN p.amount ELSE 0 END) AS refunded
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
JOIN payments    p ON p.order_id      = o.order_id
GROUP BY r.city WITH ROLLUP;

-- R9. Top 5 best-selling dishes (delivered orders)
SELECT m.item_name, r.restaurant_name,
       SUM(oi.quantity)                     AS units_sold,
       SUM(oi.quantity * oi.price_at_order) AS revenue
FROM order_items oi
JOIN orders      o ON o.order_id      = oi.order_id
JOIN menu_items  m ON m.item_id       = oi.item_id
JOIN restaurants r ON r.restaurant_id = m.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY m.item_id, m.item_name, r.restaurant_name
ORDER BY units_sold DESC, revenue DESC
LIMIT 5;

-- R10. Cuisine popularity in each city
SELECT r.city, r.cuisine_type,
       COUNT(DISTINCT o.order_id)   AS orders,
       COUNT(DISTINCT o.customer_id) AS customers,
       SUM(oi.quantity)             AS dishes
FROM orders o
JOIN restaurants r  ON r.restaurant_id = o.restaurant_id
JOIN order_items oi ON oi.order_id     = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY r.city, r.cuisine_type
ORDER BY r.city, orders DESC;

-- R11. Orders above the average order value (scalar subquery)
SELECT o.order_id, c.full_name, t.total_amount,
       ROUND(t.total_amount - (SELECT AVG(total_amount) FROM v_order_totals), 2)
                                              AS above_average_by
FROM orders o
JOIN customers c      ON c.customer_id = o.customer_id
JOIN v_order_totals t ON t.order_id    = o.order_id
WHERE t.total_amount > (SELECT AVG(total_amount) FROM v_order_totals)
ORDER BY t.total_amount DESC
LIMIT 10;

-- R12. Customers who have ordered Hyderabadi food (IN subquery)
SELECT customer_id, full_name, email
FROM customers
WHERE customer_id IN (
        SELECT o.customer_id
        FROM orders o
        WHERE o.order_status = 'Delivered'
          AND o.restaurant_id IN (SELECT restaurant_id
                                  FROM restaurants
                                  WHERE cuisine_type = 'Hyderabadi'))
ORDER BY full_name;

-- R13. Dishes priced above their own restaurant's average (correlated subquery)
SELECT r.restaurant_name, m.item_name, m.price,
       (SELECT ROUND(AVG(m2.price), 2)
        FROM menu_items m2
        WHERE m2.restaurant_id = m.restaurant_id) AS restaurant_avg
FROM menu_items m
JOIN restaurants r ON r.restaurant_id = m.restaurant_id
WHERE m.price > (SELECT AVG(m2.price)
                 FROM menu_items m2
                 WHERE m2.restaurant_id = m.restaurant_id)
ORDER BY r.restaurant_name, m.price DESC;

-- R14. Delivered orders still waiting for a review (NOT EXISTS)
SELECT o.order_id, c.full_name, c.email, r.restaurant_name,
       DATE(o.delivered_at) AS delivered_on
FROM orders o
JOIN customers   c ON c.customer_id   = o.customer_id
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
  AND NOT EXISTS (SELECT 1 FROM reviews rv WHERE rv.order_id = o.order_id)
ORDER BY o.delivered_at DESC;

-- R15. Restaurants with at least one poor review (EXISTS) – quality alert
SELECT r.restaurant_id, r.restaurant_name, r.city
FROM restaurants r
WHERE EXISTS (SELECT 1
              FROM orders o
              JOIN reviews rv ON rv.order_id = o.order_id
              WHERE o.restaurant_id = r.restaurant_id
                AND rv.food_rating <= 2);

-- R16. Customer segments by lifetime spend (derived table + CASE)
SELECT segment,
       COUNT(*)                   AS customers,
       ROUND(AVG(orders), 1)      AS avg_orders,
       ROUND(AVG(spend), 2)       AS avg_spend,
       SUM(spend)                 AS total_spend
FROM (SELECT o.customer_id,
             COUNT(*)      AS orders,
             SUM(p.amount) AS spend,
             CASE WHEN SUM(p.amount) >= 3000 THEN 'Gold'
                  WHEN SUM(p.amount) >= 1500 THEN 'Silver'
                  ELSE 'Bronze' END AS segment
      FROM orders o
      JOIN payments p ON p.order_id = o.order_id
      WHERE p.payment_status = 'Completed'
      GROUP BY o.customer_id) AS customer_spend
GROUP BY segment
ORDER BY total_spend DESC;

-- R17. Best-selling dish of every restaurant (CTE + ROW_NUMBER)
WITH dish_sales AS (
    SELECT m.restaurant_id, m.item_name,
           SUM(oi.quantity) AS units,
           ROW_NUMBER() OVER (PARTITION BY m.restaurant_id
                              ORDER BY SUM(oi.quantity) DESC, m.item_name) AS rn
    FROM order_items oi
    JOIN menu_items m ON m.item_id  = oi.item_id
    JOIN orders     o ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY m.restaurant_id, m.item_name
)
SELECT r.restaurant_name, ds.item_name AS best_seller, ds.units
FROM dish_sales ds
JOIN restaurants r ON r.restaurant_id = ds.restaurant_id
WHERE ds.rn = 1
ORDER BY ds.units DESC;

-- R18. Price-change audit: order lines charged at an older price
SELECT oi.order_id, m.item_name,
       oi.price_at_order AS charged, m.price AS current_price,
       m.price - oi.price_at_order AS difference
FROM order_items oi
JOIN menu_items m ON m.item_id = oi.item_id
WHERE oi.price_at_order <> m.price
ORDER BY oi.order_id;

-- R19. Payment reconciliation: refunded and failed payments
SELECT p.payment_id, o.order_id, c.full_name, r.restaurant_name,
       p.payment_method, p.payment_status, p.amount
FROM payments p
JOIN orders      o ON o.order_id      = p.order_id
JOIN customers   c ON c.customer_id   = o.customer_id
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE p.payment_status IN ('Refunded', 'Failed')
ORDER BY p.payment_status, p.amount DESC;

SELECT payment_status, COUNT(*) AS payments, SUM(amount) AS amount
FROM payments
WHERE order_id IN (SELECT order_id FROM orders WHERE order_status = 'Cancelled')
GROUP BY payment_status;
