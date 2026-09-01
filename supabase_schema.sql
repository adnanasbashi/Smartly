-- SMARTLY - COMPLETE DATABASE + SECURITY
-- Run this whole file once in Supabase SQL Editor.
-- It is safe to re-run: tables/columns/policies are created or replaced without deleting existing rows.

create extension if not exists pgcrypto;

create table if not exists public.countries (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  country_code text,
  phone_code text,
  active boolean default true,
  sort_order int default 0
);

alter table public.countries add column if not exists country_code text;
alter table public.countries add column if not exists phone_code text;
alter table public.countries add column if not exists sort_order int default 0;

create table if not exists public.categories (
  id text primary key,
  name_en text not null,
  name_ar text,
  icon text default '✨',
  active boolean default true,
  sort_order int default 0
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  name_ar text,
  description_en text,
  description_ar text,
  category_id text references public.categories(id),
  retail_price numeric(12,2) default 0,
  stock_quantity int default 0,
  image_url text,
  active boolean default true,
  is_natural boolean default false,
  sort_order int default 0
);

create table if not exists public.bundles (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  description_en text,
  price numeric(12,2) default 0,
  image_url text,
  active boolean default true,
  sort_order int default 0
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  active boolean default true,
  sort_order int default 0
);

create table if not exists public.customer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete cascade not null,
  full_name text not null,
  age int,
  email text,
  country text,
  country_code text,
  phone text not null,
  alternative_phone text,
  street text,
  building text,
  floor text,
  city_area text,
  location_text text,
  latitude double precision,
  longitude double precision,
  default_payment_method text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  phone text not null,
  alternative_phone text,
  email text,
  country text,
  country_code text,
  location text not null,
  street text,
  building text,
  floor text,
  latitude double precision,
  longitude double precision,
  fulfillment_method text default 'Delivery',
  payment_method text,
  subtotal numeric(12,2) default 0,
  total numeric(12,2) default 0,
  status text default 'pending',
  created_at timestamptz default now()
);

alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists country_code text;
alter table public.orders add column if not exists street text;
alter table public.orders add column if not exists building text;
alter table public.orders add column if not exists floor text;
alter table public.orders add column if not exists latitude double precision;
alter table public.orders add column if not exists longitude double precision;
alter table public.orders add column if not exists fulfillment_method text default 'Delivery';
alter table public.orders add column if not exists subtotal numeric(12,2) default 0;

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  quantity int not null,
  unit_price numeric(12,2) not null
);

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id),
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  phone text not null,
  quantity int default 1,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  product_name text,
  rating int check(rating between 1 and 5),
  comment text not null,
  approved boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.special_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  phone text not null,
  country text,
  item_description text,
  image_url text,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists public.site_settings (
  setting_key text primary key,
  setting_value text,
  updated_at timestamptz default now()
);

-- Admin check function. It reads only the admin_users table and avoids RLS recursion.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid() and active = true
  );
$$;

-- Automatically create/update a customer profile after a Supabase Auth signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.customer_profiles
    (user_id, full_name, age, email, country, country_code, phone, alternative_phone,
     street, building, floor, city_area, location_text, latitude, longitude)
  values
    (new.id,
     coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1), 'Customer'),
     nullif(new.raw_user_meta_data->>'age','')::int,
     new.email,
     new.raw_user_meta_data->>'country',
     new.raw_user_meta_data->>'country_code',
     coalesce(new.raw_user_meta_data->>'phone',''),
     new.raw_user_meta_data->>'alternative_phone',
     new.raw_user_meta_data->>'street',
     new.raw_user_meta_data->>'building',
     new.raw_user_meta_data->>'floor',
     new.raw_user_meta_data->>'city_area',
     new.raw_user_meta_data->>'location_text',
     nullif(new.raw_user_meta_data->>'latitude','')::double precision,
     nullif(new.raw_user_meta_data->>'longitude','')::double precision)
  on conflict (user_id) do update set
    full_name=excluded.full_name,
    email=excluded.email,
    phone=excluded.phone,
    updated_at=now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.countries enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.bundles enable row level security;
alter table public.payment_methods enable row level security;
alter table public.customer_profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.reservations enable row level security;
alter table public.reviews enable row level security;
alter table public.special_requests enable row level security;
alter table public.site_settings enable row level security;

-- Drop old policies so this script can be safely re-run.
do $$ declare r record; begin
  for r in select schemaname, tablename, policyname from pg_policies where schemaname='public' and tablename in
    ('countries','categories','products','bundles','payment_methods','customer_profiles','admin_users','orders','order_items','reservations','reviews','special_requests','site_settings')
  loop execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename); end loop;
end $$;

-- Public storefront reads.
create policy public_read_countries on public.countries for select to anon, authenticated using (active=true);
create policy public_read_categories on public.categories for select to anon, authenticated using (active=true);
create policy public_read_products on public.products for select to anon, authenticated using (active=true);
create policy public_read_bundles on public.bundles for select to anon, authenticated using (active=true);
create policy public_read_payments on public.payment_methods for select to anon, authenticated using (active=true);
create policy public_read_reviews on public.reviews for select to anon, authenticated using (approved=true);

-- Customer actions.
create policy public_insert_orders on public.orders for insert to anon, authenticated with check (true);
create policy public_insert_order_items on public.order_items for insert to anon, authenticated with check (true);
create policy public_insert_reservations on public.reservations for insert to anon, authenticated with check (true);
create policy public_insert_special_requests on public.special_requests for insert to anon, authenticated with check (true);
create policy authenticated_insert_reviews on public.reviews for insert to authenticated with check (auth.uid() = user_id);

-- Customer can manage only their own profile.
create policy customer_profile_select on public.customer_profiles for select to authenticated using (auth.uid() = user_id or public.is_admin());
create policy customer_profile_insert on public.customer_profiles for insert to authenticated with check (auth.uid() = user_id);
create policy customer_profile_update on public.customer_profiles for update to authenticated using (auth.uid() = user_id or public.is_admin()) with check (auth.uid() = user_id or public.is_admin());

-- Admin full CRUD. This is the part that prevents the previous 401/write failure.
create policy admin_all_countries on public.countries for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_categories on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_products on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_bundles on public.bundles for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_payments on public.payment_methods for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_profiles on public.customer_profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_orders on public.orders for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_order_items on public.order_items for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_reservations on public.reservations for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_reviews on public.reviews for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_special on public.special_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_all_settings on public.site_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admin_read_admin_users on public.admin_users for select to authenticated using (public.is_admin());

-- Storage for special-request pictures.
insert into storage.buckets (id, name, public)
values ('special-requests','special-requests',true)
on conflict (id) do update set public=true;

drop policy if exists special_request_upload on storage.objects;
drop policy if exists special_request_public_read on storage.objects;
drop policy if exists special_request_admin_delete on storage.objects;
create policy special_request_upload on storage.objects for insert to anon, authenticated with check (bucket_id='special-requests');
create policy special_request_public_read on storage.objects for select to anon, authenticated using (bucket_id='special-requests');
create policy special_request_admin_delete on storage.objects for delete to authenticated using (bucket_id='special-requests' and public.is_admin());

-- Countries.
insert into public.countries(name,country_code,phone_code,sort_order) values
('Lebanon','LB','+961',1),('Syria','SY','+963',2),('United Arab Emirates','AE','+971',3),('Saudi Arabia','SA','+966',4),('Jordan','JO','+962',5),('Qatar','QA','+974',6)
on conflict(name) do update set country_code=excluded.country_code,phone_code=excluded.phone_code;

-- Categories agreed for the Smartly concept.
insert into public.categories(id,name_en,name_ar,icon,sort_order) values
('smart-tools','Smart Tools','أدوات ذكية','🧰',1),
('home','Home & Organization','المنزل والتنظيم','🏠',2),
('kitchen','Kitchen','المطبخ','🍳',3),
('cleaning','Cleaning','التنظيف','🧽',4),
('wellness','Wellness','العناية والرفاهية','💆',5),
('car-travel','Car & Travel','السيارة والسفر','🚗',6),
('natural','Natural Products','منتجات طبيعية','🌿',7)
on conflict(id) do update set name_en=excluded.name_en,name_ar=excluded.name_ar,icon=excluded.icon,active=true;

-- Payment methods requested by the owner.
insert into public.payment_methods(name,sort_order) values
('Whish Money',1),('OMT',2),('Cash on Delivery',3),('Pickup',4)
on conflict(name) do update set active=true,sort_order=excluded.sort_order;

-- Initial products agreed for the first catalogue. Prices/stock can be changed from Admin.
insert into public.products(name_en,description_en,category_id,retail_price,stock_quantity,is_natural,active,sort_order) values
('LED / Red Light Therapy Face Mask','At-home LED beauty and skincare device.','wellness',39,0,false,true,1),
('Gua Sha / Facial Wellness Tool','Smooth natural-style facial massage tool.','wellness',12,0,false,true,2),
('Mini / Travel Massage Gun','Compact rechargeable massage device for everyday use and travel.','wellness',29,0,false,true,3),
('Posture Corrector','Adjustable posture support designed for everyday sitting and desk use.','wellness',18,0,false,true,4),
('Magnetic Phone Accessories','Practical magnetic phone mounting and accessory solutions.','smart-tools',15,0,false,true,5),
('Natural Food & Herbs','Natural pantry products and herbs selected for everyday use.','natural',10,0,true,true,6)
on conflict do nothing;

insert into public.site_settings(setting_key,setting_value) values
('brand_name','Smartly'),
('tagline','Smart solutions for everyday life.'),
('return_policy','Damaged or materially incorrect stocked items must be reported within 2 days of delivery.'),
('special_order_policy','Special requests normally require 2–4 weeks and the final delivery date is confirmed by our team on WhatsApp.'),
('delivery_policy','Delivery dates are confirmed by our team on WhatsApp. Requested delivery is minimum 3 days after the order.'),
('whatsapp','9613080365')
on conflict(setting_key) do nothing;

-- Product image storage for admin uploads.
insert into storage.buckets (id,name,public) values ('product-images','product-images',true)
on conflict (id) do update set public=true;
drop policy if exists product_image_upload on storage.objects;
drop policy if exists product_image_public_read on storage.objects;
drop policy if exists product_image_admin_delete on storage.objects;
create policy product_image_upload on storage.objects for insert to authenticated with check (bucket_id='product-images' and public.is_admin());
create policy product_image_public_read on storage.objects for select to anon,authenticated using (bucket_id='product-images');
create policy product_image_admin_delete on storage.objects for delete to authenticated using (bucket_id='product-images' and public.is_admin());
