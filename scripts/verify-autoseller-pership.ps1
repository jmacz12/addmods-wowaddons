$ErrorActionPreference = "Stop"
$root = "C:\Projects\WoW-Addons\addons\AutoSeller"
$ui = Get-Content (Join-Path $root "UI.lua") -Raw
$core = Get-Content (Join-Path $root "Core.lua") -Raw
$cfg = Get-Content (Join-Path $root "Config.lua") -Raw
$toc = Get-Content (Join-Path $root "AutoSeller.toc") -Raw
$seller = Get-Content (Join-Path $root "Seller.lua") -Raw
$fail = New-Object System.Collections.Generic.List[string]

$EXPECTED_VER = "0.3.11"
$tocVer = if ($toc -match '## Version:\s*(\S+)') { $Matches[1] } else { "?" }
$coreVer = if ($core -match 'MT\.VERSION\s*=\s*"([^"]+)"') { $Matches[1] } else { "?" }
if ($tocVer -ne $EXPECTED_VER -or $coreVer -ne $EXPECTED_VER) {
  $fail.Add("Version mismatch toc=$tocVer core=$coreVer expected=$EXPECTED_VER")
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
if ($cfg -notmatch 'itemType ~= "Armor"') { $fail.Add("Armor sell must require Armor type (not cloth mats)") }
if ($cfg -notmatch 'quality < 1 then return false') { $fail.Add("Remember must skip gray only") }
if ($cfg -match 'quality == 1 and self\.db\.sellWhite then return') { $fail.Add("Remember still skips whites when sellWhite on") }
if ($cfg -notmatch 'CapturePending|GetLinkQuality') { $fail.Add("Remember pre-capture / quality helpers missing") }
if ($seller -notmatch 'function MT:TryAutoRepair\(force\)') { $fail.Add("TryAutoRepair(force) missing") }
if ($seller -notmatch 'if not force and not self\.db\.autoRepair') { $fail.Add("Manual repair force gate missing") }
if ($ui -notmatch 'StaticPopup_Show\("AUTOSELLER_CLEAR_REMEMBERED"\)') { $fail.Add("Clear all confirm not wired") }
if ($ui -notmatch 'StaticPopup_Show\("AUTOSELLER_SELL_NOW"\)') { $fail.Add("Sell now confirm not wired") }
if ($core -notmatch 'donate\.stripe\.com/4gM5kF0hv5NJ1oW1WA6c001') { $fail.Add("Donate URL wrong") }
if ($core -notmatch 'jmacz12/addmods-wowaddons/releases') { $fail.Add("Download URL wrong") }
if ($core -match 'control\.mactech') { $fail.Add("Owner inbox leaked into Core") }
if ($core -notmatch 'sellArmor') { $fail.Add("sellArmor defaults missing") }

# Mirrors GetKeepReason → GetSellReason
# Remembered skips resource/consumable keeps only; stats/soulbound/high-end still win.
function Test-KeepSell([hashtable]$s) {
  if ($s.unsellable) { return "skip:unsellable" }
  if (-not $s.remembered) {
    if ($s.resourcesKeep -and $s.isResource) { return "keep:resources" }
    if ($s.consumablesKeep -and $s.isConsumable) { return "keep:consumables" }
  }
  if ($s.statsOn -and $s.hasStat) { return "keep:stats" }
  if ($s.soulboundKeep -and -not $s.colorSell -and $s.isSoulbound) { return "keep:soulbound" }
  if ($s.highEndKeep -and -not $s.colorSell -and $s.q -ge 3) { return "keep:high-end" }
  if ($s.colorSell) {
    # White resources never sell via color; remembered can still dump them next
    if ($s.q -eq 1 -and $s.isResource) {
      if ($s.remembered) { return "sell:remembered" }
      return "skip:white-resource"
    }
    return "sell:color"
  }
  # Armor gear only — cloth/leather mats never count as armorSell in real code
  if ($s.armorSell -and $s.isArmorGear) { return "sell:armor" }
  if ($s.remembered) { return "sell:remembered" }
  if ($s.weakerOn -and $s.isWeaker -and $s.q -le 2) { return "sell:weaker" }
  return "skip"
}

# Mirrors RememberSellItem: gray skipped; whites+ added when learnOnSell
function Test-Remember([hashtable]$s) {
  if (-not $s.learnOnSell) { return "no" }
  if ($s.q -lt 1) { return "no-gray" }
  return "yes"
}

function Case([string]$name, [string]$exp, [hashtable]$props) {
  $h = @{ name = $name; exp = $exp }
  foreach ($k in $props.Keys) { $h[$k] = $props[$k] }
  # Defaults so each case need not repeat everything
  if (-not $h.ContainsKey('resourcesKeep')) { $h.resourcesKeep = $true }
  if (-not $h.ContainsKey('consumablesKeep')) { $h.consumablesKeep = $true }
  if (-not $h.ContainsKey('isResource')) { $h.isResource = $false }
  if (-not $h.ContainsKey('isConsumable')) { $h.isConsumable = $false }
  if (-not $h.ContainsKey('statsOn')) { $h.statsOn = $false }
  if (-not $h.ContainsKey('hasStat')) { $h.hasStat = $false }
  if (-not $h.ContainsKey('soulboundKeep')) { $h.soulboundKeep = $true }
  if (-not $h.ContainsKey('isSoulbound')) { $h.isSoulbound = $false }
  if (-not $h.ContainsKey('highEndKeep')) { $h.highEndKeep = $true }
  if (-not $h.ContainsKey('q')) { $h.q = 1 }
  if (-not $h.ContainsKey('colorSell')) { $h.colorSell = $false }
  if (-not $h.ContainsKey('armorSell')) { $h.armorSell = $false }
  if (-not $h.ContainsKey('isArmorGear')) { $h.isArmorGear = $false }
  if (-not $h.ContainsKey('remembered')) { $h.remembered = $false }
  if (-not $h.ContainsKey('weakerOn')) { $h.weakerOn = $false }
  if (-not $h.ContainsKey('isWeaker')) { $h.isWeaker = $false }
  if (-not $h.ContainsKey('unsellable')) { $h.unsellable = $false }
  return $h
}

$cases = @(
  # Hard keeps win over every sell path
  (Case "herb kept before color/stats/armor" "keep:resources" @{ isResource = $true; statsOn = $true; hasStat = $true; colorSell = $true; armorSell = $true; isArmorGear = $true; remembered = $false; weakerOn = $true; isWeaker = $true; q = 1 }),
  (Case "potion kept before color" "keep:consumables" @{ isConsumable = $true; colorSell = $true; remembered = $false; q = 1 }),
  (Case "green intellect kept vs green+plate+remember" "keep:stats" @{ statsOn = $true; hasStat = $true; colorSell = $true; armorSell = $true; isArmorGear = $true; remembered = $true; weakerOn = $true; isWeaker = $true; q = 2 }),

  # Soft keeps only when color not selling
  (Case "blue soulbound + blue sell = sell" "sell:color" @{ isSoulbound = $true; q = 3; colorSell = $true }),
  (Case "blue soulbound + no blue sell = keep" "keep:soulbound" @{ isSoulbound = $true; q = 3; colorSell = $false; armorSell = $true; isArmorGear = $true; remembered = $true }),
  (Case "blue high-end + no blue sell = keep" "keep:high-end" @{ q = 3; colorSell = $false; armorSell = $true; isArmorGear = $true; remembered = $true }),
  (Case "blue high-end OFF + plate ON = sell armor" "sell:armor" @{ highEndKeep = $false; soulboundKeep = $false; q = 3; colorSell = $false; armorSell = $true; isArmorGear = $true }),

  # Resources hard-skip on white color even if Keep resources off
  (Case "white cloth mat never color-sold" "skip:white-resource" @{ resourcesKeep = $false; isResource = $true; q = 1; colorSell = $true }),

  # Cloth mats vs Cloth armor: mats are NOT armor gear
  (Case "cloth mat with Cloth armor toggle = skip not armor" "skip" @{ isResource = $false; resourcesKeep = $false; q = 2; colorSell = $false; armorSell = $true; isArmorGear = $false }),
  (Case "cloth robe with Cloth armor toggle = sell armor" "sell:armor" @{ q = 2; colorSell = $false; armorSell = $true; isArmorGear = $true }),

  # Sell priority after keeps
  (Case "green color before plate/remember/weaker" "sell:color" @{ q = 2; colorSell = $true; armorSell = $true; isArmorGear = $true; remembered = $true; weakerOn = $true; isWeaker = $true }),
  (Case "plate before remember/weaker" "sell:armor" @{ q = 2; colorSell = $false; armorSell = $true; isArmorGear = $true; remembered = $true; weakerOn = $true; isWeaker = $true }),
  (Case "remembered after keeps no color/armor" "sell:remembered" @{ q = 2; remembered = $true; weakerOn = $true; isWeaker = $true }),
  (Case "remembered herb dumps despite Keep resources" "sell:remembered" @{ isResource = $true; remembered = $true; q = 1 }),
  (Case "remembered low potion dumps despite Keep consumables" "sell:remembered" @{ isConsumable = $true; remembered = $true; q = 1 }),
  (Case "remembered green with Intellect still kept by stats" "keep:stats" @{ statsOn = $true; hasStat = $true; remembered = $true; q = 2 }),
  (Case "unremembered herb still kept" "keep:resources" @{ isResource = $true; remembered = $false; q = 1 }),
  (Case "weaker only if no remember/color/armor" "sell:weaker" @{ q = 2; weakerOn = $true; isWeaker = $true }),
  (Case "blue weaker blocked by quality" "skip" @{ highEndKeep = $false; soulboundKeep = $false; q = 3; weakerOn = $true; isWeaker = $true }),
  (Case "green equal/stronger than equipped = skip" "skip" @{ q = 2; weakerOn = $true; isWeaker = $false }),

  # Unsellable
  (Case "quest item no vendor price = skip" "skip:unsellable" @{ unsellable = $true; colorSell = $true; q = 1 }),

  # Defaults-ish everyday bag
  (Case "gray junk color sell" "sell:color" @{ q = 0; colorSell = $true }),
  (Case "white junk color sell" "sell:color" @{ q = 1; colorSell = $true }),
  (Case "green no rules = skip safe default" "skip" @{ q = 2 })
)

foreach ($c in $cases) {
  $got = Test-KeepSell $c
  if ($got -ne $c.exp) { $fail.Add("Keep/Sell [$($c.name)]: got $got expected $($c.exp)") }
}

$rememberCases = @(
  @{ name = "gray not remembered"; q = 0; learnOnSell = $true; exp = "no-gray" },
  @{ name = "white remembered even if sellWhite on"; q = 1; learnOnSell = $true; exp = "yes" },
  @{ name = "green remembered"; q = 2; learnOnSell = $true; exp = "yes" },
  @{ name = "blue remembered"; q = 3; learnOnSell = $true; exp = "yes" },
  @{ name = "learn toggle off"; q = 2; learnOnSell = $false; exp = "no" }
)
foreach ($c in $rememberCases) {
  $got = Test-Remember $c
  if ($got -ne $c.exp) { $fail.Add("Remember [$($c.name)]: got $got expected $($c.exp)") }
}

Write-Host "=== PRE-SHIP VERIFICATION ==="
Write-Host "Version: toc=$tocVer core=$coreVer"
Write-Host "Keep/Sell scenarios: $($cases.Count)"
Write-Host "Remember scenarios: $($rememberCases.Count)"
if ($fail.Count -eq 0) {
  Write-Host "PASS: all checks clean"
  exit 0
}
Write-Host "FAIL ($($fail.Count)):"
$fail | ForEach-Object { Write-Host " - $_" }
exit 1
