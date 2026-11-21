create extension if not exists pgcrypto;
create table if not exists public.catalogs(id uuid primary key default gen_random_uuid(),name text not null,emoji text default '🧁',image_url text,sort_order int not null default 0,created_at timestamptz default now());
create table if not exists public.products(id uuid primary key default gen_random_uuid(),catalog_id uuid not null references public.catalogs(id) on delete cascade,name text not null,description text default '',text_content text default '',content_type text not null default 'text' check(content_type in ('text','photo')),image_url text,price numeric(14,2) not null default 0,status text not null default 'available' check(status in ('available','sold')),testimonial_image_url text,created_at timestamptz default now());
create table if not exists public.reviews(id uuid primary key default gen_random_uuid(),username text not null,email text not null,review_text text not null,rating int not null check(rating between 1 and 5),is_visible boolean not null default true,created_at timestamptz default now());
create table if not exists public.customers(id uuid primary key default gen_random_uuid(),username text not null,email text not null,phone text not null,created_at timestamptz default now());
create table if not exists public.store_settings(id uuid primary key default gen_random_uuid(),label text not null,url text not null,created_at timestamptz default now());
alter table public.catalogs enable row level security; alter table public.products enable row level security; alter table public.reviews enable row level security; alter table public.customers enable row level security; alter table public.store_settings enable row level security;
create policy "catalog public read" on public.catalogs for select to anon,authenticated using(true);
create policy "product public read" on public.products for select to anon,authenticated using(true);
create policy "review public insert" on public.reviews for insert to anon,authenticated with check(is_visible=true and rating between 1 and 5);
create view public.public_reviews with (security_barrier=true) as
 select id, username, review_text, rating, created_at
 from public.reviews where is_visible=true;
grant select on public.public_reviews to anon, authenticated;
create policy "settings public read" on public.store_settings for select to anon,authenticated using(true);
create policy "customer insert" on public.customers for insert to anon,authenticated with check(true);
create policy "admin catalogs" on public.catalogs for all to authenticated using((auth.jwt()->'app_metadata'->>'role')='admin') with check((auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin products" on public.products for all to authenticated using((auth.jwt()->'app_metadata'->>'role')='admin') with check((auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin reviews" on public.reviews for all to authenticated using((auth.jwt()->'app_metadata'->>'role')='admin') with check((auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin customers read" on public.customers for select to authenticated using((auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin settings" on public.store_settings for all to authenticated using((auth.jwt()->'app_metadata'->>'role')='admin') with check((auth.jwt()->'app_metadata'->>'role')='admin');
insert into public.catalogs(name,emoji,sort_order) select 'Katalog '||lpad(n::text,2,'0'),(array['🧁','🐚','🫧','🌊','🍰','🪸','🍓','🦪','🎀','✨'])[n],n from generate_series(1,10)n where not exists(select 1 from public.catalogs);
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('loopyna-media','loopyna-media',true,5242880,array['image/jpeg','image/png','image/webp','image/gif']) on conflict(id) do nothing;
create policy "public read loopyna media" on storage.objects for select to anon,authenticated using(bucket_id='loopyna-media');
create policy "admin upload loopyna media" on storage.objects for insert to authenticated with check(bucket_id='loopyna-media' and (auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin update loopyna media" on storage.objects for update to authenticated using(bucket_id='loopyna-media' and (auth.jwt()->'app_metadata'->>'role')='admin') with check(bucket_id='loopyna-media' and (auth.jwt()->'app_metadata'->>'role')='admin');
create policy "admin delete loopyna media" on storage.objects for delete to authenticated using(bucket_id='loopyna-media' and (auth.jwt()->'app_metadata'->>'role')='admin');
