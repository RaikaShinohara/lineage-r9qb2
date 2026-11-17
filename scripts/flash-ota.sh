#!/usr/bin/env bash
# Install the LineageOS zip on r9q over adb without wiping data:
# reboot to TWRP, sideload, check boot/vendor_boot/dtbo against the zip, clear the first
# bytes of "param" (otherwise the bootloader keeps booting TWRP) and boot the system.
# Usage: scripts/flash-ota.sh <zip>   (phone in Android with adb root, or already in TWRP)
set -u
ZIP=${1:?zip}
wait_state() { for _ in $(seq 1 80); do [ "$(adb get-state 2>/dev/null)" = "$1" ] && return 0; sleep 3; done; return 1; }

[ "$(adb get-state 2>/dev/null)" = recovery ] || { adb reboot recovery; sleep 15; wait_state recovery || { echo "TWRP not reached"; exit 1; }; }
adb shell twrp sideload; sleep 6
adb sideload "$ZIP" 2>&1 | tr '\r' '\n' | tail -1
sleep 10; wait_state recovery || { echo "TWRP did not come back after sideload"; exit 1; }
adb shell 'grep -a "Updater process ended" /tmp/recovery.log | tail -1' | grep -q "RC=0" || { echo "install failed"; exit 1; }
for p in boot vendor_boot dtbo; do
    a=$(adb shell "sha256sum /dev/block/by-name/$p" | cut -d' ' -f1)
    b=$(unzip -p "$ZIP" "$p.img" | sha256sum | cut -d' ' -f1)
    [ "$a" = "$b" ] || { echo "$p does not match the zip"; exit 1; }
done
adb shell 'dd if=/dev/zero of=/dev/block/by-name/param bs=4 count=1 conv=notrunc 2>/dev/null'
adb reboot; sleep 15
wait_state device || { echo "Android did not come up (no adb)"; exit 1; }
for _ in $(seq 1 60); do [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break; sleep 3; done
echo "boot_completed=$(adb shell getprop sys.boot_completed | tr -d '\r')"
