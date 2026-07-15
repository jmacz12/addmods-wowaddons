param(
  [Parameter(Mandatory = $true)]
  [string]$AscensionPath
)

$source = Join-Path $PSScriptRoot "..\addons\MacTech_AutoSeller" | Resolve-Path
$destRoot = Join-Path $AscensionPath "Interface\AddOns"
$dest = Join-Path $destRoot "MacTech_AutoSeller"

if (-not (Test-Path $destRoot)) {
  New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
}

if (Test-Path $dest) {
  Remove-Item -Recurse -Force $dest
}

Copy-Item -Recurse -Force $source $dest
Write-Host "Installed AutoSeller (MacTech_AutoSeller folder) -> $dest"
