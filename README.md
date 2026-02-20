# WOLED Text Fringing Fix (MacType Profile)

A tuned MacType profile focused on reducing color fringing and improving text clarity on WOLED displays while keeping broad app/browser compatibility.

## Included Profile

- `profiles/RWBG_Woled-Bo0ii V2.ini`

## What This Profile Is Optimized For

- WOLED displays where RGB subpixel assumptions can look wrong
- Neutral grayscale-style rendering feel (`AntiAliasMode=0`, `LcdFilter=0`)
- Better browser coverage with DirectWrite and per-browser overrides

## Browser Coverage

This profile includes overrides for:

- Chromium family: `chrome.exe`, `msedge.exe`, `brave.exe`, `opera.exe`, `vivaldi.exe`, `chromium.exe`, `arc.exe`, `msedgewebview2.exe`
- Firefox family: `firefox.exe`, `waterfox.exe`, `librewolf.exe`, `zen.exe`

Note: MacType cannot reliably inject every sandboxed renderer process in every browser build. This profile maximizes practical coverage without disabling browser sandbox.

## Install

1. Install MacType and run it in **Service Mode**.
2. Copy `profiles/RWBG_Woled-Bo0ii V2.ini` into your MacType `ini` folder (usually `C:\Program Files\MacType\ini\`).
3. Open MacType Wizard and select this profile.
4. Restart MacType service (or reboot).
5. Fully close browsers (including background processes) and reopen.

## Safety / Compatibility

This profile uses:

- `[Experimental]`
- `ArmBreaker=2`

`ArmBreaker=2` is the most aggressive compatibility option and may reduce some process protections to improve injection success.

If you want a safer variant, change:

- `ArmBreaker=2` -> `ArmBreaker=1`

## Known Limitations

- Some modern apps draw text with pipelines MacType does not fully control.
- Coverage can vary by OS build, browser version, and security policy.

## Credits

Profile tuning by Bo0ii.
