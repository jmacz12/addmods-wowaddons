$root = Join-Path $PSScriptRoot ".."
$addon = Join-Path $root "addons\MacTech_AutoSeller"
$outDir = Join-Path $root "dist"
$zip = Join-Path $outDir "MacTech_AutoSeller-0.1.0.zip"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (Test-Path $zip) { Remove-Item $zip -Force }

Compress-Archive -Path $addon -DestinationPath $zip
Write-Host "Packed $zip"
