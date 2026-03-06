-- 1) Add is_theme_asset column
ALTER TABLE public.generations
ADD COLUMN IF NOT EXISTS is_theme_asset boolean;

-- 2) Backfill is_theme_asset using prompt/storage heuristics
UPDATE public.generations g
SET is_theme_asset = (
  (g.storage_path LIKE 'themes/%') OR
  (lower(g.prompt) LIKE 'theme:%') OR
  (lower(g.prompt) LIKE '%aesthetic style described%') OR
  (lower(g.prompt) LIKE '%theme details:%') OR
  (lower(g.prompt) LIKE '%generate an image that perfectly embodies this aesthetic style%')
)
WHERE g.is_theme_asset IS NULL;

-- 3) Create function to set is_theme_asset on insert/update
CREATE OR REPLACE FUNCTION public.set_is_theme_asset()
RETURNS trigger AS $$
BEGIN
  NEW.is_theme_asset := (
    (NEW.storage_path IS NOT NULL AND NEW.storage_path LIKE 'themes/%') OR
    (NEW.prompt IS NOT NULL AND (
      lower(NEW.prompt) LIKE 'theme:%' OR
      lower(NEW.prompt) LIKE '%aesthetic style described%' OR
      lower(NEW.prompt) LIKE '%theme details:%' OR
      lower(NEW.prompt) LIKE '%generate an image that perfectly embodies this aesthetic style%'
    ))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4) Attach trigger
DROP TRIGGER IF EXISTS trg_set_is_theme_asset ON public.generations;
CREATE TRIGGER trg_set_is_theme_asset
BEFORE INSERT OR UPDATE OF prompt, storage_path ON public.generations
FOR EACH ROW EXECUTE FUNCTION public.set_is_theme_asset();

-- 5) Indexes
CREATE INDEX IF NOT EXISTS idx_generations_user_is_theme ON public.generations (user_id, is_theme_asset);
CREATE INDEX IF NOT EXISTS idx_generations_user_created_desc ON public.generations (user_id, created_at DESC);
;
