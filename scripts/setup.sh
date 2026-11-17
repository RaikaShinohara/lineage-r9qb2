#!/usr/bin/env bash
# Prepare a synced lineage-23.2 checkout for r9q (SM-G990B2):
#  - check out the pinned base of each modified project and apply patches/ on a local branch "b2"
#  - copy the extracted, already fixed-up blobs to vendor/samsung/{r9q,sm8350-common}
# Usage: LINEAGE_DIR=/path/to/lineage scripts/setup.sh
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
LINEAGE_DIR=${LINEAGE_DIR:?set LINEAGE_DIR to the lineage-23.2 checkout}

while read -r name base _; do
    path=${name//_//}   # device_samsung_sm8350-common -> device/samsung/sm8350-common
    dir="$LINEAGE_DIR/$path"
    echo "== $path @ $base"
    git -C "$dir" cat-file -e "$base^{commit}" 2>/dev/null || git -C "$dir" fetch --depth=1 github "$base"
    git -C "$dir" checkout -q -B b2 "$base"
    git -C "$dir" am -q --keep-cr "$REPO_DIR/patches/$name"/*.patch
done < "$REPO_DIR/patches/BASES.txt"

mkdir -p "$LINEAGE_DIR/vendor/samsung"
rsync -a --delete "$REPO_DIR/vendor/samsung/r9q" "$REPO_DIR/vendor/samsung/sm8350-common" \
    "$LINEAGE_DIR/vendor/samsung/"
echo "Done. Build with scripts/build.sh"
