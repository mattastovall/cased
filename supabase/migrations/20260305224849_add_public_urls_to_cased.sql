alter table public."CASED"
add column if not exists input_image_urls text[] not null default '{}'::text[],
add column if not exists output_image_urls text[] not null default '{}'::text[],
add column if not exists output_video_urls text[] not null default '{}'::text[];

update public."CASED"
set
  input_image_urls = coalesce(
    (
      select array_agg(
        'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/' || path
        order by path
      )
      from unnest(input_image_paths) as path
    ),
    array[]::text[]
  ),
  output_image_urls = coalesce(
    (
      select array_agg(
        'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/' || path
        order by path
      )
      from unnest(output_image_paths) as path
    ),
    array[]::text[]
  ),
  output_video_urls = case request_name
    when 'chestplate-loop-video' then array[
      'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/cased/output-videos/537596987758.mp4'
    ]::text[]
    when 'chestplate-reveal-video' then array[
      'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/cased/output-videos/1b2527b77161.mp4'
    ]::text[]
    when 'chestplate-strike-video' then array[
      'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/cased/output-videos/5a4b4428437c.mp4'
    ]::text[]
    when 'chestplate-twist-video' then array[
      'https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/cased/output-videos/4414108e274f.mp4'
    ]::text[]
    else array[]::text[]
  end;
