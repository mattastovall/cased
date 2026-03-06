-- PostgREST onConflict cannot target a partial unique index.
-- Create a non-partial unique index for (generation_row_id, variant).
-- Note: UNIQUE allows multiple NULL generation_row_id rows, so this stays rollout-safe.

create unique index if not exists image_derivatives_generation_row_id_variant_uidx_full
  on public.image_derivatives (generation_row_id, variant);

-- Drop the partial index to avoid confusion (optional but recommended)
drop index if exists public.image_derivatives_generation_row_id_variant_uidx;;
