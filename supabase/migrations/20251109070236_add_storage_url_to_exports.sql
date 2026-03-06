ALTER TABLE exports 
ADD COLUMN storage_path text,
ADD COLUMN storage_bucket text DEFAULT 'exports';

COMMENT ON COLUMN exports.storage_path IS 'Path to the rendered MOV file in Supabase Storage';
COMMENT ON COLUMN exports.storage_bucket IS 'Storage bucket name (default: exports)';;
