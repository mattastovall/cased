CREATE OR REPLACE FUNCTION public.get_user_history_page(
  p_user text,
  p_page int,
  p_limit int
)
RETURNS TABLE(
  id bigint,
  prompt text,
  image_url text,
  created_at timestamptz,
  theme_uuid uuid,
  theme_name text,
  reference_image_url text,
  model text,
  storage_path text,
  unique_id text,
  generation_id bigint,
  public boolean,
  generation_type text,
  video_url text,
  thumbnail_url text,
  seed bigint,
  sessionid text,
  nsfw boolean,
  advanced_settings jsonb,
  is_trending boolean,
  request_id text,
  total bigint
)
LANGUAGE sql
STABLE
AS $$
  WITH filtered AS (
    SELECT
      g.id,
      g.prompt,
      g.image_url,
      g.created_at,
      CASE WHEN g."theme_UUID" ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN g."theme_UUID"::uuid ELSE NULL END AS theme_uuid,
      NULL::text AS reference_image_url,
      g.model,
      g.storage_path,
      (g.unique_id)::text AS unique_id,
      (g.generation_id)::bigint AS generation_id,
      g.public,
      (g.generation_type)::text AS generation_type,
      g.video_url,
      g.thumbnail_url,
      g.seed,
      g."sessionID" AS sessionid,
      g.nsfw,
      g.advanced_settings,
      g."isTrending" AS is_trending,
      (g.request_id)::text AS request_id
    FROM public.generations g
    WHERE g.user_id = p_user
      AND g.generation_id IS NOT NULL
      AND COALESCE(g.is_theme_asset, false) = false
    ORDER BY g.created_at DESC
    LIMIT p_limit
    OFFSET GREATEST(p_page - 1, 0) * p_limit
  ),
  total_count AS (
    SELECT COUNT(*) AS total
    FROM public.generations g
    WHERE g.user_id = p_user
      AND g.generation_id IS NOT NULL
      AND COALESCE(g.is_theme_asset, false) = false
  )
  SELECT f.id,
         f.prompt,
         f.image_url,
         f.created_at,
         f.theme_uuid,
         t.name AS theme_name,
         f.reference_image_url,
         f.model,
         f.storage_path,
         f.unique_id,
         f.generation_id,
         f.public,
         f.generation_type,
         f.video_url,
         f.thumbnail_url,
         f.seed,
         f.sessionid,
         f.nsfw,
         f.advanced_settings,
         f.is_trending,
         f.request_id,
         tc.total
  FROM filtered f
  LEFT JOIN public.themes t ON (t."UUID")::text = COALESCE(f.theme_uuid::text, '')
  CROSS JOIN total_count tc;
$$;;
