create table if not exists public.dev_urls (
  id uuid primary key default gen_random_uuid(),
  user_id text,
  email text,
  note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index if not exists dev_urls_email_key on public.dev_urls (lower(email));
create index if not exists dev_urls_user_idx on public.dev_urls (user_id);

alter table public.dev_urls enable row level security;

-- Only service role can manage/read by default
drop policy if exists "service manages dev_urls" on public.dev_urls;
create policy "service manages dev_urls"
  on public.dev_urls
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');;
