-- FoodExpress - Assignment 8 : basic SQL queries and aggregate functions
-- Run after 01_create_database.sql, 02_constraints.sql and 04_sample_data.sql
USE foodexpress;

-- Q1. Vegetarian dishes under ₹150 that can be ordered now
SELECT item_id, item_name, price, category
FROM menu_items
WHERE is_veg = TRUE
  AND is_available = TRUE
  AND price < 150;

-- Q2. Cancelled orders
SELECT order_id, customer_id, restaurant_id, order_date
FROM orders
WHERE order_status = 'Cancelled';

-- Q3. Orders placed in the first week of October (BETWEEN)
SELECT order_id, customer_id, order_date, order_status
FROM orders
WHERE order_date BETWEEN '2026-10-01 00:00:00' AND '2026-10-07 23:59:59';

-- Q4. Restaurants in Mumbai or Pune (IN)
SELECT restaurant_id, restaurant_name, cuisine_type, city
FROM restaurants
WHERE city IN ('Mumbai', 'Pune');

-- Q5. Every biryani on the platform (LIKE pattern)
SELECT item_id, restaurant_id, item_name, price
FROM menu_items
WHERE item_name LIKE '%Biryani%';

-- Q6. Active orders still waiting for a rider (IS NULL)
SELECT order_id, restaurant_id, order_date, order_status
FROM orders
WHERE agent_id IS NULL
  AND order_status NOT IN ('Delivered', 'Cancelled');

-- Q7. The ten most expensive dishes
SELECT item_name, restaurant_id, category, price
FROM menu_items
ORDER BY price DESC, item_name ASC
LIMIT 10;

-- Q8. Restaurant directory sorted by city, then name
SELECT city, restaurant_name, cuisine_type, contact_phone
FROM restaurants
ORDER BY city, restaurant_name;

-- Q9. The eight most recent orders
SELECT order_id, customer_id, restaurant_id, order_date, order_status
FROM orders
ORDER BY order_date DESC
LIMIT 8;

-- Q10. COUNT() – orders, distinct customers and riders assigned
SELECT COUNT(*)                    AS total_orders,
       COUNT(DISTINCT customer_id) AS customers_who_ordered,
       COUNT(agent_id)             AS orders_with_rider,
       COUNT(delivered_at)         AS delivered_orders
FROM orders;

-- Q11. SUM() – money collected and refunded
SELECT SUM(CASE WHEN payment_status = 'Completed' THEN amount ELSE 0 END) AS collected,
       SUM(CASE WHEN payment_status = 'Refunded'  THEN amount ELSE 0 END) AS refunded,
       SUM(CASE WHEN payment_status = 'Pending'   THEN amount ELSE 0 END) AS pending
FROM payments;

-- Q12. AVG() – average menu price and average ratings
SELECT ROUND(AVG(price), 2)  AS avg_menu_price
FROM menu_items;

SELECT ROUND(AVG(food_rating), 2)  AS avg_food_rating,
       ROUND(AVG(agent_rating), 2) AS avg_rider_rating,
       COUNT(agent_rating)         AS rider_ratings_given
FROM reviews;

-- Q13. MIN() and MAX() – price range and trading period
SELECT MIN(price) AS cheapest_item, MAX(price) AS costliest_item
FROM menu_items;

SELECT MIN(order_date) AS first_order, MAX(order_date) AS latest_order
FROM orders;

-- Q14. All five aggregates together – completed payments
SELECT COUNT(*)              AS payments,
       SUM(amount)           AS revenue,
       ROUND(AVG(amount), 2) AS avg_order_value,
       MIN(amount)           AS smallest,
       MAX(amount)           AS largest
FROM payments
WHERE payment_status = 'Completed';

-- Q15. Number of orders in each status
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- Q16. Revenue by payment method
SELECT payment_method,
       COUNT(*)              AS payments,
       SUM(amount)           AS revenue,
       ROUND(AVG(amount), 2) AS avg_amount
FROM payments
WHERE payment_status = 'Completed'
GROUP BY payment_method
ORDER BY revenue DESC;

-- Q17. Menu size and price level per category
SELECT category,
       COUNT(*)             AS items,
       MIN(price)           AS min_price,
       MAX(price)           AS max_price,
       ROUND(AVG(price), 2) AS avg_price
FROM menu_items
GROUP BY category
ORDER BY avg_price DESC;

-- Q18. Orders per month
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       COUNT(*)                         AS orders,
       SUM(order_status = 'Cancelled')  AS cancelled
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- Q19. Restaurants that received more than 8 orders
SELECT restaurant_id, COUNT(*) AS orders
FROM orders
GROUP BY restaurant_id
HAVING COUNT(*) > 8
ORDER BY orders DESC;

-- Q20. Menu categories whose average price is above ₹200
SELECT category, COUNT(*) AS items, ROUND(AVG(price), 2) AS avg_price
FROM menu_items
GROUP BY category
HAVING AVG(price) > 200;

-- Q21. Repeat customers (at least 4 delivered orders)
SELECT customer_id, COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
HAVING COUNT(*) >= 4
ORDER BY delivered_orders DESC, customer_id;

-- Q22. Large orders: subtotal above ₹900
SELECT order_id,
       SUM(quantity)                  AS units,
       SUM(quantity * price_at_order) AS subtotal
FROM order_items
GROUP BY order_id
HAVING subtotal > 900
ORDER BY subtotal DESC;

-- Q23. UPDATE – Dosa Junction raises the price of Masala Dosa
SELECT item_id, item_name, price FROM menu_items WHERE item_id = 7;

UPDATE menu_items
SET price = 109.00
WHERE item_id = 7;

SELECT item_id, item_name, price FROM menu_items WHERE item_id = 7;

SELECT order_id, item_id, quantity, price_at_order
FROM order_items
WHERE item_id = 7;

-- Q24. UPDATE – the order that is out for delivery is delivered
UPDATE orders
SET order_status = 'Delivered',
    delivered_at = order_date + INTERVAL 31 MINUTE
WHERE order_status = 'Out for Delivery';

UPDATE payments
SET payment_status = 'Completed'
WHERE payment_status = 'Pending'
  AND order_id IN (SELECT order_id FROM orders WHERE order_status = 'Delivered');

SELECT o.order_id, o.order_status, o.delivered_at, p.payment_method, p.payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.order_id = 61;

-- Q25. INSERT and DELETE – a seasonal dish is added and later withdrawn
INSERT INTO menu_items (restaurant_id, item_name, description, price, category)
VALUES (10, 'Pumpkin Spice Cake', 'Autumn special', 179.00, 'Dessert');

SELECT item_id, item_name, price, is_veg, is_available
FROM menu_items WHERE restaurant_id = 10;

DELETE FROM menu_items
WHERE restaurant_id = 10 AND item_name = 'Pumpkin Spice Cake';

SELECT COUNT(*) AS sweet_tooth_items FROM menu_items WHERE restaurant_id = 10;
