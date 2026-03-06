-- Add canonical generation FK to image_derivatives
alter table public.image_derivatives
  add column if not exists generation_row_id bigint;

create index if not exists image_derivatives_generation_row_id_idx
  on public.image_derivatives (generation_row_id);

-- One derivative per variant per generation row (partial to allow legacy rows without FK)
create unique index if not exists image_derivatives_generation_row_id_variant_uidx
  on public.image_derivatives (generation_row_id, variant)
  where generation_row_id is not null;

-- FK (only if missing)
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'image_derivatives_generation_row_id_fkey'
  ) then
    alter table public.image_derivatives
      add constraint image_derivatives_generation_row_id_fkey
      foreign key (generation_row_id) references public.generations(id)
      on delete cascade;
  end if;
end$$;

-- Optional: stop sending synthetic id by giving id a default
alter table public.image_derivatives
  alter column id set default gen_random_uuid()::text;;
