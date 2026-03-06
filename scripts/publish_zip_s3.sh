#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <zip_path> <s3_uri_prefix> [expires_seconds]"
  echo "Example: $0 dist/cased-chestplate-assets-2026-03-05-v1.zip s3://my-bucket/team-share 1209600"
  exit 1
fi

ZIP_PATH="$1"
S3_PREFIX="$2"
EXPIRES_SECONDS="${3:-1209600}" # 14 days

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Zip not found: $ZIP_PATH"
  exit 1
fi

if [[ ! "$S3_PREFIX" =~ ^s3:// ]]; then
  echo "s3_uri_prefix must start with s3://"
  exit 1
fi

ZIP_BASENAME="$(basename "$ZIP_PATH")"
SHA_PATH="${ZIP_PATH}.sha256"

if [[ ! -f "$SHA_PATH" ]]; then
  shasum -a 256 "$ZIP_PATH" | awk '{print $1 "  '"$ZIP_BASENAME"'"}' > "$SHA_PATH"
fi

DEST_ZIP="${S3_PREFIX%/}/${ZIP_BASENAME}"
DEST_SHA="${S3_PREFIX%/}/${ZIP_BASENAME}.sha256"

aws s3 cp "$ZIP_PATH" "$DEST_ZIP"
aws s3 cp "$SHA_PATH" "$DEST_SHA"

SIGNED_URL="$(aws s3 presign "$DEST_ZIP" --expires-in "$EXPIRES_SECONDS")"

echo "Uploaded:"
echo "  $DEST_ZIP"
echo "  $DEST_SHA"
echo
echo "Signed URL (expires in ${EXPIRES_SECONDS}s):"
echo "  $SIGNED_URL"
