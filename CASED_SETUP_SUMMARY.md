# CASED Setup Summary

## Date
- 2026-03-05 (America/Chicago)

## Scope Completed
- Parsed request logs from 7 `.txt` files.
- Built consolidated request JSON payloads.
- Mirrored assets locally and packaged provenance artifacts.
- Uploaded input/output images to Supabase Storage bucket `cased` in project `themes` (`vxdmipbkwsbsmnxzdppz`).
- Created and seeded `public."CASED"` table with request metadata and storage paths.

## Source Files Processed
- `chestplate-ansysSimulation-image.txt`
- `chestplate-from-Ref-image.txt`
- `chestplate-labsetting-image.txt`
- `chestplate-loop-video.txt`
- `chestplate-reveal-video.txt`
- `chestplate-strike-video.txt`
- `chestplate-twist-video.txt`

## Request JSON Outputs
Directory: `request-json/`
- `all-requests.json` (single consolidated file)
- Per-request files:
  - `chestplate-ansysSimulation-image.json`
  - `chestplate-from-Ref-image.json`
  - `chestplate-labsetting-image.json`
  - `chestplate-loop-video.json`
  - `chestplate-reveal-video.json`
  - `chestplate-strike-video.json`
  - `chestplate-twist-video.json`
  - `manifest.json`

## Asset Packaging Outputs
Generated via `scripts/build_asset_package.py`:
- `dist/staging/manifest.json`
- `dist/staging/download_report.json`
- `dist/cased-chestplate-assets-2026-03-05-v1/`
- `dist/cased-chestplate-assets-2026-03-05-v1.zip`
- `dist/cased-chestplate-assets-2026-03-05-v1.zip.sha256`

Packaging result:
- Logs processed: 7
- Assets in manifest: 19
- Downloaded: 19
- Failed: 0
- Outputs packaged: 7 (4 mp4, 3 png)

## Supabase Project/Bucket
- Linked project ref: `vxdmipbkwsbsmnxzdppz` (themes)
- Storage bucket used: `cased` (lowercase)

Uploaded image objects:
- `cased/input-images/` => 12 PNG files
- `cased/output-images/` => 3 PNG files

## Database Changes
### Config
- Updated `supabase/config.toml` DB major version from `17` to `15` to match remote.

### Migration State
- Synced remote migration history into local `supabase/migrations` using `supabase migration fetch`.

### CASED Migration Applied
- Migration file:
  - `supabase/migrations/20260305220013_create_cased_table_and_seed.sql`
- Applied with:
  - `supabase db push --yes`
- Remote migration list confirms version is applied:
  - `20260305220013`

### Table Created
`public."CASED"` with columns:
- `id bigserial primary key`
- `request_name text not null unique`
- `source_log text not null`
- `endpoint text`
- `request_id text`
- `request_payload jsonb not null`
- `input_image_paths text[] not null default '{}'::text[]`
- `output_image_paths text[] not null default '{}'::text[]`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Seed behavior:
- Upsert by `request_name` from `request-json/all-requests.json` + parsed log metadata.
- Total seeded request rows: 7.

## Scripts Added
- `scripts/build_asset_package.py`
- `scripts/publish_zip_s3.sh`

## Notes
- Supabase Storage CLI commands were run with `--experimental`.
- `supabase db dump` table verification was not used due to Docker daemon requirement in this environment; migration application is confirmed by remote migration history.
