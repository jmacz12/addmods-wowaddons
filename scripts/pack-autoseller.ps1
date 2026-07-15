$root = Join-Path $PSScriptRoot ".."
$addon = Join-Path $root "addons\AutoSeller"
$outDir = Join-Path $root "dist"
$zip = Join-Path $outDir "AutoSeller-0.3.0.zip"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (Test-Path $zip) { Remove-Item $zip -Force }

Compress-Archive -Path $addon -DestinationPath $zip
Write-Host "Packed $zip"
