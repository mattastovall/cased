CREATE TABLE IF NOT EXISTS assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id text NOT NULL,
  type text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL,
  has_video boolean NOT NULL DEFAULT false,
  has_audio boolean NOT NULL DEFAULT false,
  storage_provider text NOT NULL DEFAULT 'supabase',
  bucket text NOT NULL,
  object_key text NOT NULL,
  cdn_url text NOT NULL,
  checksum_sha256 text NOT NULL,
  status text NOT NULL DEFAULT 'uploaded',
  access_level text NOT NULL DEFAULT 'private',
  metadata jsonb DEFAULT '{}'::jsonb,
  transcripts jsonb DEFAULT '{"tracks": []}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  -- New columns from implementation plan
  short_description text,
  description text,
  -- Additional columns from plan
  created_by uuid,
  original_uri text,
  license text,
  source text,
  -- Media metadata columns
  width_px integer,
  height_px integer,
  duration_ms integer,
  frame_rate_fps numeric,
  audio_channels integer,
  audio_sample_rate integer
);

CREATE INDEX IF NOT EXISTS idx_assets_org_id ON assets(org_id);
CREATE INDEX IF NOT EXISTS idx_assets_checksum ON assets(checksum_sha256);
CREATE INDEX IF NOT EXISTS idx_assets_org_checksum ON assets(org_id, checksum_sha256);;
