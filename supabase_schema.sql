-- SMARTLY INITIAL DATABASE
create extension if not exists pgcrypto;

create table if not exists countries(id uuid primary key default gen_random_uuid(), name text unique not null, active boolean default true, sort_order int default 0);
create table if not exists categories(id text primary key, name_en text not null, name_ar text, icon text default '✨', active boolean default true, sort_order int default 0);
create table if not exists products(id uuid primary key default gen_random_uuid(), name_en text not null, name_ar text, description_en text, description_ar text, category_id text references categories(id), retail_price numeric(12,2) default 0, stock_quantity int default 0, image_url text, active boolean default true, is_natural boolean default false, sort_order int default 0);
create table if not exists bundles(id uuid primary key default gen_random_uuid(), name_en text not null, description_en text, price numeric(12,2) default 0, image_url text, active boolean default true, sort_order int default 0);
create table if not exists payment_methods(id uuid primary key default gen_random_uuid(), name text unique not null, active boolean default true, sort_order int default 0);
create table if not exists orders(id uuid primary key default gen_random_uuid(), order_number text unique not null, name text not null, phone text not null, alternative_phone text, email text, country text, location text not null, payment_method text, subtotal numeric(12,2) default 0, total numeric(12,2) default 0, status text default 'pending', created_at timestamptz default now());
create table if not exists order_items(id uuid primary key default gen_random_uuid(), order_id uuid references orders(id) on delete cascade, product_id uuid references products(id), quantity int not null, unit_price numeric(12,2) not null);
create table if not exists reservations(id uuid primary key default gen_random_uuid(), product_id uuid references products(id), name text not null, phone text not null, quantity int default 1, status text default 'pending', created_at timestamptz default now());
create table if not exists reviews(id uuid primary key default gen_random_uuid(), customer_name text not null, product_name text, rating int check(rating between 1 and 5), comment text not null, approved boolean default false, created_at timestamptz default now());
create table if not exists special_requests(id uuid primary key default gen_random_uuid(), name text not null, phone text not null, country text, item_description text, image_url text, status text default 'pending', created_at timestamptz default now());
create table if not exists site_settings(id uuid primary key default gen_random_uuid(), setting_key text unique not null, setting_value text, updated_at timestamptz default now());

insert into countries(name,sort_order) values ('Lebanon',1),('Syria',2) on conflict(name) do nothing;
insert into categories(id,name_en,name_ar,icon,sort_order) values
('home','Home','المنزل','🏠',1),('kitchen','Kitchen','المطبخ','🍳',2),('cleaning','Cleaning','التنظيف','🧽',3),('smart','Smart Home','المنزل الذكي','💡',4),('wellness','Wellness','العناية','💆',5),('natural','Natural Products','منتجات طبيعية','🌿',6),('car','Car & Travel','السيارة والسفر','🚗',7)
on conflict(id) do nothing;
insert into payment_methods(name,sort_order) values ('Cash on Delivery',1),('Pickup',2),('Bank Transfer',3) on conflict(name) do nothing;

alter table countries enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table bundles enable row level security;
alter table payment_methods enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table reservations enable row level security;
alter table reviews enable row level security;
alter table special_requests enable row level security;
alter table site_settings enable row level security;

drop policy if exists public_read_countries on countries;
create policy public_read_countries on countries for select using (active=true);
drop policy if exists public_read_categories on categories;
create policy public_read_categories on categories for select using (active=true);
drop policy if exists public_read_products on products;
create policy public_read_products on products for select using (active=true);
drop policy if exists public_read_bundles on bundles;
create policy public_read_bundles on bundles for select using (active=true);
drop policy if exists public_read_payments on payment_methods;
create policy public_read_payments on payment_methods for select using (active=true);
drop policy if exists public_read_reviews on reviews;
create policy public_read_reviews on reviews for select using (approved=true);

drop policy if exists public_insert_orders on orders;
create policy public_insert_orders on orders for insert with check (true);
drop policy if exists public_insert_order_items on order_items;
create policy public_insert_order_items on order_items for insert with check (true);
drop policy if exists public_insert_reservations on reservations;
create policy public_insert_reservations on reservations for insert with check (true);
drop policy if exists public_insert_reviews on reviews;
create policy public_insert_reviews on reviews for insert with check (true);
drop policy if exists public_insert_special_requests on special_requests;
create policy public_insert_special_requests on special_requests for insert with check (true);

-- IMPORTANT: admin UPDATE/DELETE policies should be added only after creating an authenticated admin role.
