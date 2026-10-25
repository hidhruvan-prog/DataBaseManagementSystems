-- FoodExpress - Assignment 6 : constraint verification tests
-- Run on the EMPTY database after 01 and 02, before 04_sample_data.sql.
-- Statements marked 'expect error' are supposed to fail.
USE foodexpress;

-- setup: Parent rows: two customers (registration_date omitted → DEFAULT)
INSERT INTO customers (customer_id, full_name, email, phone, password_hash) VALUES
    (1, 'Test Customer',   'test.customer@example.com', '9876543210', SHA2('demo-1', 256)),
    (2, 'Second Customer', 'second.customer@example.com', '9123456780', SHA2('demo-2', 256));
SELECT customer_id, full_name, registration_date FROM customers;

-- setup: Addresses (label and is_active omitted → DEFAULT 'Home' / TRUE)
INSERT INTO addresses (address_id, customer_id, address_line, city, state, pincode, is_default) VALUES
    (1, 1, '12, MG Road',     'Bengaluru', 'Karnataka',   '560001', TRUE),
    (2, 2, '5, Marine Drive', 'Mumbai',    'Maharashtra', '400020', TRUE);
SELECT address_id, customer_id, label, pincode, is_default, is_active FROM addresses;

-- setup: Restaurants, menu items and a rider (flags and joined_on → DEFAULT)
INSERT INTO restaurants (restaurant_id, restaurant_name, cuisine_type, address_line, city, pincode, contact_phone) VALUES
    (1, 'Test Kitchen',  'North Indian', '1, Brigade Road',  'Bengaluru', '560025', '08012345678'),
    (2, 'Other Kitchen', 'Chinese',      '2, Church Street', 'Bengaluru', '560001', '08087654321');
INSERT INTO menu_items (item_id, restaurant_id, item_name, price, category) VALUES
    (1, 1, 'Paneer Tikka', 220.00, 'Starter'),
    (2, 2, 'Veg Noodles',  180.00, 'Main Course');
INSERT INTO delivery_agents (agent_id, agent_name, phone, vehicle_number, city) VALUES
    (1, 'Test Rider', '9988776655', 'KA01AB1234', 'Bengaluru');
SELECT item_id, item_name, is_veg, is_available FROM menu_items;
SELECT agent_id, agent_name, is_available, joined_on FROM delivery_agents;

-- setup: An order, its line item and payment (order_date, order_status, delivery_fee, payment_status → DEFAULT)
INSERT INTO orders (order_id, customer_id, restaurant_id, address_id, agent_id)
VALUES (1, 1, 1, 1, 1);
INSERT INTO order_items (order_item_id, order_id, item_id, quantity, price_at_order)
VALUES (1, 1, 1, 2, 220.00);
INSERT INTO payments (payment_id, order_id, amount, payment_method)
VALUES (1, 1, 480.00, 'UPI');
SELECT order_id, order_date, order_status, delivery_fee, delivered_at FROM orders;
SELECT payment_id, order_id, amount, payment_status, payment_date FROM payments;

-- T1 [Entity] PRIMARY KEY rejects a duplicate customer_id -- expect error
INSERT INTO customers (customer_id, full_name, email, phone, password_hash)
VALUES (1, 'Duplicate Id', 'dup@example.com', '9876500000', 'x');

-- T2 [Entity] NOT NULL rejects a menu item without a price -- expect error
INSERT INTO menu_items (restaurant_id, item_name, category)
VALUES (1, 'Mystery Dish', 'Starter');

-- T3 [Key] UNIQUE rejects a second account with the same e-mail -- expect error
INSERT INTO customers (full_name, email, phone, password_hash)
VALUES ('Copy Cat', 'test.customer@example.com', '9876500001', 'x');

-- T4 [Key] UNIQUE rejects a second rider with the same vehicle number -- expect error
INSERT INTO delivery_agents (agent_name, phone, vehicle_number, city)
VALUES ('Rider Two', '9988776600', 'KA01AB1234', 'Bengaluru');

-- T5 [Key] UNIQUE (restaurant_id, item_name) rejects a duplicate dish on one menu -- expect error
INSERT INTO menu_items (restaurant_id, item_name, price, category)
VALUES (1, 'Paneer Tikka', 250.00, 'Starter');

-- T6 [Key] The generated-column UNIQUE key allows only one default address per customer -- expect error
INSERT INTO addresses (customer_id, label, address_line, city, state, pincode, is_default)
VALUES (1, 'Work', 'Manyata Tech Park', 'Bengaluru', 'Karnataka', '560045', TRUE);

-- T7 [Key] …while a second, non-default address is accepted
INSERT INTO addresses (address_id, customer_id, label, address_line, city, state, pincode)
VALUES (3, 1, 'Work', 'Manyata Tech Park', 'Bengaluru', 'Karnataka', '560045');
SELECT address_id, customer_id, label, is_default, default_owner FROM addresses;

-- T8 [Key] UNIQUE (order_id) on payments rejects a second payment for the same order -- expect error
INSERT INTO payments (order_id, amount, payment_method) VALUES (1, 480.00, 'Card');

-- T9 [Key] UNIQUE (order_id, item_id) rejects the same dish twice in one order -- expect error
INSERT INTO order_items (order_id, item_id, quantity, price_at_order) VALUES (1, 1, 1, 220.00);

-- T10 [Domain] CHECK rejects an invalid mobile number -- expect error
INSERT INTO customers (full_name, email, phone, password_hash)
VALUES ('Bad Phone', 'bad.phone@example.com', '12345', 'x');

-- T11 [Domain] CHECK rejects a malformed e-mail address -- expect error
INSERT INTO customers (full_name, email, phone, password_hash)
VALUES ('Bad Mail', 'bad-mail.example.com', '9876500002', 'x');

-- T12 [Domain] CHECK rejects a 5-digit pincode -- expect error
INSERT INTO addresses (customer_id, address_line, city, state, pincode)
VALUES (2, 'Andheri', 'Mumbai', 'Maharashtra', '40005');

-- T13 [Domain] CHECK rejects a negative price -- expect error
UPDATE menu_items SET price = -50 WHERE item_id = 1;

-- T14 [Domain] CHECK rejects a category outside the allowed list -- expect error
INSERT INTO menu_items (restaurant_id, item_name, price, category)
VALUES (1, 'Tomato Soup', 120, 'Soup');

-- T15 [Domain] CHECK rejects a quantity of zero -- expect error
UPDATE order_items SET quantity = 0 WHERE order_item_id = 1;

-- T16 [Domain] ENUM rejects an unknown order status (strict mode) -- expect error
UPDATE orders SET order_status = 'Shipped' WHERE order_id = 1;

-- T17 [Domain] CHECK rejects a rider vehicle number in the wrong format -- expect error
INSERT INTO delivery_agents (agent_name, phone, vehicle_number, city)
VALUES ('Rider Three', '9988776611', 'BIKE-42', 'Bengaluru');

-- T18 [Business rule] CHECK: an order cannot be marked Delivered without delivered_at -- expect error
UPDATE orders SET order_status = 'Delivered' WHERE order_id = 1;

-- T19 [Business rule] CHECK: delivered_at cannot be earlier than order_date -- expect error
UPDATE orders SET order_status = 'Delivered',
                  delivered_at = order_date - INTERVAL 10 MINUTE
WHERE order_id = 1;

-- T20 [Business rule] A consistent update is accepted
UPDATE orders SET order_status = 'Delivered',
                  delivered_at = order_date + INTERVAL 32 MINUTE
WHERE order_id = 1;
SELECT order_id, order_status, order_date, delivered_at FROM orders;

-- T21 [Business rule] Trigger: a dish from another restaurant cannot be added to the order -- expect error
INSERT INTO order_items (order_id, item_id, quantity, price_at_order)
VALUES (1, 2, 1, 180.00);

-- T22 [Business rule] Trigger: an order that is not delivered cannot be reviewed -- expect error
INSERT INTO orders (order_id, customer_id, restaurant_id, address_id)
VALUES (2, 2, 2, 2);
INSERT INTO reviews (order_id, food_rating) VALUES (2, 4);

-- T23 [Domain] CHECK rejects a rating outside 1–5 -- expect error
INSERT INTO reviews (order_id, food_rating, agent_rating) VALUES (1, 6, 5);

-- T24 [Business rule] A valid review of the delivered order is accepted (review_date → DEFAULT)
INSERT INTO reviews (order_id, food_rating, agent_rating, comment)
VALUES (1, 5, 4, 'Hot and fresh');
SELECT review_id, order_id, food_rating, agent_rating, review_date FROM reviews;

-- T25 [Referential] FOREIGN KEY rejects an order for a restaurant that does not exist -- expect error
INSERT INTO orders (customer_id, restaurant_id, address_id) VALUES (1, 99, 1);

-- T26 [Referential] Composite FOREIGN KEY rejects delivering customer 1's order to customer 2's address -- expect error
INSERT INTO orders (customer_id, restaurant_id, address_id) VALUES (1, 1, 2);

-- T27 [Referential] ON DELETE RESTRICT: a restaurant with menu items and orders cannot be deleted -- expect error
DELETE FROM restaurants WHERE restaurant_id = 1;

-- T28 [Referential] ON DELETE RESTRICT: a customer with order history cannot be deleted -- expect error
DELETE FROM customers WHERE customer_id = 1;

-- T29 [Referential] ON DELETE SET NULL: removing a rider keeps the order but clears agent_id (rolled back)
START TRANSACTION;
DELETE FROM delivery_agents WHERE agent_id = 1;
SELECT order_id, agent_id, order_status FROM orders;
ROLLBACK;

-- T30 [Referential] ON DELETE CASCADE: deleting an order removes its items, payment and review (rolled back)
START TRANSACTION;
DELETE FROM orders WHERE order_id = 1;
SELECT (SELECT COUNT(*) FROM order_items WHERE order_id = 1) AS items_left,
       (SELECT COUNT(*) FROM payments    WHERE order_id = 1) AS payments_left,
       (SELECT COUNT(*) FROM reviews     WHERE order_id = 1) AS reviews_left;
ROLLBACK;

-- T31 [Referential] ON DELETE CASCADE: deleting a customer without orders also deletes their addresses (rolled back)
START TRANSACTION;
DELETE FROM orders WHERE order_id = 2;
DELETE FROM customers WHERE customer_id = 2;
SELECT address_id, customer_id FROM addresses;
ROLLBACK;

-- remove the test rows
DELETE FROM reviews; DELETE FROM payments; DELETE FROM order_items; DELETE FROM orders;
DELETE FROM menu_items; DELETE FROM delivery_agents; DELETE FROM restaurants;
DELETE FROM addresses; DELETE FROM customers;
