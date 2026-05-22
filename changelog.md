# v1.4.1

## Boot & One-time Tasks
- **One-time boot markers** — `tee` and ROM spoof cleanup run once after install (markers set in `customize.sh`, cleared in `boot_core.sh`).
- **Boot feature list trimmed** — regular boot dispatch now runs recovery, boot_hardening, suspicious_props, and lsposed only; security_patch/rom_spoof/bootloader_spoofer removed from the loop.
- **Delayed boot props** switched to `apply_boot_props` for consistency.
- **Bootloader spoofer cleanup is unconditional** — no toggle gating.

## TEE Attestation
- **TEE attestation moved to boot** via Specter APK ContentProvider (`features/tee.sh`) with cached status + hash.
- **VBMeta helpers extracted** to `lib/vbmeta.sh` and reused by TEE hash fallback logic.
- **Install-time TEE check removed** — installer reads cached TEE status/hash only.

## target.txt (Tricky Store)
- **Set target.txt now merges** missing apps instead of overwriting; existing entries and order are preserved (`features/target_merge.sh`).
- **Action pipeline updated** to call merge script; install-time generation still uses `target.sh`.

## Play Integrity & ROM Spoof
- **Play Integrity section added** to Tools with "Get New Fingerprint" (pif.sh) action.
- **PIF detection cleanup renamed** to ROM spoof cleanup and shared across boot + WebUI (`rom_spoof_cleanup.sh`).
- **Removed bootloader spoofer and ROM spoof toggles** from Controls UI.

## Conflict System & Toggles
- **Conflict registry updated** (TreatWheel → prop_handler; reduced overlap for TSupport/Yurikey/Integrity Box).
- **Conflict toggle application expanded** to include action gms and pif toggles.
- **Security patch boot toggle removed** from Control list.

## Keybox
- **Custom keybox "No" path fixed** — no extra detection dialog; installs directly.
- **Unused imports removed** in keybox UI.

## Device Info & WebUI
- **Recovery folder detection** now controls recovery toggle visibility.
- **Security patch dialog cleaned up** — duplicate generate icon removed.
- **Localization updated** for new Play Integrity and ROM spoof cleanup labels.

## Build & Repo
- **BusyBox standalone fix** in `action.sh` for non-BusyBox shells.
- **APK bundling** — `src/apk/` included in module zip.
- **Docs trimmed** — removed old architecture/dev docs from `docs/`.

# v1.4.0

## Performance
- **Init restructured** — page renders immediately with placeholders; all async I/O (device info, i18n, network checks, catalog fetch) runs fire-and-forget. No more 1-4s blank screen on slow devices.
- **Code splitting** — monolithic 490 KB material.ts split into 4 on-demand per-page chunks. Initial JS download reduced to ~84 KB (82% reduction).
- **CSS inlined** — no more render-blocking CSS download. Styles embedded directly in HTML.
- **Faster first paint** — core MWC now starts downloading in parallel with bridge/config init instead of after.
- **Native `<select>`** — replaced MWC md-outlined-select/md-select-option with native elements, eliminating the 120 KB select-option chunk.
- **Animation tuning** — page-enter transition set to 250ms (down from 350ms).
- **Unused imports removed** — md-sub-menu, md-list, md-list-item (3 unnecessary MWC component imports eliminated).
- **Duplicate button CSS removed** — custom .md3-tonal class replaced with standard md-filled-tonal-button.
- **Removed page-init.ts indirection** — simplified the dynamic import chain, one less round trip per tab switch.
- **Material Icons fonts non-blocking** — CDN stylesheets load with `media="print"` + `onload` swap, eliminating render blocking. Local `assets/material-icons.css` fallback on CDN failure.
- **Back button reworked** — first press goes Home, second press exits the WebUI.
- Lowered offline detection timeout from 2000ms to 800ms per endpoint.

## Theme
- **Theme flash eliminated** — inline `<script>` sets CSS custom properties before first paint. Theme colors cached in localStorage for instant correct colors on every subsequent visit.
- **Replace full MCU library with precomputed preset data** — the 97 KB @material/material-color-utilities library removed. 9 named presets now use a precomputed 7.5 KB lookup table of exact Google Material Design 3 hex values.
- **Monet wallpaper color matching** — Monet accent color is extracted and mapped to the closest named preset (red/orange/yellow/green/cyan/blue/purple/pink/grey) based on its HSL hue.
- **Grey preset fixed** — neutral seeds now produce true grey tones instead of the brown/cyan tint from HCT extraction artifacts.

## i18n
- **English strings inlined** — no network fetch needed for English locale.
- **Non-English caching** — translation files cached in localStorage. Repeat visits load instantly.
- **Duplicate lang file removed** from module zip (already inlined in JS).

## Device Info
- **Info cards cached** — device info cached in localStorage with 30-second TTL. Repeat visits show data instantly instead of `—`, with silent background refresh.

## Boot State Properties
- **Vendor boot props** — `vendor.boot.verifiedbootstate`, `vendor.boot.vbmeta.device_state`, `ro.vendor.boot.warranty_bit` now reset alongside `ro.boot.*` variants at boot.
- **Build flavor/fingerprint spoof** — `ro.build.flavor` patched (userdebug/eng → user), all `ro.*.build.fingerprint` patched (userdebug→user, test-keys→release-keys).
- **Realme specific** — `ro.boot.realmebootstate`, `ro.boot.realme.lockstate` set at boot.
- **Recovery bootmode hiding** — bootmode set to `unknown` when it contains "recovery".
- **Toggle added** — Boot State Props can be disabled in Control → Boot Behavior when needed.

## Security Patch
- **Fetch from source.android.com** — new globe button in the security patch dialog scrapes the latest Pixel security bulletin date directly from Google, instead of guessing "previous month".

## Suspicious Props
- **Backup before delete** — slain properties now backed up to `/data/adb/Specter/slain_props.prop` before removal.

## Build & Misc
- **CSS inlining** — build step automatically inlines the minified CSS into HTML.
- **Preconnect hints** added for rawbin.netlify.app in document `<head>`.
- **Module zip reduced** — 175 KB → 159 KB (9% smaller).

## Tools
- **Google Services section** added to Tools page — one-shot "Force Stop & Clear Play Store" button (gms.sh) restored.
- **Set target.txt one-shot button** restored under Tricky Store section.
