-- Add video_id column to assets table (nullable UUID)
-- Note: Foreign key constraint will be added once videos table exists
ALTER TABLE assets 
ADD COLUMN IF NOT EXISTS video_id uuid;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_assets_video_id ON assets(video_id);

-- Add comment
COMMENT ON COLUMN assets.video_id IS 'Links reference assets to their associated video project. References videos(id).';;
