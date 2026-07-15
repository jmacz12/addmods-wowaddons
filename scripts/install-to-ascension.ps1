param(
  [Parameter(Mandatory = $true)]
  [string]$AscensionPath
)

$source = Join-Path $PSScriptRoot "..\addons\AutoSeller" | Resolve-Path
$destRoot = Join-Path $AscensionPath "Interface\AddOns"
$dest = Join-Path $destRoot "AutoSeller"
$legacy = Join-Path $destRoot "MacTech_AutoSeller"

if (-not (Test-Path $destRoot)) {
  New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
}

if (Test-Path $legacy) {
  Remove-Item -Recurse -Force $legacy
}

if (Test-Path $dest) {
  Remove-Item -Recurse -Force $dest
}

Copy-Item -Recurse -Force $source $dest
Write-Host "Installed AutoSeller & Repair -> $dest"
