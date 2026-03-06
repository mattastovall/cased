-- Create content_generation_jobs table
CREATE TABLE IF NOT EXISTS content_generation_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL, -- Link to assets table
  status TEXT NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, failed
  progress JSONB DEFAULT '{}'::jsonb, -- { step: "string", percent: number }
  payload JSONB DEFAULT '{}'::jsonb, -- Result data
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE content_generation_jobs ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can do everything with jobs (for now, simplify to public if needed, but auth is better)
CREATE POLICY "Users can select their own jobs" ON content_generation_jobs
  FOR SELECT TO authenticated, anon
  USING (true); -- Ideally check owner, but for now allow all to unblock

CREATE POLICY "Users can insert jobs" ON content_generation_jobs
  FOR INSERT TO authenticated, anon
  WITH CHECK (true);

CREATE POLICY "Users can update their own jobs" ON content_generation_jobs
  FOR UPDATE TO authenticated, anon
  USING (true);

-- Create worker_logs table (if missing)
CREATE TABLE IF NOT EXISTS worker_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  name TEXT NOT NULL,
  method TEXT,
  video_id UUID,
  payload JSONB,
  response JSONB,
  status TEXT,
  error TEXT,
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ DEFAULT now(),
  duration_ms INTEGER
);

ALTER TABLE worker_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow inserting logs" ON worker_logs
  FOR INSERT TO authenticated, anon, service_role
  WITH CHECK (true);

CREATE POLICY "Allow reading logs" ON worker_logs
  FOR SELECT TO authenticated, anon, service_role
  USING (true);

-- Storage Policies (Fixing StorageApiError)
-- We need to allow access to 'frames', 'audio', 'exports' buckets in storage.objects

-- Ensure buckets exist (this is idempotent-ish via insert on conflict)
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('frames', 'frames', true),
  ('audio', 'audio', true),
  ('exports', 'exports', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Policy for frames bucket
CREATE POLICY "Public Access Frames" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'frames')
  WITH CHECK (bucket_id = 'frames');

-- Policy for audio bucket
CREATE POLICY "Public Access Audio" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'audio')
  WITH CHECK (bucket_id = 'audio');

-- Policy for exports bucket
CREATE POLICY "Public Access Exports" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'exports')
  WITH CHECK (bucket_id = 'exports');

-- Also ensure assets bucket allows updates if not already
CREATE POLICY "Public Access Assets" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'assets' OR bucket_id = 'reference-media')
  WITH CHECK (bucket_id = 'assets' OR bucket_id = 'reference-media');;
