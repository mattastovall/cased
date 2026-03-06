-- Keep generations.thumbnail_url in sync with xs derivative
-- Assumes image_derivatives.generation_row_id -> generations.id exists

create or replace function public.set_generation_thumbnail_url_from_derivative()
returns trigger
language plpgsql
as $$
begin
  if new.generation_row_id is not null and new.variant = 'xs' then
    update public.generations
      set thumbnail_url = new.url
    where id = new.generation_row_id;
  end if;
  return new;
end;
$$;

drop trigger if exists image_derivatives_set_generation_thumb on public.image_derivatives;
create trigger image_derivatives_set_generation_thumb
after insert or update of url on public.image_derivatives
for each row
execute function public.set_generation_thumbnail_url_from_derivative();

-- Backfill existing generations with missing thumbnail_url from xs derivative
with latest_xs as (
  select distinct on (generation_row_id)
    generation_row_id,
    url
  from public.image_derivatives
  where generation_row_id is not null
    and variant = 'xs'
  order by generation_row_id, created_at desc
)
update public.generations g
set thumbnail_url = lx.url
from latest_xs lx
where g.id = lx.generation_row_id
  and (g.thumbnail_url is null or g.thumbnail_url = '');
;
