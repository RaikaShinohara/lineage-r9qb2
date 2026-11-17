#!/usr/bin/env bash
# Build the flashable full OTA zip from the target-files produced by scripts/build.sh.
# Usage: LINEAGE_DIR=/path/to/lineage OUT_DIR=/where/to/put/the/zip scripts/make-ota.sh
# The OTA temp files go to OUT_DIR too: packaging needs several GB of free space.
set -e
LINEAGE_DIR=${LINEAGE_DIR:?set LINEAGE_DIR to the lineage-23.2 checkout}
OUT_DIR=${OUT_DIR:?set OUT_DIR}
cd "$LINEAGE_DIR"
mkdir -p "$OUT_DIR/tmp"
ZIP="$OUT_DIR/lineage-23.2-$(date +%Y%m%d)-UNOFFICIAL-r9q.zip"
TMPDIR="$OUT_DIR/tmp" PATH="$PWD/out/host/linux-x86/bin:$PATH" \
    out/host/linux-x86/bin/ota_from_target_files --verbose \
        --path out/host/linux-x86 --backup=true \
        out/target/product/r9q/obj/PACKAGING/target_files_intermediates/lineage_r9q-target_files \
        "$ZIP" > "$OUT_DIR/ota.log" 2>&1
rm -rf "$OUT_DIR/tmp"
echo "$ZIP"
