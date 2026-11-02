<div align="center">

# WOLED Text Fix

**Sharp, fringe-free text on WOLED screens in Windows.**

A tuned MacType profile and the matching Windows settings, made for screens with a red, white, blue, green subpixel layout.

[Get the profile](profiles/RWBG_WOLED_Clean.ini) · [Setup in 4 steps](#setup)

</div>

<img src="docs/media/woled-text-fix.webp" width="100%" alt="WOLED Text Fix: the camera dives into a word on an OLED monitor until its red, white, blue and green subpixels show. With ClearType the colored subpixels light up along letter edges; with the WOLED profile only the white ones do. Then the four setup steps: winget install MacType, copy RWBG_WOLED_Clean.ini into MacType's ini folder, choose Run as a service and the profile in MacType Wizard, and run apply-woled-text.cmd. It ends with a before and after wipe on real text." />

## Why text fringes on WOLED

Windows smooths text with ClearType. ClearType assumes every pixel is a red, a green and a blue stripe, in that order, and lights those stripes separately to make letter edges look finer.

WOLED panels (the OLED type made by LG, used in many OLED monitors and TVs) lay each pixel out as red, white, blue, green. The color ClearType adds lands on the wrong stripes, so letters get colored edges. Turning ClearType off removes the color, but Windows' own gray text looks thin and soft.

This fix makes text gray everywhere and tunes it for WOLED:

- **MacType with `RWBG_WOLED_Clean.ini`** redraws text in most apps: grayscale smoothing, no hinting (so small text has no hard, jagged edges), a slightly heavier weight, and settings for each browser family.
- **`apply-woled-text.cmd`** sets Windows itself to gray text, for the apps MacType can't reach, like Office and the Settings app.

## Screens

| Screen | Result |
|---|---|
| **ASUS ROG Strix OLED XG32UCWG** (32", 4K, WOLED) | Tuned on this screen. The best result. |
| Other WOLED screens | Same subpixel layout, so the same fix applies. Text weight may want a small change (see [Tuning](#tuning)). |
| QD-OLED screens | Gray text has no color to fringe, so it helps there too. Weight and contrast were not tuned for them. |

## Setup

About five minutes, on Windows 10 or 11.

### 1. Get MacType

```powershell
winget install MacType.MacType
```

Or run the installer from [MacType's releases](https://github.com/snowie2000/mactype/releases/latest).

### 2. Add the profile

Download [`RWBG_WOLED_Clean.ini`](profiles/RWBG_WOLED_Clean.ini) (or this whole repo as a ZIP) and copy it into:

```text
C:\Program Files\MacType\ini
```

Windows asks for admin permission because the folder is under Program Files. Click **Continue**.

### 3. Turn it on in MacType Wizard

1. Open **MacType Wizard** from the Start menu.
2. Choose **Run as a service**, then click **Next**.
3. Click **RWBG_WOLED_Clean**, then click **Apply**.

Service mode starts with Windows and reaches the most apps. The wizard recommends System Tray mode, and the profile works there too.

### 4. Match Windows

Double-click [`windows/apply-woled-text.cmd`](windows/apply-woled-text.cmd). It:

- lists your screens and asks which ones are WOLED,
- sets Windows to gray text (ClearType color off),
- gives those screens flat gray DirectWrite text, which Office, Settings and other modern apps use,
- if Office is installed, offers to make Office follow these settings (this turns off Office graphics acceleration).

It changes only your own user settings (no admin rights needed), and saves an undo file on your Desktop first. To see what it would change without changing anything, run `.\apply-woled-text.ps1 -DryRun` in PowerShell from the `windows` folder.

**Then sign out and back in** (or restart), and fully close and reopen your browsers, so every app picks up the new text.

## Check it worked

Open a page with black text on white and zoom in with Magnifier (Windows key + Plus). Letter edges should be gray, with no red, green or blue.

## Profiles

| File | What it is |
|---|---|
| [`RWBG_WOLED_Clean.ini`](profiles/RWBG_WOLED_Clean.ini) | **Recommended.** Gray, unhinted, slightly heavy, no shadow. |
| [`RWBG_Woled-Bo0ii V2.ini`](profiles/RWBG_Woled-Bo0ii%20V2.ini) | Earlier version. Lighter, with small-font hinting on, which can make small text look harder. |

What the recommended profile sets:

| Setting | Value | Why |
|---|---|---|
| `AntiAliasMode`, `LcdFilter` | `0`, `0` | Gray smoothing, no subpixel color. |
| `HintingMode`, `HintSmallFont` | `1`, `0` | No hinting, so small text keeps soft, even edges. |
| `RenderWeight` | `1.09` | A little heavier than plain gray text, which looks thin on OLED. |
| `GammaValue`, `Contrast` | `1.5`, `0.90` | Smooth edges without washed-out stems. |
| `[DirectWrite]` `RenderingMode`, `ClearTypeLevel` | `5`, `0` | Gray text in DirectWrite apps too. |
| Browser sections | `InvertColor=1` (Chromium), `ClipBoxFix=1` (Firefox family) | Fixes for how each browser draws text. |

### Tuning

Text too thin or too bold for your screen? Open the profile in `C:\Program Files\MacType\ini`, change `RenderWeight` (try `1.00` to `1.20`), save, then restart MacType: run `Restart-Service MacType` in an admin PowerShell, or restart Windows.

## Undo

- **Windows settings:** double-click the `WOLED text - undo (...).reg` file that step 4 saved on your Desktop, then sign out and back in.
- **MacType:** pick another profile in MacType Wizard, or uninstall MacType from Settings > Apps.

## Notes

- **ArmBreaker:** the profile sets `ArmBreaker=2`, MacType's strongest option for loading into protected processes such as browsers. It can weaken some process protections. For a milder setting, change it to `ArmBreaker=1`.
- **ClearType Text Tuner** resets the per-screen settings from step 4. Run `apply-woled-text.cmd` again after using it.
- **Screen numbers can change** when you plug in, unplug or rearrange screens, and the step 4 settings stay with the old number. Run the script again after changing your screens.
- Some apps draw text their own way (games, some GPU-drawn apps) and keep their own look.
- Faint colored outlines around icons on WOLED come from the panel itself, not from text rendering, so software can't fix them.

## Credits

Profile tuning by Bo0ii. Built on [MacType](https://github.com/snowie2000/mactype) by FlyingSnow (GPL-3.0).
