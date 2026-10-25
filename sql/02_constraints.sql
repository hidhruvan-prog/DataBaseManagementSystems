-- =====================================================================
--  FoodExpress - Online Food Delivery System
--  Assignment 6 : Data integrity constraints (MySQL 8.0.16+)
--  Run after 01_create_database.sql.
--  PRIMARY KEY and FOREIGN KEY constraints were declared with the tables
--  in 01_create_database.sql; this script adds UNIQUE, CHECK and DEFAULT
--  constraints plus two triggers for rules that span tables.
-- =====================================================================
USE foodexpress;

-- ---------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------
ALTER TABLE customers
    MODIFY registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD CONSTRAINT uq_customers_email UNIQUE (email),
    ADD CONSTRAINT uq_customers_phone UNIQUE (phone),
    ADD CONSTRAINT chk_customers_email CHECK (email LIKE '%_@_%._%'),
    ADD CONSTRAINT chk_customers_phone CHECK (phone REGEXP '^[6-9][0-9]{9}$');

-- ---------------------------------------------------------------------
-- addresses
-- ---------------------------------------------------------------------
ALTER TABLE addresses
    MODIFY label      VARCHAR(20) NOT NULL DEFAULT 'Home',
    MODIFY is_default BOOLEAN     NOT NULL DEFAULT FALSE,
    MODIFY is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    ADD CONSTRAINT chk_addresses_label   CHECK (label IN ('Home','Work','Other')),
    ADD CONSTRAINT chk_addresses_pincode CHECK (pincode REGEXP '^[1-9][0-9]{5}$');

-- At most one default address per customer. MySQL has no partial unique
-- index, so a generated column holds customer_id only for the default row
-- (NULL otherwise) and a UNIQUE key on it allows any number of NULLs.
ALTER TABLE addresses
    ADD COLUMN default_owner INT
        GENERATED ALWAYS AS (IF(is_default, customer_id, NULL)) VIRTUAL,
    ADD CONSTRAINT uq_addresses_one_default UNIQUE (default_owner);

-- ---------------------------------------------------------------------
-- restaurants
-- ---------------------------------------------------------------------
ALTER TABLE restaurants
    MODIFY is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD CONSTRAINT uq_restaurants_phone   UNIQUE (contact_phone),
    ADD CONSTRAINT chk_restaurants_pincode CHECK (pincode REGEXP '^[1-9][0-9]{5}$'),
    ADD CONSTRAINT chk_restaurants_phone   CHECK (contact_phone REGEXP '^[0-9]{10,11}$');

-- ---------------------------------------------------------------------
-- menu_items
-- ---------------------------------------------------------------------
ALTER TABLE menu_items
    MODIFY is_veg       BOOLEAN NOT NULL DEFAULT TRUE,
    MODIFY is_available BOOLEAN NOT NULL DEFAULT TRUE,
    ADD CONSTRAINT uq_menu_items_name     UNIQUE (restaurant_id, item_name),
    ADD CONSTRAINT chk_menu_items_price   CHECK (price > 0),
    ADD CONSTRAINT chk_menu_items_category CHECK (category IN
        ('Starter','Main Course','Bread','Rice','Dessert','Beverage','Snack'));

-- ---------------------------------------------------------------------
-- delivery_agents
-- ---------------------------------------------------------------------
ALTER TABLE delivery_agents
    MODIFY is_available BOOLEAN NOT NULL DEFAULT TRUE,
    MODIFY joined_on    DATE    NOT NULL DEFAULT (CURRENT_DATE),
    ADD CONSTRAINT uq_agents_phone   UNIQUE (phone),
    ADD CONSTRAINT uq_agents_vehicle UNIQUE (vehicle_number),
    ADD CONSTRAINT chk_agents_phone  CHECK (phone REGEXP '^[6-9][0-9]{9}$'),
    ADD CONSTRAINT chk_agents_vehicle
        CHECK (vehicle_number REGEXP '^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

-- ---------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------
ALTER TABLE orders
    MODIFY order_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY order_status ENUM('Placed','Preparing','Out for Delivery',
                             'Delivered','Cancelled') NOT NULL DEFAULT 'Placed',
    MODIFY delivery_fee DECIMAL(6,2) NOT NULL DEFAULT 40.00,
    ADD CONSTRAINT chk_orders_fee CHECK (delivery_fee BETWEEN 0 AND 200),
    -- delivered_at is filled exactly when the order is Delivered
    ADD CONSTRAINT chk_orders_delivered CHECK (
        (order_status =  'Delivered' AND delivered_at IS NOT NULL) OR
        (order_status <> 'Delivered' AND delivered_at IS NULL)),
    ADD CONSTRAINT chk_orders_delivery_time
        CHECK (delivered_at IS NULL OR delivered_at > order_date);

-- ---------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------
ALTER TABLE order_items
    ADD CONSTRAINT uq_order_items_line UNIQUE (order_id, item_id),
    ADD CONSTRAINT chk_order_items_qty   CHECK (quantity BETWEEN 1 AND 50),
    ADD CONSTRAINT chk_order_items_price CHECK (price_at_order > 0);

-- ---------------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------------
ALTER TABLE payments
    MODIFY payment_status ENUM('Pending','Completed','Failed','Refunded')
                          NOT NULL DEFAULT 'Pending',
    MODIFY payment_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD CONSTRAINT uq_payments_order  UNIQUE (order_id),
    ADD CONSTRAINT chk_payments_amount CHECK (amount >= 0);

-- ---------------------------------------------------------------------
-- reviews
-- ---------------------------------------------------------------------
ALTER TABLE reviews
    MODIFY review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD CONSTRAINT uq_reviews_order UNIQUE (order_id),
    ADD CONSTRAINT chk_reviews_food  CHECK (food_rating BETWEEN 1 AND 5),
    ADD CONSTRAINT chk_reviews_agent
        CHECK (agent_rating IS NULL OR agent_rating BETWEEN 1 AND 5);

-- ---------------------------------------------------------------------
-- Rules that involve two tables cannot be written as CHECK constraints
-- in MySQL, so they are enforced with BEFORE INSERT triggers.
-- ---------------------------------------------------------------------
DELIMITER $$

-- a menu item can only be added to an order placed with its restaurant
CREATE TRIGGER trg_order_items_same_restaurant
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    IF (SELECT restaurant_id FROM menu_items WHERE item_id = NEW.item_id)
       <> (SELECT restaurant_id FROM orders WHERE order_id = NEW.order_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Menu item does not belong to the order''s restaurant';
    END IF;
END$$

-- a review can only be written for an order that has been delivered
CREATE TRIGGER trg_reviews_only_delivered
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    IF (SELECT order_status FROM orders WHERE order_id = NEW.order_id)
       <> 'Delivered' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only delivered orders can be reviewed';
    END IF;
END$$

DELIMITER ;
