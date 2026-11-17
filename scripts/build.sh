#!/usr/bin/env bash
# Build LineageOS 23.2 for the Galaxy S21 FE SM-G990B2 (codename r9q).
# Usage: LINEAGE_DIR=/path/to/lineage scripts/build.sh [make target, default target-files-package]
# Log: $LINEAGE_DIR/../build.log (or $BUILD_LOG)
set -o pipefail
LINEAGE_DIR=${LINEAGE_DIR:?set LINEAGE_DIR to the lineage-23.2 checkout}
BUILD_LOG=${BUILD_LOG:-$LINEAGE_DIR/../build.log}
cd "$LINEAGE_DIR" || exit 1

export USE_CCACHE=${USE_CCACHE:-1}
export CCACHE_EXEC=${CCACHE_EXEC:-/usr/bin/ccache}
# Stock blobs (audio.primary, sound_trigger...) share names with CAF modules that are not
# installed: only their symbol files clash. -k 0 keeps going to show every error in one run.
export NINJA_ARGS="-w dupbuild=warn -k 0"

source build/envsetup.sh
lunch lineage_r9q-bp4a-userdebug || exit 1

# 30 GB RAM + 32 GB swap: with 24 jobs Soong/metalava run out of memory
m -j"${JOBS:-16}" "${1:-target-files-package}" 2>&1 | tee "$BUILD_LOG"
status=${PIPESTATUS[0]}
echo "BUILD_EXIT=$status" | tee -a "$BUILD_LOG"
exit "$status"
