<#
.SYNOPSIS
    Sets Windows to draw grayscale text on WOLED screens, to match the MacType profile.

.DESCRIPTION
    MacType fixes text in most apps, but some (Office, the Settings app, other
    modern apps) draw text without it. This script makes Windows itself draw
    grayscale text, so those apps lose the color fringing too:

      1. Turns on grayscale font smoothing for the whole system (ClearType color off).
      2. For each WOLED screen you pick, sets its DirectWrite text settings to flat
         grayscale (PixelStructure 0, ClearTypeLevel 0).
      3. Optionally turns off Office graphics acceleration so Office follows them.

    Only your own user settings (HKCU) change; no admin rights are needed.
    Before changing anything, it saves an undo file on your Desktop.

.PARAMETER DryRun
    Show the screens and what would change, without changing anything.

.EXAMPLE
    .\apply-woled-text.ps1 -DryRun
#>
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WoledText {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool EnumDisplayDevices(string device, uint index, ref DISPLAY_DEVICE dd, uint flags);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint action, uint uiParam, IntPtr pvParam, uint winIni);
}
"@

$DesktopKey = 'HKCU:\Control Panel\Desktop'
$AvalonKey  = 'HKCU:\Software\Microsoft\Avalon.Graphics'
$OfficeKey  = 'HKCU:\Software\Microsoft\Office\16.0\Common\Graphics'

# The values the profile was tuned with on an ASUS ROG Strix OLED XG32UCWG.
$SmoothingContrast = 1400
$ScreenValues = [ordered]@{
    PixelStructure                 = 0     # flat: no RGB/BGR subpixel layout
    ClearTypeLevel                 = 0     # no color in the anti-aliasing
    GrayscaleEnhancedContrastLevel = 200
    GammaLevel                     = 1800
    TextContrastLevel              = 2
    EnhancedContrastLevel          = 100
}

# Common monitor maker codes, so the list shows "ASUS" instead of "AUS".
$Makers = @{
    AUS = 'ASUS'; GSM = 'LG'; DEL = 'Dell'; SAM = 'Samsung'; ACR = 'Acer'; GBT = 'Gigabyte'
    AOC = 'AOC'; PHL = 'Philips'; LEN = 'Lenovo'; HPN = 'HP'; MSI = 'MSI'; BNQ = 'BenQ'; SNY = 'Sony'
}

function Get-Screens {
    $wmi = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue)
    $screens = @()
    for ($i = 0; $i -lt 32; $i++) {
        $adapter = New-Object WoledText+DISPLAY_DEVICE
        $adapter.cb = [Runtime.InteropServices.Marshal]::SizeOf($adapter)
        if (-not [WoledText]::EnumDisplayDevices([NullString]::Value, $i, [ref]$adapter, 0)) { break }
        if (($adapter.StateFlags -band 1) -eq 0) { continue }   # not part of the desktop

        # The monitor's ID looks like MONITOR\AUS32F6\{...}; AUS32F6 links it to its EDID name.
        $monitor = New-Object WoledText+DISPLAY_DEVICE
        $monitor.cb = $adapter.cb
        $code = ''
        if ([WoledText]::EnumDisplayDevices($adapter.DeviceName, 0, [ref]$monitor, 0)) {
            $parts = $monitor.DeviceID -split '\\'
            if ($parts.Count -gt 1) { $code = $parts[1] }
        }

        $name = ''
        foreach ($w in $wmi) {
            if ($code -and $w.InstanceName -like "DISPLAY\$code\*") {
                $maker = -join ($w.ManufacturerName | Where-Object { $_ } | ForEach-Object { [char]$_ })
                $model = -join ($w.UserFriendlyName | Where-Object { $_ } | ForEach-Object { [char]$_ })
                if ($Makers.ContainsKey($maker)) { $maker = $Makers[$maker] }
                $name = "$maker $model".Trim()
                break
            }
        }
        if (-not $name) { $name = $monitor.DeviceString }
        if (-not $name) { $name = 'Unknown screen' }

        $screens += [pscustomobject]@{
            Number = $screens.Count + 1
            Name   = $name
            Key    = $adapter.DeviceName.TrimStart('\', '.')   # \\.\DISPLAY1 -> DISPLAY1
        }
    }
    return $screens
}

function Format-RegValue($key, $name) {
    $item = Get-Item -Path $key -ErrorAction SilentlyContinue
    if (-not $item -or $item.GetValueNames() -notcontains $name) { return "`"$name`"=-" }
    $value = $item.GetValue($name)
    switch ($item.GetValueKind($name)) {
        'DWord'  { return "`"$name`"=dword:{0:x8}" -f [uint32]$value }
        'String' { return "`"$name`"=`"$value`"" }
        default  { return $null }
    }
}

function Save-UndoFile($screens, $includeOffice) {
    $lines = @('Windows Registry Editor Version 5.00', '')
    $lines += '[HKEY_CURRENT_USER\Control Panel\Desktop]'
    foreach ($n in 'FontSmoothing', 'FontSmoothingType', 'FontSmoothingGamma') {
        $line = Format-RegValue $DesktopKey $n
        if ($line -and $line -notmatch '=-$') { $lines += $line }
    }
    foreach ($s in $screens) {
        $lines += ''
        $path = "$AvalonKey\$($s.Key)"
        if (-not (Test-Path $path)) {
            $lines += "[-HKEY_CURRENT_USER\Software\Microsoft\Avalon.Graphics\$($s.Key)]"
            continue
        }
        $lines += "[HKEY_CURRENT_USER\Software\Microsoft\Avalon.Graphics\$($s.Key)]"
        foreach ($n in $ScreenValues.Keys) { $lines += (Format-RegValue $path $n) }
    }
    if ($includeOffice) {
        $lines += ''
        $lines += '[HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Common\Graphics]'
        $lines += (Format-RegValue $OfficeKey 'DisableHardwareAcceleration')
    }
    $stamp = Get-Date -Format 'yyyy-MM-dd HHmm'
    $file = Join-Path ([Environment]::GetFolderPath('Desktop')) "WOLED text - undo ($stamp).reg"
    [IO.File]::WriteAllText($file, (($lines -join "`r`n") + "`r`n"), [Text.Encoding]::Unicode)
    return $file
}

# ---------------------------------------------------------------------------

Write-Host ''
Write-Host 'WOLED text fix: Windows settings' -ForegroundColor White
Write-Host ''

$screens = @(Get-Screens)
if ($screens.Count -eq 0) { throw 'No screens found.' }

Write-Host 'Screens found:'
foreach ($s in $screens) { Write-Host ('  {0}  {1,-28} ({2})' -f $s.Number, $s.Name, $s.Key) }
Write-Host ''

$picked = @()
while ($picked.Count -eq 0) {
    if ($screens.Count -eq 1) {
        $answer = Read-Host 'Is this a WOLED screen? Press Enter for yes, or type n to stop'
        if ($answer -match '^\s*n') { Write-Host 'Nothing changed.'; return }
        $picked = $screens
    } else {
        $answer = Read-Host 'Which of these are WOLED screens? Type the numbers, like 1 or 1,2'
        $numbers = @($answer -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
        $picked = @($screens | Where-Object { $numbers -contains $_.Number })
        if ($picked.Count -eq 0) { Write-Host 'Please type at least one number from the list.' -ForegroundColor Yellow }
    }
}

$office = $false
if (Test-Path 'HKCU:\Software\Microsoft\Office\16.0') {
    $answer = Read-Host 'Office is installed. Make Office text gray too? It turns off Office graphics acceleration. (y/N)'
    $office = $answer -match '^\s*y'
}

Write-Host ''
Write-Host 'Changes:'
Write-Host '  Whole system:  grayscale text (ClearType color off)'
foreach ($s in $picked) { Write-Host "  $($s.Name):  flat grayscale text ($($s.Key))" }
if ($office) { Write-Host '  Office:  graphics acceleration off' }
Write-Host ''

if ($DryRun) {
    Write-Host 'Dry run: nothing changed.' -ForegroundColor Yellow
    return
}

$undo = Save-UndoFile $picked $office

# Whole system: grayscale font smoothing. SystemParametersInfo saves the setting
# and tells running apps about it.
$SPIF = 0x1 -bor 0x2   # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
[void][WoledText]::SystemParametersInfo(0x004B, 1, [IntPtr]::Zero, $SPIF)                  # SPI_SETFONTSMOOTHING on
[void][WoledText]::SystemParametersInfo(0x200B, 0, [IntPtr]1, $SPIF)                       # SPI_SETFONTSMOOTHINGTYPE standard (grayscale)
[void][WoledText]::SystemParametersInfo(0x200D, 0, [IntPtr]$SmoothingContrast, $SPIF)      # SPI_SETFONTSMOOTHINGCONTRAST

# Each WOLED screen: flat grayscale DirectWrite text.
foreach ($s in $picked) {
    $path = "$AvalonKey\$($s.Key)"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    foreach ($n in $ScreenValues.Keys) {
        New-ItemProperty -Path $path -Name $n -PropertyType DWord -Value $ScreenValues[$n] -Force | Out-Null
    }
}

if ($office) {
    if (-not (Test-Path $OfficeKey)) { New-Item -Path $OfficeKey -Force | Out-Null }
    New-ItemProperty -Path $OfficeKey -Name 'DisableHardwareAcceleration' -PropertyType DWord -Value 1 -Force | Out-Null
}

Write-Host 'Done.' -ForegroundColor Green
Write-Host 'Sign out and back in (or restart) so every app picks this up.'
Write-Host ''
Write-Host 'To undo, double-click the file saved on your Desktop:'
Write-Host "  $undo"
Write-Host ''
Write-Host 'Note: running the ClearType Text Tuner later resets these screen settings. Run this file again after it.'
