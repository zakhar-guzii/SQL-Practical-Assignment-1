import random
import uuid
import mysql.connector
from faker import Faker

fake = Faker()

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    passwd="MySQL_Student123",
    database="ecommerce_db"
)
cursor = conn.cursor(buffered=True) #обʼєкт, що буде відправляти SQL-запити до бази даних

def generate_customer():
    first_name = fake.first_name()
    last_name = fake.last_name()
    email = fake.unique.email()
    phone = fake.phone_number()[:20]
    city = fake.city()
    creation_time = fake.date_this_decade().strftime("%Y-%m-%d")
    loyalty_points = random.randint(0, 1000)
    return first_name, last_name, email, phone, city, creation_time, loyalty_points

def insert_customers(n):
    sql = """
        INSERT INTO customers
        (first_name, last_name, email, phone, city, creation_time, loyalty_points)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    for _ in range(n):
        cursor.execute(sql, generate_customer())
    conn.commit()
insert_customers(5000)

order_statuses = ['Pending', 'Shipped', 'Delivered', 'Canceled']
payment_methods = ['Credit Card', 'Debit Card', 'Cash', 'Mobile Wallets', 'PayPal', 'Bank Transfer']

def generate_order(customer_id):
    customer_id = random.choice(customer_id)
    order_date = fake.date_this_decade().strftime("%Y-%m-%d")
    status = random.choice(order_statuses)
    payment_methods = random.choice(payment_methods)
    shipping_address = fake.address().replace('\n', ', ')
    total_amount = round(random.randint(5, 10000),2)
    return customer_id, order_date, status, payment_methods, shipping_address, total_amount

def insert_orders(m, customer_id):
    sql = """
          INSERT INTO orders
          (customer_id, order_date, status, payment_method, shipping_address, total_amount)
          VALUES (%s, %s, %s, %s, %s, %s) \
          """
    for _ in range(m):
        order = generate_order(customer_id)
        cursor.execute(sql, order)
    conn.commit()

insert_orders(50000, uuid.uuid4())

def generate_supplier():
    name = fake.company()
    contact_name = fake.name()
    email = fake.unique.company_email()
    phone = fake.phone_number()[:20]
    country = fake.country()
    rating = round(random.uniform(0, 5), 2)
    return name, contact_name, email, phone, country, rating

def insert_suppliers(k):
    sql = """
          INSERT INTO suppliers
              (name, contact_name, email, phone, country, rating)
          VALUES (%s, %s, %s, %s, %s, %s) \
          """
    for _ in range(k):
        supplier = generate_supplier()
        cursor.execute(sql, supplier)
    conn.commit()

insert_suppliers(100)

categories = [
    "Electronics", "Clothing", "Books", "Home & Kitchen",
    "Sports", "Toys", "Beauty", "Automotive", "Furniture"
]

def generate_product():
    name = " ".join(fake.words(2)).title()
    description = fake.text(max_nb_chars=200)
    price = round(random.uniform(1, 100000), 2)
    category = random.choice(categories)
    stock_quantity = random.randint(0, 1000)
    discount = round(random.uniform(0, 66), 2)
    return name, description, price, category, stock_quantity, discount

def insert_products(k):
    sql = """
          INSERT INTO products
              (name, description, price, category, stock_quantity, discount)
          Values (%s, %s, %s, %s, %s, %s) \
          """
    for _ in range(k):
        product = generate_product()
        cursor.execute(sql, product)
    conn.commit()

insert_products(2000)

def generate_order_item(order_ids, product_ids, product_prices):
    order_id = random.choice(order_ids)
    product_id = random.choice(product_ids)
    quantity = random.randint(1, 10)
    unit_price = product_prices[product_id]
    discount = round(random.uniform(0, 50), 2)  # наприклад, до 50%
    return order_id, product_id, quantity, unit_price, discount

def insert_order_items(n, order_ids, product_ids, product_prices):
    sql = """
        INSERT INTO order_items
        (order_id, product_id, quantity, unit_price, discount)
        VALUES (%s, %s, %s, %s, %s)
    """
    for _ in range(n):
        order_item = generate_order_item(order_ids, product_ids, product_prices)
        cursor.execute(sql, order_item)
    conn.commit()


n = random.randint(50000, 20000)
insert_order_items(n, order_ids, product_ids, product_prices)
