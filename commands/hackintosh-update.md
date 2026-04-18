---
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, Agent]
description: "Research, validate compatibility, and update Hackintosh EFI (OpenCore, kexts, SSDTs, drivers)"
---

# /hackintosh-update - Hackintosh EFI Update Skill

## Purpose
Research latest versions of all Hackintosh EFI components, validate compatibility with user's hardware, update the EFI partition, and provide clear instructions for what requires manual steps (BIOS, reboot).

## Context
All hardware details, current kext versions, SSDTs, drivers, boot-args, DeviceProperties, and config.plist settings are documented in the memory file:
`/Users/mpelos/.claude/projects/-Users-mpelos/memory/hackintosh.md`

**ALWAYS read this file first** to get the current state of the Hackintosh.

## Language
All communication with the user MUST be in **Portuguese (BR)**.

## User's Hardware (quick reference)
- **Motherboard**: Gigabyte Z790 Aorus Elite AX ICE
- **CPU**: Intel Core i9-14900K (Raptor Lake)
- **GPU macOS**: Check memory file (was RX 5600 XT, may have been swapped to RX 580)
- **SSD**: WD BLACK SN850X 1TB
- **Wi-Fi**: Intel Wi-Fi 6E AX211
- **Bluetooth**: Intel Bluetooth 5.3
- **Ethernet**: Realtek RTL8125B 2.5G
- **Audio**: Onboard (AppleALC layout-id 11)
- **SMBIOS**: MacPro7,1
- **macOS**: Check current version with `sw_vers`

## Components to Check

### 1. OpenCore (bootloader)
- **Repo**: acidanthera/OpenCorePkg
- **Check**: GitHub releases for latest stable version
- **Compatibility**: Always check OpenCore changelog for breaking changes
- **CRITICAL**: OpenCore updates may require config.plist schema changes

### 2. Kexts (kernel extensions)
All from GitHub releases unless noted:

| Kext | Repo | Purpose |
|---|---|---|
| Lilu | acidanthera/Lilu | Base framework (update FIRST, others depend on it) |
| WhateverGreen | acidanthera/WhateverGreen | GPU patches |
| AppleALC | acidanthera/AppleALC | Audio |
| VirtualSMC | acidanthera/VirtualSMC | SMC emulation (includes SMCProcessor, SMCSuperIO) |
| NVMeFix | acidanthera/NVMeFix | NVMe power management |
| RestrictEvents | acidanthera/RestrictEvents | System patches, OTA updates |
| CpuTscSync | acidanthera/CpuTscSync | TSC sync for i9-14900K |
| BlueToolFixup | acidanthera/BrcmPatchRAM | Bluetooth fix (Monterey+) |
| IntelBluetoothFirmware | OpenIntelWireless/IntelBluetoothFirmware | Intel BT firmware |
| IntelBTPatcher | OpenIntelWireless/IntelBluetoothFirmware | Intel BT patches |
| itlwm | OpenIntelWireless/itlwm | Intel Wi-Fi driver |
| LucyRTL8125Ethernet | Mieze/LucyRTL8125Ethernet | Realtek 2.5G Ethernet |
| USBWakeFixup | osy/USBWakeFixup | USB wake from sleep |
| USBMap | N/A (custom) | Custom USB map - DO NOT UPDATE |

### 3. Drivers (.efi)
- Bundled with OpenCore: OpenRuntime.efi, OpenCanopy.efi, ResetNvramEntry.efi, FirmwareSettingsEntry.efi
- Separate: HfsPlus.efi (rarely changes), AudioDxe.efi (bundled with OC)

### 4. SSDTs (ACPI)
- Generally static, rarely need updates
- SSDT-NVOFF is custom-made — DO NOT replace

### 5. macOS Updates
- Check with `softwareupdate --list`
- **NEVER suggest upgrading to macOS Tahoe** unless user explicitly asks and WhateverGreen compatibility is confirmed for their GPU

## Execution Steps

### Phase 1: Read Current State
1. Read memory file: `/Users/mpelos/.claude/projects/-Users-mpelos/memory/hackintosh.md`
2. Check current macOS version: `sw_vers`
3. If user specifies a target version, note it

### Phase 2: Research Latest Versions
Use WebSearch and WebFetch to check GitHub releases for ALL components listed above.

**Search strategy per component:**
- WebSearch: `site:github.com {repo} releases latest 2026`
- WebFetch on `https://github.com/{repo}/releases/latest` to get version and changelog

**Run searches in parallel using Agent tool** to speed up research. Launch one agent per repo group:
- Agent 1: acidanthera repos (Lilu, WhateverGreen, AppleALC, VirtualSMC, NVMeFix, RestrictEvents, CpuTscSync, BrcmPatchRAM, OpenCorePkg)
- Agent 2: Other repos (OpenIntelWireless/itlwm, OpenIntelWireless/IntelBluetoothFirmware, Mieze/LucyRTL8125Ethernet, osy/USBWakeFixup)
- Agent 3: macOS updates (`softwareupdate --list`)

### Phase 3: macOS Update Compatibility Research
For EVERY macOS update listed by `softwareupdate --list`, research online whether it is safe for Hackintosh:

**Launch a dedicated Agent** to research each available macOS update (security updates AND major versions). The agent must:

1. **WebSearch** for Hackintosh compatibility reports:
   - `"macOS {version}" hackintosh {current GPU architecture} site:reddit.com/r/hackintosh`
   - `"macOS {version}" hackintosh OpenCore {current OC version}`
   - `"macOS {version}" hackintosh issues problems`
   - `"macOS {version}" {GPU model} hackintosh` (e.g., "macOS 15.7.5 RX 580 hackintosh")

2. **Check Dortania/OpenCore compatibility**:
   - WebFetch `https://dortania.github.io/hackintosh/` or search for Dortania guides mentioning the version
   - Check if OpenCore release notes mention the macOS version

3. **Check for known regressions**:
   - Search for kernel panics, boot loops, or hardware-specific issues
   - Check if any kexts in our setup are known to break with this version
   - Pay special attention to: WhateverGreen (GPU), itlwm (Wi-Fi), AppleALC (audio)

4. **For major macOS upgrades** (e.g., Sequoia to Tahoe):
   - Check memory file for existing upgrade guide and requirements
   - Verify ALL required kexts are available and compatible
   - Check if KDK or other special components are needed
   - Research community success/failure reports extensively

5. **Produce a verdict per update**:
   - **SAFE**: Community reports confirm it works, no known issues for our hardware
   - **LIKELY SAFE**: Few reports but no red flags, minor update (security patch)
   - **CAUTION**: Mixed reports or insufficient data, recommend waiting
   - **BLOCK**: Known issues with our hardware, or required kexts not yet compatible
   - Include sources/links for the verdict

### Phase 3.5: OpenCore Upgrade Research (MANDATORY if OC update available)
If a new OpenCore version is available, **ALWAYS launch a dedicated Agent** to research the upgrade thoroughly before proceeding:

1. **Fetch the full changelog** from `https://github.com/acidanthera/OpenCorePkg/releases/tag/{version}`
2. **Check config.plist schema changes**: Search for "OpenCore {old} to {new} config.plist changes", diff Sample.plist between versions
3. **Check if any new quirks were added**, existing ones removed/renamed, or default values changed
4. **Check if any .efi drivers changed behavior** (OpenRuntime, OpenCanopy, etc.)
5. **Search community reports**: "OpenCore {version} upgrade issues", tonymacx86, reddit, insanelymac
6. **Produce a migration guide**: List exactly what files need replacing and what config.plist edits are needed (if any)

**CRITICAL**: OpenRuntime.efi MUST match the OpenCore version — mismatched versions cause boot failure. ALL bundled .efi drivers must be updated together with OpenCore.

**When updating OpenCore:**
- Replace: OpenCore.efi, BOOTx64.efi, and ALL .efi drivers currently in use (OpenRuntime, OpenCanopy, AudioDxe, ResetNvramEntry, FirmwareSettingsEntry)
- Keep: HfsPlus.efi (not bundled with OC, rarely changes)
- Keep: config.plist (apply schema changes if any, otherwise leave untouched)
- Download from: `https://github.com/acidanthera/OpenCorePkg/releases/download/{version}/OpenCore-{version}-RELEASE.zip` — use the X64/EFI directory

### Phase 4: Kext/OpenCore Compatibility Validation
For each component with a new version available:
1. **Read the changelog/release notes** for breaking changes
2. **Check macOS version compatibility** (some kexts drop support for older macOS)
3. **Check hardware compatibility** (especially WhateverGreen for GPU, itlwm for Wi-Fi)
4. **Check Lilu dependency** -- if Lilu updates, dependent kexts may need matching versions
5. **Check OpenCore config.plist schema changes** if OC version changes

**CRITICAL — Kext version compatibility with current macOS:**
- Kexts MUST be downloaded for the **currently installed macOS version** (e.g., Sequoia), NOT for a future version (e.g., Tahoe)
- Some kexts have separate builds for different macOS versions — always download the one matching the current OS
- If a kext's latest release was compiled with a newer macOS SDK (e.g., Tahoe SDK) and is incompatible with the current OS, use the **previous release** that targets the current macOS
- **IntelBluetoothFirmware is a known offender**: builds compiled with Tahoe SDK may break Bluetooth on Sequoia. Always verify the SDK version in Info.plist (`DTSDKName` field) matches or is older than the current macOS

**Red flags that block update:**
- WhateverGreen dropping support for current GPU architecture
- OpenCore major version change without config.plist migration guide
- Kext requiring newer macOS than currently installed
- Known regressions reported in release notes or issues

### Phase 5: Present Update Report
Present a clear table to the user (in Portuguese) showing:

```
## Relatório de Atualização do Hackintosh

### Componentes com Atualização Disponível
| Componente | Atual | Nova | Compatível | Notas |
|---|---|---|---|---|

### Componentes Já Atualizados (sem mudanças)
| Componente | Versão |
|---|---|

### Atualizações Bloqueadas (incompatíveis)
| Componente | Motivo |
|---|---|

### macOS Updates Disponíveis
| Update | Versão | Veredicto | Fontes | Notas |
|---|---|---|---|---|
```

Verdicts: SAFE / LIKELY SAFE / CAUTION / BLOCK

**Wait for user confirmation before proceeding to Phase 6.**

### Phase 6: Update EFI
Only after user confirms:

1. **Mount EFI partition**:
   - `diskutil list` to identify correct EFI (209 MB, next to APFS container — NOT the 105 MB "NO NAME" Windows EFI)
   - Ask user to run: `sudo diskutil mount diskXs1`
   - **NEVER assume disk identifiers — they change on every reboot**

2. **Backup EFI BEFORE updates**:
   - Create compressed backup on Desktop: `cd /Volumes/EFI && zip -r ~/Desktop/EFI-backup-$(date +%Y%m%d)-before.zip EFI/`
   - Do NOT keep a copy on the EFI partition (limited space, Desktop zip is sufficient)

3. **Download new kexts**:
   - Use `curl -L` to download release .zip files from GitHub to `/tmp/hackintosh-update/`
   - Extract and validate each kext has correct Info.plist

4. **Update kexts**:
   - Replace kexts in `/Volumes/EFI/EFI/OC/Kexts/` one by one
   - For VirtualSMC: update VirtualSMC.kext, SMCProcessor.kext, SMCSuperIO.kext together
   - **NEVER touch USBMap.kext** (custom)
   - **NEVER touch SSDT-NVOFF.aml** (custom)

5. **Update OpenCore** (if applicable):
   - Replace BOOTx64.efi, OpenCore.efi, and bundled drivers
   - **Check if config.plist needs schema changes**

6. **Preserve custom config.plist settings**:
   After any update, verify these are preserved:
   - boot-args: check memory file for current args (includes custom ones like `revpatch=sbvmm`, `-rad24`, `-radnogva`, etc.)
   - ScanPolicy: 2688771 (includes ESP for Windows dual-boot)
   - ShowPicker: true
   - HideAuxiliary: true
   - EnablePassword: false
   - All DeviceProperties (GPU, audio, disable-gpu entries)
   - All SSDT entries in ACPI:Add (including SSDT-NVOFF)
   - Kernel Block entries
   - ResizeGpuBars / ResizeAppleGpuBars settings

7. **Validate**:
   - Verify all kexts have valid Info.plist
   - Verify config.plist is valid (no syntax errors)
   - Count kexts match expected number

8. **Backup EFI AFTER updates**:
   - Create compressed backup on Desktop: `cd /Volumes/EFI && zip -r ~/Desktop/EFI-backup-$(date +%Y%m%d)-after.zip EFI/`
   - This captures the updated EFI state for reference or quick restore

### Phase 7: Post-Update Instructions
Provide clear instructions (in Portuguese) for:
1. Reboot and test
2. What to check after reboot (audio, Wi-Fi, Bluetooth, GPU, USB)
3. How to rollback if something breaks (rename EFI-backup back to EFI)
4. If macOS update is available, instructions to apply it

### Phase 8: Update Memory
After successful update, update the memory file with new versions:
`/Users/mpelos/.claude/projects/-Users-mpelos/memory/hackintosh.md`

## Safety Rules
- **ALWAYS backup EFI before any changes**
- **ALWAYS read memory file first** for current state
- **NEVER update USBMap.kext** (custom hardware-specific)
- **NEVER replace SSDT-NVOFF.aml** (custom, created by us)
- **NEVER suggest macOS Tahoe** unless explicitly asked
- **NEVER assume disk identifiers** — always verify with `diskutil list`
- **NEVER auto-reboot** — always give instructions for the user to do it
- **If OpenCore major version changes**, warn user about potential boot failure and ensure backup
- **If in doubt about compatibility, DON'T update** — ask user first
- **Lilu must be updated BEFORE dependent kexts** (WhateverGreen, AppleALC, VirtualSMC, etc.)

## Rollback Plan
If boot fails after update:
1. Boot from USB installer (if available)
2. Mount EFI: `diskutil mount diskXs1`
3. Remove current EFI: `rm -rf /Volumes/EFI/EFI`
4. Restore backup: `mv /Volumes/EFI/EFI-backup-YYYYMMDD /Volumes/EFI/EFI`
5. Reboot

Alternative: Reset NVRAM from OpenCore picker (press Space to show auxiliary, select Reset NVRAM)
