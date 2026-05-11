# Conflict Handling Policy

Specter automatically detects conflicting modules and resolves them silently.
No user prompts during install — all conflict handling is done at boot and
configurable from the Control page.

## How It Works

At every boot, `service.sh` calls `resolve_conflicts()` which:

1. **Detects** conflicting modules by checking `/data/adb/modules/<id>/`
2. **Reads** the user's choice from config (`priority_specter` or `priority_module`)
3. **Acts** based on the choice:
   - `priority_specter` (default, toggle OFF): renames the module's boot scripts
     to `.bak`, preventing them from running. The module stays installed and
     its Zygisk/native code keeps working.
   - `priority_module` (toggle ON): Specter disables its own overlapping
     features via the existing toggle system (`cfg_set toggle_* 0`).
     The other module's scripts are restored from `.bak` if previously blocked.

## Per-Module Table

| Module | ID | Detection | Default | Toggle OFF (Specter) | Toggle ON (Module) |
|---|---|---|---|---|---|
| NoHello | `nohello` | `/data/adb/modules/nohello` | OFF — block service.sh | Rename service.sh → .bak (Zygisk stays) | Specter skips boot prop hardening, security patch, suspicious props, LSPosed clean, ROM spoof block |
| TSupport-Advance | `tsupport-advance` | `/data/adb/modules/tsupport-advance` | OFF — block both boot scripts | Rename post-fs-data.sh + service.sh → .bak | Specter skips all overlapping features (prop hardening, ROM spoof block, target gen, LSPosed clean, etc.) |
| TreatWheel | `treat_wheel` | `/data/adb/modules/treat_wheel` | OFF — block service.sh | Rename service.sh → .bak (Zygisk stays) | Specter skips boot prop hardening, ROM spoof block, suspicious props |
| Sensitive Props | `sensitive_props` | `/data/adb/modules/sensitive_props` | OFF — block service.sh | Rename service.sh → .bak | Specter skips boot prop hardening, suspicious props, ROM spoof block |
| Yurikey Manager | `Yurikey` | `/data/adb/modules/Yurikey` | OFF — block service.sh | Rename service.sh → .bak | Specter skips boot prop hardening, security patch, suspicious props, ROM spoof block |
| Integrity Box | `integritybox` | `/data/adb/modules/playintegrityfix` + `/data/adb/Box-Brain` | OFF — block service.sh | Rename service.sh → .bak | Specter skips all overlapping features (prop hardening, security patch, suspicious props, ROM spoof, bootloader spoofer, target gen) |

## Always Blocked — No Toggle

| Module | Detection | Action |
|---|---|---|
| BootloaderSpoofer (`es.chiteroman.bootloaderspoofer`) | `/data/system/packages.list` | `pm uninstall --user 0` — archived since 2024, no one uses it |

## Compatible Modules — Never Blocked

| Module | Reason |
|---|---|
| Play Integrity Fix | Essential, complementary features (Zygisk injection, auto fingerprint) |
| TrickyStore | Attestation certificate manipulation — different layer from prop spoofing |
| TEESimulator | TrickyStore fork — already integrated via locked.xml format |

## Backup and Restore

Specter keeps a list of renamed scripts at:
```
/data/adb/Specter/conflict_backups.txt
```

On Specter uninstall, all `.bak` files are automatically restored to their
original names. No permanent changes are made to other modules.

## Warnings

- **Do NOT** manually rename `.bak` files back while Specter is active.
  They will be re-blocked on the next boot.
- **Do NOT** run both TSupport-Advance and Specter with both active.
  They do the same thing. Select one via the Conflict Resolution toggles.
- **NoHello's Zygisk root hiding** (mount namespace, FD sanitization) keeps
  working even when its service.sh is blocked. Only the prop spoofing is
  prevented.
- **TreatWheel's Zygisk library** stays active when its service.sh is blocked.
  Only the native prop spoofing daemon is prevented from starting.

## Do's and Don'ts

### Do
- Run Specter with PIF + TrickyStore — designed to work together
- Use the Control page → Conflict Resolution to manage priorities
- Check the conflicts section after installing new modules

### Don't
- Manually edit files in `/data/adb/modules/<id>/` while Specter is running
- Expect both Specter and TSupport-Advance to be fully active simultaneously
- Remove the `conflict_backups.txt` file — needed for clean uninstall
