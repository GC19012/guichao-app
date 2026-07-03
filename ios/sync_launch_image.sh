#!/bin/bash

# Keep iOS LaunchImage in sync with the business logo.
# Source of truth: assets/images/logo/logo.png

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_IMAGE="$ROOT_DIR/assets/images/logo/logo.png"
OUT_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/LaunchImage.imageset"

if [ ! -f "$SRC_IMAGE" ]; then
  echo "error: source logo not found: $SRC_IMAGE"
  exit 1
fi

if [ ! -d "$OUT_DIR" ]; then
  echo "error: LaunchImage imageset not found: $OUT_DIR"
  exit 1
fi

# Match existing LaunchImage assets generated for iOS 1x/2x/3x.
sips -z 350 350 "$SRC_IMAGE" --out "$OUT_DIR/LaunchImage.png" >/dev/null
sips -z 700 700 "$SRC_IMAGE" --out "$OUT_DIR/LaunchImage@2x.png" >/dev/null
sips -z 1050 1050 "$SRC_IMAGE" --out "$OUT_DIR/LaunchImage@3x.png" >/dev/null

echo "synced LaunchImage from: $SRC_IMAGE"
