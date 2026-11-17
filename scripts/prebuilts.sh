#!/usr/bin/env bash
# Clone only the clang and rust prebuilts the build uses (partial clone + sparse checkout).
# The full repos carry ~95 GB of history, and with clone-depth=1 repo retries without depth.
# Usage: LINEAGE_DIR=/path/to/lineage scripts/prebuilts.sh
set -euo pipefail
LINEAGE_DIR=${LINEAGE_DIR:?set LINEAGE_DIR to the lineage-23.2 checkout}
AOSP=https://android.googlesource.com/platform/prebuilts

clone() {  # clone <dir> <repo> <commit> <sparse paths...>
    local dir=$1 repo=$2 rev=$3; shift 3
    [ -d "$dir/.git" ] && { echo "$dir already exists"; return; }
    git clone --filter=blob:none --no-checkout "$AOSP/$repo" "$dir"
    git -C "$dir" sparse-checkout set --cone "$@"
    git -C "$dir" checkout -q "$rev"
}

clone "$LINEAGE_DIR/prebuilts/clang/host/linux-x86" clang/host/linux-x86 \
    9916fb51ccb914d62d35ad9a7b9b21d2ef046928 \
    clang-3289846 clang-r547379 clang-r563880 clang-r563880c clang-stable embedded-sysroots \
    kleaf llvm-binutils-stable mlgo-models profiles soong
clone "$LINEAGE_DIR/prebuilts/rust" rust \
    06a4f29f8512c6b77bdce81dd036a3e39954803b \
    bootstrap linux-x86/1.88.0 soong
