create table exports (
  id uuid primary key default gen_random_uuid(),
  project_id text not null,
  width int not null,
  height int not null,
  fps int not null,
  duration double precision not null,
  audio_url text,
  status text not null default 'queued',
  output_url text,
  error_message text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);;
