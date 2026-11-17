# LineageOS 23.2 for the Galaxy S21 FE 5G Snapdragon (SM-G990B2, r9q)

Unofficial LineageOS 23.2 (Android 16, `lineage_r9q-bp4a-userdebug`) for the Samsung Galaxy S21 FE 5G
with the Snapdragon 888 (SM8350), model **SM-G990B2** (`ro.product.vendor.device=r9q2`).

It is built on the [samsung-sm8350](https://github.com/samsung-sm8350) trees (device `r9q`,
`sm8350-common`, kernel `lineage-22`) with the changes in `patches/` and blobs extracted from the
G990B2 stock firmware.

> This port was made with the help of an AI assistant. Test it on a device you can recover.

## Status

| Area | Status |
|---|---|
| Boot | OK, about 30 s to the lock screen |
| Display | OK: 120/60 Hz, HDR, brightness, touch |
| Wi-Fi (QCA6490) | OK: 2.4 and 5 GHz, comes up at boot |
| Bluetooth | OK |
| Camera | OK: rear and front preview, 4000×3000 photo, video recording (H.264 + AAC) |
| Sensors, fingerprint, NFC, vibrator | OK |
| Battery and charging | OK |
| SIM, mobile data | Works (SIM detected, data call up, validated). With poor LTE coverage the modem bounces between LTE and 3G and data can stall for a few minutes after losing the network; see *Known issues* |
| Calls, SMS, VoLTE | Not tested |
| Speaker/headphone audio, GPS fix, DisplayPort over USB-C, ultrawide/tele lenses | Not tested |

### Known issues and provisional choices

- **`/data` is not encrypted** and **SELinux is permissive**.
- Build is `userdebug` signed with test keys; `adb root` works when "Rooted debugging" is on.
- Kernel: `free_initmem()` is skipped on r9q (zeroing `.init` through the linear map hangs the SoC
  with this toolchain; ~2 MB stay allocated) and `CRYPTO_FIPS` is off (its integrity check panics
  on a non-Samsung build). Root cause of the `.init` hang is still unknown.
- Some blobs are built with `check_elf` disabled (32-bit blobs with private EABI symbols; a few
  Android 14 blobs such as `libqti-iopd` with `perf_get_prop`).
- Mobile data on the tested DIGI SIM (roaming on Movistar, LTE SNR between -2 and 4): LTE ↔ 3G
  ping-pong, 1–5 Mbit/s, one multi-minute stall after a short loss of registration. LTE-only
  mode makes it worse there. Not yet compared with stock on the same SIM and spot.
- `vendor_boot` carries every arm64 DTB the kernel builds (only Lahaina V2.1, index 36, is used).

## Requirements

- Unlocked bootloader. Tested with bootloader/modem **G990B2XXSFHYI1**; the vendor blobs come from
  **G990B2XXS7GXF1**.
- TWRP 3.7.1 for r9q (Vol+ and Power at the Samsung logo with USB connected).

## Install

**First install (wipes the phone).** In TWRP, `twrp format data` crashes, so:

1. Format `metadata` with `mke2fs` and reboot to TWRP (so `dm-default-key` is not set up).
2. Format `userdata` with `make_f2fs`.
3. `adb sideload lineage-23.2-*-UNOFFICIAL-r9q.zip` (TWRP may crash after the install while loading
   APEX; the install is still fine if `/tmp/recovery.log` shows `Updater process ended with RC=0`).
4. Clear the first 4 bytes of `param`, or the bootloader keeps booting TWRP:
   `dd if=/dev/zero of=/dev/block/by-name/param bs=4 count=1 conv=notrunc`.

**Updates (keep data):** `scripts/flash-ota.sh <zip>` with the phone in Android (adb root) or in
TWRP. It sideloads, checks `boot`, `vendor_boot` and `dtbo` against the zip, clears `param` and
waits for `sys.boot_completed`.

## Build

```bash
mkdir lineage && cd lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
# tested with manifest 84e40f4b7f32360505019b1fc468392766e5003c (2026-11-10)
cp /path/to/lineage-r9qb2/local_manifests/r9q2.xml .repo/local_manifests/
repo sync -c -j8
LINEAGE_DIR=$PWD /path/to/lineage-r9qb2/scripts/prebuilts.sh
LINEAGE_DIR=$PWD /path/to/lineage-r9qb2/scripts/setup.sh
LINEAGE_DIR=$PWD /path/to/lineage-r9qb2/scripts/build.sh
LINEAGE_DIR=$PWD OUT_DIR=/some/disk/with/space /path/to/lineage-r9qb2/scripts/make-ota.sh
```

- `prebuilts.sh` clones only the clang (`r547379`) and rust (`1.88.0`) prebuilts the build uses
  (partial clone + sparse checkout), pinned to the tested commits.
- `setup.sh` checks out the base commit of each modified project listed in `patches/BASES.txt`,
  applies the patches on a local branch `b2` and copies `vendor/samsung/`.
- `build.sh` builds `target-files-package` (several hours from scratch; tested with 16 jobs,
  30 GB RAM and 32 GB swap).
- `make-ota.sh` turns target-files into the flashable full OTA (needs several GB of free space).

## Layout

| Path | Contents |
|---|---|
| `local_manifests/r9q2.xml` | Extra projects for the lineage-23.2 checkout |
| `patches/device_samsung_r9q/` | 18 commits on `samsung-sm8350/android_device_samsung_r9q` (`next-r9q`) |
| `patches/device_samsung_sm8350-common/` | 7 commits on `android_device_samsung_sm8350-common` (`lineage-23.0`) |
| `patches/kernel_samsung_sm8350/` | 12 commits on `android_kernel_samsung_sm8350` (`lineage-22`) |
| `patches/BASES.txt` | Base commit of each patch series |
| `vendor/samsung/r9q`, `vendor/samsung/sm8350-common` | Blobs extracted from G990B2XXS7GXF1 with the `extract-files.py` fixups applied |
| `scripts/` | `prebuilts.sh`, `setup.sh`, `build.sh`, `make-ota.sh`, `flash-ota.sh` |

To regenerate the blobs from a stock `vendor.img` instead, mount or unpack it and run
`device/samsung/r9q/extract-files.py <dump>`.

## Main changes

**Kernel**

- Android 16 build fixes: uapi `sched_param`, vDSO32 with clang and lld.
- QCA6490 Wi-Fi: build `qcacld-3.0` as `wlan.ko`; `cnss2` waits for cold-boot calibration instead
  of rejecting the driver.
- `epoll_pwait2` backport. Android 16's `BLASTBufferQueue` needs it, and on 5.4 every app looped
  on `ENOSYS` and flooded logd.
- IPA and rmnet from the 2024 sources (kernel branch `lineage-23.2`). The 2022 version held mobile
  downlink packets for up to ~10 s.
- `CRYPTO_FIPS` off; `.init` not freed on r9q.

**Device: SM-G990B2 adaptations**

- `r9q2xxx` props.
- Qualcomm Wi-Fi/BT instead of Broadcom: module list, firmware, `init.r9q2.rc` alias.
- `wlan` in `modules.blocklist`, so `vendor_modprobe.sh` does not block early-init for 70 s.

**Device: display**

- Display blobs relinked to `libtinyxml2-v34`.

**Device: camera**

- About 110 missing CamX and `dlopen` libraries.
- `libhidlbase` shim for postproc.
- `libsensorndkbridge_shim`, providing Samsung's `ALooper_*_forCamera`, so CamX can load
  `com.ss.stats.aec`.
- Binary patch of `SecUsecaseFastAec::SessionCbNotifyMessage` in `com.qti.chi.override.so`: it
  locked a mutex created after the session started, and that crashed the provider.

**Device: video recording**

- `debug.stagefright.c2inputsurface=-1`, because there is no OMX service for persistent input
  surfaces.

## Credits

[LineageOS](https://lineageos.org), the [samsung-sm8350](https://github.com/samsung-sm8350) team
(device, common and kernel trees) and Samsung's kernel source releases.
