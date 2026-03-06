-- Update JSON values for styles that have matching JSON files
-- This is a template for how to update the JSON fields
-- In a real implementation, we would fetch and parse the JSON files
UPDATE styles 
SET json = jsonb_build_object(
  'model', 'dall-e-3',
  'style_params', jsonb_build_object(
    'name', slug,
    'strength', 0.8
  )
)
WHERE slug IN (
  '80s-glitch-aesthetic',
  'anime-urban-cinematic-aesthetic',
  'apocalypsefolk-aesthetic',
  'arctic-glyphcore-illustration',
  'astral-gold-aesthetic'
  -- and so on for other styles
);;
