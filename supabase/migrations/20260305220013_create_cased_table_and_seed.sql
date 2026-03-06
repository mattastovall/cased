create table if not exists public."CASED" (
  id bigserial primary key,
  request_name text not null unique,
  source_log text not null,
  endpoint text,
  request_id text,
  request_payload jsonb not null,
  input_image_paths text[] not null default '{}'::text[],
  output_image_paths text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-ansysSimulation-image', 'chestplate-ansysSimulation-image.txt', 'fal-ai/nano-banana-2/edit', 'ebb68d49-5118-4cad-8401-d92d83eb0bcd', $p0${"prompt":"show this exact model in ANSYS (LS-DYNA / Mechanical) undergoing energy absorption and deformation simulations, same angle as reference","image_urls":["https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/images/1772731459020-26fccc6d-3b74-44c1-a4c9-8654355aab16%20(1).png"],"num_images":1,"aspect_ratio":"16:9","resolution":"1K","output_format":"png","safety_tolerance":"4","limit_generations":true,"enable_web_search":false,"sync_mode":false,"seed":1523836945}$p0$::jsonb, ARRAY['cased/input-images/2d81baecb86f.png']::text[], ARRAY['cased/output-images/c857f626ea36.png']::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-from-Ref-image', 'chestplate-from-Ref-image.txt', 'fal-ai/nano-banana-2/edit', 'd1a7f4ea-606b-484e-b79f-aa9317a0e68c', $p1${"prompt":"generate a 3d rendering of this chest padding on a black background, the material of the padding should grey made out of a dense foam, base the padding pattern and shape on the attached diagram. Use the blue padding render as a reference for render camera angle and lighting. The padding should be in the shape of the breastplate in the photo. ","image_urls":["https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/images/1772729788027-image.png","https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/images/1772730565894-image.png","https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/images/1772730438614-image.png"],"num_images":1,"aspect_ratio":"16:9","resolution":"1K","output_format":"png","safety_tolerance":"4","limit_generations":true,"enable_web_search":false,"sync_mode":false,"seed":1523836946}$p1$::jsonb, ARRAY['cased/input-images/132652a143c6.png','cased/input-images/25577e8cccff.png','cased/input-images/3c3abe49499b.png']::text[], ARRAY['cased/output-images/62e8a79adbfc.png']::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-labsetting-image', 'chestplate-labsetting-image.txt', 'fal-ai/nano-banana-2/edit', '0ca69035-8cdd-448f-aa33-8dbef3148b14', $p2${"prompt":"show this exact chest plate padding  undergoing impact tests in a lab setting, close up, .heic, slowmo. empty background behind plate","image_urls":["https://vxdmipbkwsbsmnxzdppz.supabase.co/storage/v1/object/public/images/1772731459020-26fccc6d-3b74-44c1-a4c9-8654355aab16%20(1).png"],"num_images":1,"aspect_ratio":"16:9","resolution":"2K","output_format":"png","safety_tolerance":"4","limit_generations":true,"enable_web_search":false,"sync_mode":false,"seed":1523836946}$p2$::jsonb, ARRAY['cased/input-images/2d81baecb86f.png']::text[], ARRAY['cased/output-images/5bb3c8a47718.png']::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-loop-video', 'chestplate-loop-video.txt', 'fal-ai/kling-video/v3/pro/image-to-video', 'e9c02029-58cf-4fcd-bbb1-57fb61d35c02', $p3${"prompt":"Animate the chestplate twisting and flexing in mid-air to showcase its extreme flexibility, with the diamond-shaped cells shifting, compressing, and stretching as the material warps before it naturally returns to its original flat position","multi_prompt":null,"start_image_url":"https://v3b.fal.media/files/b/0a9104e2/Tcrj3_J6ECSxmXkH6F98d_26fccc6d-3b74-44c1-a4c9-8654355aab16%20(1).png","duration":"6","generate_audio":true,"elements":[],"shot_type":"customize","aspect_ratio":"16:9","negative_prompt":"blur, distort, and low quality","cfg_scale":0.5,"end_image_url":"https://v3b.fal.media/files/b/0a9104e2/gdTVS0UfsbDGZKuqojv8Q_26fccc6d-3b74-44c1-a4c9-8654355aab16.png"}$p3$::jsonb, ARRAY['cased/input-images/0692aa24c5cf.png','cased/input-images/21bf55cddf6a.png']::text[], ARRAY[]::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-reveal-video', 'chestplate-reveal-video.txt', 'fal-ai/kling-video/v3/pro/image-to-video', '6330136a-2989-43e1-82f3-fbafeae8a637', $p4${"prompt":"reveal the black chest pad by materializing the chest piece from the outward in, the effect focus on the diamond structure of the foam. Instead of the plate appearing as one solid chunk, it assembles cell-by-cell","multi_prompt":null,"start_image_url":"https://v3b.fal.media/files/b/0a90fbf2/D88eK8C6brw--yiiYh1nt_Frame%201533209345.png","duration":"4","generate_audio":true,"elements":[],"shot_type":"customize","aspect_ratio":"16:9","negative_prompt":"blur, distort, and low quality","cfg_scale":0.5,"end_image_url":"https://v3b.fal.media/files/b/0a90fbf2/LwVPYoAAA23RQkuN4XF1n_26fccc6d-3b74-44c1-a4c9-8654355aab16%20(1).png"}$p4$::jsonb, ARRAY['cased/input-images/6436b144ee26.png','cased/input-images/ff72013b2fde.png']::text[], ARRAY[]::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-strike-video', 'chestplate-strike-video.txt', 'fal-ai/kling-video/v3/pro/image-to-video', 'e194240a-6686-4d76-a4b4-8fedecaa4fed', $p5${"prompt":"show the impact instrument strike the center of the chestplate causing a slighty ripple in the center, slow mo","multi_prompt":null,"start_image_url":"https://v3b.fal.media/files/b/0a910023/cmEGQB2CIExyWTMvv5MVu_ab2d11f0-9c90-4d0a-b790-74d97a812a08.png","duration":"4","generate_audio":true,"elements":[],"shot_type":"customize","aspect_ratio":"16:9","negative_prompt":"blur, distort, and low quality","cfg_scale":0.5,"end_image_url":"https://v3b.fal.media/files/b/0a910023/HCcl6NqoZ8KCwicsJ2hXt_e6a94147-d01a-42c2-9f91-5f60b30671d9%20(3).png"}$p5$::jsonb, ARRAY['cased/input-images/164503e98ef4.png','cased/input-images/8e948f06d96b.png']::text[], ARRAY[]::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();

insert into public."CASED" (request_name, source_log, endpoint, request_id, request_payload, input_image_paths, output_image_paths)
values ('chestplate-twist-video', 'chestplate-twist-video.txt', 'fal-ai/kling-video/v3/pro/image-to-video', 'a0e9b428-f67b-476b-a361-bb4ce7a47737', $p6${"prompt":"Animate the chestplate twisting and flexing in mid-air to showcase its extreme flexibility, with the diamond-shaped cells shifting, compressing, and stretching as the material warps before it naturally returns to its original flat position","multi_prompt":null,"start_image_url":"https://v3b.fal.media/files/b/0a910519/oQBsfXZPu2T5eITFaa-WN_26fccc6d-3b74-44c1-a4c9-8654355aab16%20(1).png","duration":"6","generate_audio":true,"elements":[],"shot_type":"customize","aspect_ratio":"16:9","negative_prompt":"blur, distort, and low quality","cfg_scale":0.5,"end_image_url":"https://v3b.fal.media/files/b/0a910519/7X4lPTvibOKaDt4Ulv_Z8_26fccc6d-3b74-44c1-a4c9-8654355aab16.png"}$p6$::jsonb, ARRAY['cased/input-images/8e7a2e0caba0.png','cased/input-images/b98284b35f55.png']::text[], ARRAY[]::text[])
on conflict (request_name) do update set
  source_log = excluded.source_log,
  endpoint = excluded.endpoint,
  request_id = excluded.request_id,
  request_payload = excluded.request_payload,
  input_image_paths = excluded.input_image_paths,
  output_image_paths = excluded.output_image_paths,
  updated_at = now();
