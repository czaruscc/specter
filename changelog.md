# Specter Changelog

## v1.0.0
- Keybox revocation sourced directly from Google's attestation endpoint (not rawbin catalog)
- Keybox install warns on revocation instead of aborting
- Private keyboxes are also checked for revocation via Google
- Device info loads via await+fetch — no polling, no stale reads
- WebUI written in TypeScript with strict mode
- Material 3 interface with MWC components
- Keybox management: download, install, backup, verify
- Dynamic target.txt generation with blacklist + SmartMerge
- Security spoofing: patch date, boot hash, property hardening
- PIF integration for INJECT and Fork variants
- Zygisk Next configuration (denylist, memory-type, linker)
- Widevine L1 attestation for Qualcomm devices
- Detection cleanup and RKA provisioning
- Multi-root support (Magisk / KernelSU / APatch)
- i18n with 5 languages (en, zh, ru, es, ar)
- CI with TypeScript checking, shell lint, and automated releases
