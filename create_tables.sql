CREATE DATABASE ecommerce_db;
use ecommerce_db;

create table customers
(
    customer_id    int primary key AUTO_INCREMENT,
    first_name     varchar(50),
    last_name      varchar(50),
    email          varchar(100) unique,
    phone          varchar(20),
    city           varchar(50),
    creation_time  date,
    loyalty_points int
);

create table orders
(
    order_id         int primary key AUTO_INCREMENT,
    customer_id      int,
    foreign key (customer_id) references customers (customer_id),
    order_date       date,
    status           enum (
        'Pending',
        'Shipped',
        'Delivered',
        'Canceled'),
    payment_method   enum (
        'Credit Card',
        'Debit Card',
        'Cash',
        'Mobile Wallets',
        'PayPal',
        'Bank Transfer'
        ),
    shipping_address varchar(200),
    total_amount     decimal(10, 2)
);

create table suppliers
(
    supplier_id  int primary key AUTO_INCREMENT,
    name         varchar(100),
    contact_name varchar(100),
    email        varchar(100),
    phone        varchar(20),
    country      varchar(50),
    rating       decimal(3, 2)
);

create table products
(
    product_id     int primary key AUTO_INCREMENT,
    name           varchar(100),
    description    text,
    price          decimal(10, 2),
    category       varchar(50),
    stock_quantity int,
    supplier_id    int,
    foreign key (supplier_id) references suppliers (supplier_id),
    created_at     date
);

create table order_items
(
    order_item_id int primary key AUTO_INCREMENT,
    order_id      int references orders (order_id),
    foreign key (order_id) references orders (order_id),
    product_id    int references products (product_id),
    foreign key (product_id) references products (product_id),
    quantity      int,
    unit_price    decimal(10, 2),
    discount      decimal(5, 2)
);