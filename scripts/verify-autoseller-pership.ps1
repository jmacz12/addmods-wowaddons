$ErrorActionPreference = "Stop"
$root = "C:\Projects\WoW-Addons\addons\AutoSeller"
$ui = Get-Content (Join-Path $root "UI.lua") -Raw
$core = Get-Content (Join-Path $root "Core.lua") -Raw
$cfg = Get-Content (Join-Path $root "Config.lua") -Raw
$toc = Get-Content (Join-Path $root "AutoSeller.toc") -Raw
$seller = Get-Content (Join-Path $root "Seller.lua") -Raw
$fail = New-Object System.Collections.Generic.List[string]

$tocVer = if ($toc -match '## Version:\s*(\S+)') { $Matches[1] } else { "?" }
$coreVer = if ($core -match 'MT\.VERSION\s*=\s*"([^"]+)"') { $Matches[1] } else { "?" }
if ($tocVer -ne "0.3.9" -or $coreVer -ne "0.3.9") {
  $fail.Add("Version mismatch toc=$tocVer core=$coreVer")
}

if ($ui -match 'SetText\("[^"]*MacTech') { $fail.Add("MacTech in SetText") }
if ($ui -match 'SoftNote\([^)]*MacTech') { $fail.Add("MacTech in SoftNote") }
if ($ui -match 'mtas') { $fail.Add("/mtas still referenced in UI") }
if ($core -match '/mtas') { $fail.Add("/mtas still registered") }
if ($ui -match 'Opt-in learning|Debug export') { $fail.Add("Debug/learning still on panels") }

$need = @(
  'Remember items I sell',
  'Clear all',
  'Enable keep-by-stats',
  'Resources / trade goods',
  'High-end \(Rare\+\)',
  'Consumables',
  'Soulbound \(if color not selling\)',
  'Enable auto-sell at merchants',
  'Gray junk',
  'White \(not resources\)',
  '"Green"',
  '"Blue"',
  '"Purple"',
  'By armor type',
  '"Cloth"',
  '"Leather"',
  '"Mail"',
  '"Plate"',
  'Sell weaker than equipped',
  'Repair gear when talking to a vendor',
  'My gold',
  'Guild bank',
  'Guild first, then my gold',
  'Sell now',
  'Scan bags',
  'Repair now',
  'Print link in chat',
  'Made by Add Mods',
  'AUTOSELLER_CLEAR_REMEMBERED',
  'AUTOSELLER_SELL_NOW',
  'RefreshRulesChecks',
  'TryAutoRepair\(true\)',
  'AutoSellerRulesKeepPanel',
  'AutoSellerRulesSellPanel',
  'AutoSellerRulesRepairPanel'
)
foreach ($n in $need) {
  if ($ui -notmatch $n) { $fail.Add("Missing UI piece: $n") }
}

$expected = @(
  'MT.db.learnOnSell',
  'MT.db.keep.byStats.enabled',
  'MT.db.keep.resources',
  'MT.db.keep.highEnd',
  'MT.db.keep.consumables',
  'MT.db.keep.soulbound',
  'MT.db.enabled',
  'MT.db.sellGray',
  'MT.db.sellWhite',
  'MT.db.sellGreen',
  'MT.db.sellBlue',
  'MT.db.sellEpic',
  'MT.db.sellArmor.cloth',
  'MT.db.sellArmor.leather',
  'MT.db.sellArmor.mail',
  'MT.db.sellArmor.plate',
  'MT.db.sellWeakerThanEquipped',
  'MT.db.autoRepair',
  'MT.db.repairPay'
)
foreach ($e in $expected) {
  if ($ui -notmatch [regex]::Escape($e)) { $fail.Add("Missing db write: $e") }
}
if ($ui -notmatch 'MT\.db\.keep\.byStats\[key\]') { $fail.Add("Stat keys not bound via byStats[key]") }

$keepIdx = $cfg.IndexOf('Hard safety: mats')
$statsIdx = $cfg.IndexOf('Keep-by-stats')
$colorIdx = $cfg.IndexOf('Color sells')
$armorIdx = $cfg.IndexOf('Armor type')
$remIdx = $cfg.IndexOf('Remembered list')
$weakIdx = $cfg.IndexOf('Weaker than equipped')
if (-not ($keepIdx -gt 0 -and $statsIdx -gt $keepIdx -and $colorIdx -gt $statsIdx -and $armorIdx -gt $colorIdx -and $remIdx -gt $armorIdx -and $weakIdx -gt $remIdx)) {
  $fail.Add("Sell/keep priority code order wrong")
}
if ($cfg -notmatch 'not colorSell') { $fail.Add("Soulbound/high-end may not yield to color") }
if ($cfg -notmatch 'never auto-sell resources') { $fail.Add("White resource hard-skip missing") }
if ($cfg -notmatch 'WEAKER_MAX_QUALITY = 2') { $fail.Add("Weaker should be green-max") }
if ($cfg -notmatch 'function MT:ArmorTypeSellEnabled') { $fail.Add("ArmorTypeSellEnabled missing") }
if ($cfg -notmatch 'Wrap UseContainerItem|capture the item before') { $fail.Add("Remember pre-capture wrap missing") }
if ($seller -notmatch 'function MT:TryAutoRepair\(force\)') { $fail.Add("TryAutoRepair(force) missing") }
if ($seller -notmatch 'if not force and not self\.db\.autoRepair') { $fail.Add("Manual repair force gate missing") }
if ($ui -notmatch 'StaticPopup_Show\("AUTOSELLER_CLEAR_REMEMBERED"\)') { $fail.Add("Clear all confirm not wired") }
if ($ui -notmatch 'StaticPopup_Show\("AUTOSELLER_SELL_NOW"\)') { $fail.Add("Sell now confirm not wired") }
if ($core -notmatch 'donate\.stripe\.com/4gM5kF0hv5NJ1oW1WA6c001') { $fail.Add("Donate URL wrong") }
if ($core -notmatch 'jmacz12/addmods-wowaddons/releases') { $fail.Add("Download URL wrong") }
if ($core -match 'control\.mactech') { $fail.Add("Owner inbox leaked into Core") }
if ($core -notmatch 'sellArmor') { $fail.Add("sellArmor defaults missing") }

function Test-Matrix([hashtable]$s) {
  if ($s.resourcesKeep -and $s.isResource) { return "keep:resources" }
  if ($s.consumablesKeep -and $s.isConsumable) { return "keep:consumables" }
  if ($s.statsOn -and $s.hasStat) { return "keep:stats" }
  if ($s.soulboundKeep -and -not $s.colorSell -and $s.isSoulbound) { return "keep:soulbound" }
  if ($s.highEndKeep -and -not $s.colorSell -and $s.q -ge 3) { return "keep:high-end" }
  if ($s.colorSell) {
    if ($s.q -eq 1 -and $s.isResource) { return "skip:white-resource" }
    return "sell:color"
  }
  if ($s.armorSell) { return "sell:armor" }
  if ($s.remembered) { return "sell:remembered" }
  if ($s.weakerOn -and $s.isWeaker -and $s.q -le 2) { return "sell:weaker" }
  return "skip"
}

$cases = @(
  @{ name = 'green+stat vs green sell'; exp = 'keep:stats'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $true; hasStat = $true; soulboundKeep = $true; isSoulbound = $false; highEndKeep = $true; q = 2; colorSell = $true; armorSell = $true; remembered = $false; weakerOn = $true; isWeaker = $true },
  @{ name = 'blue soulbound color wins'; exp = 'sell:color'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $true; isSoulbound = $true; highEndKeep = $true; q = 3; colorSell = $true; armorSell = $false; remembered = $false; weakerOn = $false; isWeaker = $false },
  @{ name = 'blue soulbound no color keep'; exp = 'keep:soulbound'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $true; isSoulbound = $true; highEndKeep = $true; q = 3; colorSell = $false; armorSell = $true; remembered = $true; weakerOn = $false; isWeaker = $false },
  @{ name = 'white resource never color-sold'; exp = 'skip:white-resource'; resourcesKeep = $false; consumablesKeep = $true; isResource = $true; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $false; isSoulbound = $false; highEndKeep = $false; q = 1; colorSell = $true; armorSell = $false; remembered = $false; weakerOn = $false; isWeaker = $false },
  @{ name = 'plate armor before remember'; exp = 'sell:armor'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $true; isSoulbound = $false; highEndKeep = $true; q = 2; colorSell = $false; armorSell = $true; remembered = $true; weakerOn = $true; isWeaker = $true },
  @{ name = 'remembered after keeps'; exp = 'sell:remembered'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $true; isSoulbound = $false; highEndKeep = $true; q = 2; colorSell = $false; armorSell = $false; remembered = $true; weakerOn = $true; isWeaker = $true },
  @{ name = 'weaker only if no remember/color'; exp = 'sell:weaker'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $true; isSoulbound = $false; highEndKeep = $true; q = 2; colorSell = $false; armorSell = $false; remembered = $false; weakerOn = $true; isWeaker = $true },
  @{ name = 'blue weaker blocked by q'; exp = 'skip'; resourcesKeep = $true; consumablesKeep = $true; isResource = $false; isConsumable = $false; statsOn = $false; hasStat = $false; soulboundKeep = $false; isSoulbound = $false; highEndKeep = $false; q = 3; colorSell = $false; armorSell = $false; remembered = $false; weakerOn = $true; isWeaker = $true },
  @{ name = 'herb kept before stats'; exp = 'keep:resources'; resourcesKeep = $true; consumablesKeep = $true; isResource = $true; isConsumable = $false; statsOn = $true; hasStat = $true; soulboundKeep = $true; isSoulbound = $false; highEndKeep = $true; q = 1; colorSell = $true; armorSell = $false; remembered = $false; weakerOn = $false; isWeaker = $false }
)

foreach ($c in $cases) {
  $got = Test-Matrix $c
  if ($got -ne $c.exp) { $fail.Add("Matrix $($c.name): got $got expected $($c.exp)") }
}

Write-Host "=== PRE-SHIP VERIFICATION ==="
Write-Host "Version: toc=$tocVer core=$coreVer"
Write-Host "Matrix cases: $($cases.Count)"
if ($fail.Count -eq 0) {
  Write-Host "PASS: all checks clean"
  exit 0
}
Write-Host "FAIL:"
$fail | ForEach-Object { Write-Host " - $_" }
exit 1
