
create table styles (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  slug       text not null unique,
  thumb_url  text not null,
  json       jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table generations (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id),
  style_id   uuid references styles(id),
  prompt     text,
  image_url  text,
  created_at timestamptz default now()
);

alter table generations enable row level security;
create policy "Users can read their gens" on generations
  for select using ( auth.uid() = user_id );
create policy "Users can insert gens" on generations
  for insert with check ( auth.uid() = user_id );
;
