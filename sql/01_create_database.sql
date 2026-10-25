-- =====================================================================
--  FoodExpress - Online Food Delivery System
--  Assignment 5 : Database creation and table implementation (MySQL 8)
--  Finalized design (after the Assignment 3 analysis):
--    * Restaurants.address split into address_line / city / pincode
--    * stored avg_rating columns removed (derived from Reviews instead)
--    * Orders.total_amount replaced by delivery_fee + derived subtotal
--    * Orders.delivered_at added
--    * Reviews no longer repeats customer_id / restaurant_id
--      (both are reachable through order_id); agent_rating added
--    * Orders(address_id, customer_id) is a composite foreign key, so an
--      order can only use an address that belongs to the same customer
--  UNIQUE / CHECK / DEFAULT constraints are added in 02_constraints.sql
-- =====================================================================

DROP DATABASE IF EXISTS foodexpress;
CREATE DATABASE foodexpress
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE foodexpress;

-- ---------------------------------------------------------------------
-- 1. customers : people who order food
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id       INT           NOT NULL AUTO_INCREMENT,
    full_name         VARCHAR(100)  NOT NULL,
    email             VARCHAR(100)  NOT NULL,
    phone             VARCHAR(15)   NOT NULL,
    password_hash     VARCHAR(255)  NOT NULL,
    registration_date DATETIME      NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. addresses : delivery addresses saved by a customer (1 : M)
-- ---------------------------------------------------------------------
CREATE TABLE addresses (
    address_id    INT           NOT NULL AUTO_INCREMENT,
    customer_id   INT           NOT NULL,
    label         VARCHAR(20)   NOT NULL,          -- Home / Work / Other
    address_line  VARCHAR(255)  NOT NULL,
    city          VARCHAR(50)   NOT NULL,
    state         VARCHAR(50)   NOT NULL,
    pincode       CHAR(6)       NOT NULL,
    is_default    BOOLEAN       NOT NULL,
    is_active     BOOLEAN       NOT NULL,
    CONSTRAINT pk_addresses PRIMARY KEY (address_id),
    -- candidate key used as the target of the composite FK in orders
    CONSTRAINT uq_addresses_id_customer UNIQUE (address_id, customer_id),
    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 3. restaurants : partner restaurants
-- ---------------------------------------------------------------------
CREATE TABLE restaurants (
    restaurant_id    INT           NOT NULL AUTO_INCREMENT,
    restaurant_name  VARCHAR(100)  NOT NULL,
    cuisine_type     VARCHAR(50)   NOT NULL,
    address_line     VARCHAR(255)  NOT NULL,
    city             VARCHAR(50)   NOT NULL,
    pincode          CHAR(6)       NOT NULL,
    contact_phone    VARCHAR(15)   NOT NULL,
    is_active        BOOLEAN       NOT NULL,
    CONSTRAINT pk_restaurants PRIMARY KEY (restaurant_id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. menu_items : dishes offered by a restaurant (1 : M)
-- ---------------------------------------------------------------------
CREATE TABLE menu_items (
    item_id        INT           NOT NULL AUTO_INCREMENT,
    restaurant_id  INT           NOT NULL,
    item_name      VARCHAR(100)  NOT NULL,
    description    VARCHAR(255)  NULL,
    price          DECIMAL(8,2)  NOT NULL,
    category       VARCHAR(50)   NOT NULL,
    is_veg         BOOLEAN       NOT NULL,
    is_available   BOOLEAN       NOT NULL,
    CONSTRAINT pk_menu_items PRIMARY KEY (item_id),
    CONSTRAINT fk_menu_items_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 5. delivery_agents : riders who deliver orders
-- ---------------------------------------------------------------------
CREATE TABLE delivery_agents (
    agent_id        INT           NOT NULL AUTO_INCREMENT,
    agent_name      VARCHAR(100)  NOT NULL,
    phone           VARCHAR(15)   NOT NULL,
    vehicle_number  VARCHAR(20)   NOT NULL,
    city            VARCHAR(50)   NOT NULL,
    is_available    BOOLEAN       NOT NULL,
    joined_on       DATE          NOT NULL,
    CONSTRAINT pk_delivery_agents PRIMARY KEY (agent_id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 6. orders : one row per order placed (central transaction table)
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id       INT            NOT NULL AUTO_INCREMENT,
    customer_id    INT            NOT NULL,
    restaurant_id  INT            NOT NULL,
    address_id     INT            NOT NULL,
    agent_id       INT            NULL,           -- NULL until assigned
    order_date     DATETIME       NOT NULL,
    order_status   ENUM('Placed','Preparing','Out for Delivery',
                        'Delivered','Cancelled') NOT NULL,
    delivery_fee   DECIMAL(6,2)   NOT NULL,
    delivered_at   DATETIME       NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- the delivery address must belong to the customer placing the order
    CONSTRAINT fk_orders_address_owner
        FOREIGN KEY (address_id, customer_id)
        REFERENCES addresses (address_id, customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_agent
        FOREIGN KEY (agent_id) REFERENCES delivery_agents (agent_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 7. order_items : resolves the M : N between orders and menu_items
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INT           NOT NULL AUTO_INCREMENT,
    order_id        INT           NOT NULL,
    item_id         INT           NOT NULL,
    quantity        INT           NOT NULL,
    price_at_order  DECIMAL(8,2)  NOT NULL,       -- price snapshot
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_item
        FOREIGN KEY (item_id) REFERENCES menu_items (item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8. payments : one payment record per order (1 : 1)
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT            NOT NULL AUTO_INCREMENT,
    order_id        INT            NOT NULL,
    amount          DECIMAL(10,2)  NOT NULL,
    payment_method  ENUM('Cash','Card','UPI','Wallet') NOT NULL,
    payment_status  ENUM('Pending','Completed','Failed','Refunded') NOT NULL,
    payment_date    DATETIME       NOT NULL,
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9. reviews : optional feedback for a delivered order (1 : 1)
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
    review_id      INT           NOT NULL AUTO_INCREMENT,
    order_id       INT           NOT NULL,
    food_rating    TINYINT       NOT NULL,
    agent_rating   TINYINT       NULL,
    comment        VARCHAR(500)  NULL,
    review_date    DATETIME      NOT NULL,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Derived data lives in views instead of stored columns
-- ---------------------------------------------------------------------
CREATE VIEW v_order_totals AS
SELECT o.order_id,
       SUM(oi.quantity * oi.price_at_order)                  AS subtotal,
       o.delivery_fee,
       SUM(oi.quantity * oi.price_at_order) + o.delivery_fee AS total_amount
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.delivery_fee;

CREATE VIEW v_restaurant_ratings AS
SELECT r.restaurant_id,
       r.restaurant_name,
       COUNT(rv.review_id)          AS review_count,
       ROUND(AVG(rv.food_rating),1) AS avg_rating
FROM restaurants r
LEFT JOIN orders  o  ON o.restaurant_id = r.restaurant_id
LEFT JOIN reviews rv ON rv.order_id     = o.order_id
GROUP BY r.restaurant_id, r.restaurant_name;
