-- Preset workflow schema aligned with docs/easymode/db.md
create extension if not exists "pgcrypto";

-- Enums (idempotent via DO blocks)
DO $$ BEGIN
  CREATE TYPE preset_item_status AS ENUM ('published', 'draft', 'in_review', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE preset_submission_status AS ENUM ('pending', 'approved', 'rejected', 'needs_changes');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE preset_job_status AS ENUM ('queued', 'running', 'completed', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Updated at helper
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Tables
create table if not exists public.preset_types (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  is_active boolean not null default true,
  display_order integer,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Triggers (recreate to be safe)
drop trigger if exists preset_types_updated_at on public.preset_types;
create trigger preset_types_updated_at
before update on public.preset_types
for each row
execute function public.set_updated_at();

create table if not exists public.preset_categories (
  id uuid primary key default gen_random_uuid(),
  preset_type_id uuid not null references public.preset_types(id) on delete cascade,
  slug text not null,
  label text not null,
  description text,
  icon_key text,
  display_order integer,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (preset_type_id, slug)
);
create index if not exists preset_categories_type_display_idx
  on public.preset_categories (preset_type_id, display_order nulls last);
drop trigger if exists preset_categories_updated_at on public.preset_categories;
create trigger preset_categories_updated_at
before update on public.preset_categories
for each row
execute function public.set_updated_at();

create table if not exists public.preset_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.preset_categories(id) on delete cascade,
  slug text not null,
  title text not null,
  subtitle text,
  description text,
  image_url text,
  tags text[] not null default '{}',
  config jsonb not null default '{}'::jsonb,
  edit boolean not null default false,
  status preset_item_status not null default 'draft',
  is_default boolean not null default false,
  metadata jsonb,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  display_order integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_id, slug)
);
create index if not exists preset_items_category_status_idx
  on public.preset_items (category_id, status, display_order nulls last);
create index if not exists preset_items_tags_idx
  on public.preset_items using gin(tags);
drop trigger if exists preset_items_updated_at on public.preset_items;
create trigger preset_items_updated_at
before update on public.preset_items
for each row
execute function public.set_updated_at();

create table if not exists public.preset_item_versions (
  id bigserial primary key,
  item_id uuid not null references public.preset_items(id) on delete cascade,
  data_snapshot jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  change_type text not null default 'edit',
  created_at timestamptz not null default now()
);
create index if not exists preset_item_versions_item_idx
  on public.preset_item_versions (item_id, created_at desc);

create table if not exists public.preset_item_submissions (
  id uuid primary key default gen_random_uuid(),
  preset_type_id uuid not null references public.preset_types(id) on delete cascade,
  category_id uuid references public.preset_categories(id),
  proposed_item jsonb not null,
  submitted_by uuid not null references auth.users(id),
  moderation_status preset_submission_status not null default 'pending',
  moderated_by uuid references auth.users(id),
  moderated_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists preset_item_submissions_status_idx
  on public.preset_item_submissions (moderation_status, created_at desc);

create table if not exists public.generation_preset_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  workflow_id text not null,
  model_id text not null,
  prompt text not null,
  negative_prompt text,
  params jsonb not null default '{}'::jsonb,
  preset_ids uuid[] not null default '{}',
  metadata jsonb,
  prompt_fragments jsonb not null,
  result jsonb,
  error text,
  status preset_job_status not null default 'queued',
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz
);
create index if not exists generation_preset_jobs_user_idx
  on public.generation_preset_jobs (user_id, created_at desc);
drop trigger if exists generation_preset_jobs_updated_at on public.generation_preset_jobs;
create trigger generation_preset_jobs_updated_at
before update on public.generation_preset_jobs
for each row
execute function public.set_updated_at();

-- RLS
alter table public.preset_types enable row level security;
alter table public.preset_categories enable row level security;
alter table public.preset_items enable row level security;
alter table public.preset_item_versions enable row level security;
alter table public.preset_item_submissions enable row level security;
alter table public.generation_preset_jobs enable row level security;

-- Policies (drop/create for idempotency)
-- preset_types
DROP POLICY IF EXISTS "Allow read on preset_types" ON public.preset_types;
CREATE POLICY "Allow read on preset_types"
  ON public.preset_types
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Service role manages preset_types" ON public.preset_types;
CREATE POLICY "Service role manages preset_types"
  ON public.preset_types
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- preset_categories
DROP POLICY IF EXISTS "Allow read on preset_categories" ON public.preset_categories;
CREATE POLICY "Allow read on preset_categories"
  ON public.preset_categories
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Service role manages preset_categories" ON public.preset_categories;
CREATE POLICY "Service role manages preset_categories"
  ON public.preset_categories
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- preset_items
DROP POLICY IF EXISTS "Allow read published preset_items" ON public.preset_items;
CREATE POLICY "Allow read published preset_items"
  ON public.preset_items
  FOR SELECT
  USING (status = 'published' OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role manages preset_items" ON public.preset_items;
CREATE POLICY "Service role manages preset_items"
  ON public.preset_items
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- preset_item_versions
DROP POLICY IF EXISTS "Service role manages preset_item_versions" ON public.preset_item_versions;
CREATE POLICY "Service role manages preset_item_versions"
  ON public.preset_item_versions
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- preset_item_submissions
DROP POLICY IF EXISTS "Submitters can insert preset submissions" ON public.preset_item_submissions;
CREATE POLICY "Submitters can insert preset submissions"
  ON public.preset_item_submissions
  FOR INSERT
  WITH CHECK (auth.uid() = submitted_by);

DROP POLICY IF EXISTS "Submitters read own preset submissions" ON public.preset_item_submissions;
CREATE POLICY "Submitters read own preset submissions"
  ON public.preset_item_submissions
  FOR SELECT
  USING (auth.uid() = submitted_by OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Submitters update pending submissions" ON public.preset_item_submissions;
CREATE POLICY "Submitters update pending submissions"
  ON public.preset_item_submissions
  FOR UPDATE
  USING (auth.uid() = submitted_by AND moderation_status = 'pending')
  WITH CHECK (auth.uid() = submitted_by);

DROP POLICY IF EXISTS "Service role manages preset submissions" ON public.preset_item_submissions;
CREATE POLICY "Service role manages preset submissions"
  ON public.preset_item_submissions
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- generation_preset_jobs
DROP POLICY IF EXISTS "Users read own preset jobs" ON public.generation_preset_jobs;
CREATE POLICY "Users read own preset jobs"
  ON public.generation_preset_jobs
  FOR SELECT
  USING (auth.uid() = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role manages preset jobs" ON public.generation_preset_jobs;
CREATE POLICY "Service role manages preset jobs"
  ON public.generation_preset_jobs
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');;
