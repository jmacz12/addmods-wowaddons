$root = Join-Path $PSScriptRoot ".."
$addon = Join-Path $root "addons\AutoSeller"
$outDir = Join-Path $root "dist"
$version = (Select-String -Path (Join-Path $addon "AutoSeller.toc") -Pattern '^## Version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$zip = Join-Path $outDir "AutoSeller-Repair-$version.zip"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (Test-Path $zip) { Remove-Item $zip -Force }

Compress-Archive -Path $addon -DestinationPath $zip
Write-Host "Packed $zip"
