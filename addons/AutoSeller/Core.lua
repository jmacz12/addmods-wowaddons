MacTechAutoSeller = MacTechAutoSeller or {}
local MT = MacTechAutoSeller

MT.ADDON_NAME = "AutoSeller & Repair"
MT.VERSION = "0.3.10"
MT.CHAT_TAG = "|cff55ccffAutoSeller & Repair|r"
MT.DONATE_URL = "https://donate.stripe.com/4gM5kF0hv5NJ1oW1WA6c001"
MT.DOWNLOAD_URL = "https://github.com/jmacz12/addmods-wowaddons/releases"

local defaults = {
  enabled = true,
  optInLearning = false,
  learnOnSell = true, -- remember non-gray items you sell at a merchant
  keep = {
    resources = true,
    consumables = true, -- potions, food, scrolls, etc.
    highEnd = true,
    soulbound = true,
    byStats = {
      enabled = false,
      intellect = false,
      stamina = false,
      spirit = false,
      agility = false,
      strength = false,
      haste = false,
      crit = false,
      hit = false,
    },
  },
  minQualityKeep = 3, -- Rare+ kept when highEnd is on (0=poor..5=legendary)
  sellGray = true,
  sellWhite = true, -- common (white) items; resources never via this rule
  sellGreen = false, -- uncommon
  sellBlue = false, -- rare; High-end keep only applies when Blue is not set to sell
  sellEpic = false, -- purple
  sellArmor = { -- opt-in: sell Armor gear by type (keep rules still win)
    cloth = false,
    leather = false,
    mail = false,
    plate = false,
  },
  sellWeakerThanEquipped = false, -- opt-in: sell green-and-below gear with lower ilvl than equipped
  autoRepair = true, -- repair gear when opening a merchant that can repair
  repairPay = "personal", -- personal | guild | guild_first
  rememberedSell = {}, -- [itemId] = entry or legacy true
  lastDebugExport = nil,
  learningEvents = {}, -- local buffer; export later for Mission Control
}

local function DeepCopy(src)
  if type(src) ~= "table" then return src end
  local t = {}
  for k, v in pairs(src) do
    t[k] = DeepCopy(v)
  end
  return t
end

function MT:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(MT.CHAT_TAG .. " " .. tostring(msg or ""))
end

function MT:InitDB()
  if type(MacTechAutoSellerDB) ~= "table" then
    MacTechAutoSellerDB = DeepCopy(defaults)
  else
    for k, v in pairs(defaults) do
      if MacTechAutoSellerDB[k] == nil then
        MacTechAutoSellerDB[k] = DeepCopy(v)
      end
    end
    if type(MacTechAutoSellerDB.keep) ~= "table" then
      MacTechAutoSellerDB.keep = DeepCopy(defaults.keep)
    end
    if type(MacTechAutoSellerDB.keep.byStats) ~= "table" then
      MacTechAutoSellerDB.keep.byStats = DeepCopy(defaults.keep.byStats)
    end
    if MacTechAutoSellerDB.keep.consumables == nil then
      MacTechAutoSellerDB.keep.consumables = true
    end
    if type(MacTechAutoSellerDB.rememberedSell) ~= "table" then
      MacTechAutoSellerDB.rememberedSell = {}
    end
    if type(MacTechAutoSellerDB.sellArmor) ~= "table" then
      MacTechAutoSellerDB.sellArmor = DeepCopy(defaults.sellArmor)
    else
      for ak, av in pairs(defaults.sellArmor) do
        if MacTechAutoSellerDB.sellArmor[ak] == nil then
          MacTechAutoSellerDB.sellArmor[ak] = av
        end
      end
    end
  end
  self.db = MacTechAutoSellerDB
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "AutoSeller" then
    MacTechDebug:Register(MT.ADDON_NAME, MT.VERSION)
    MT:InitDB()
    MT:InstallSellHook()
  elseif event == "PLAYER_LOGIN" then
    MacTechDebug:SafeCall("CreateUI", function()
      MT:CreateUI()
    end)
    MT:Print("loaded. /autoseller for options.")
  elseif event == "MERCHANT_SHOW" then
    MacTechDebug:SafeCall("AutoRepairOnMerchant", function()
      if MT.TryAutoRepair then MT:TryAutoRepair() end
    end)
    if MT.db and MT.db.enabled then
      MacTechDebug:SafeCall("AutoSellOnMerchant", function()
        MT:SellEligible()
      end)
    end
  end
end)

SLASH_ADDMODSAS1 = "/autoseller"
SLASH_ADDMODSAS2 = "/ams"
SlashCmdList.ADDMODSAS = function(msg)
  msg = strtrim(string.lower(msg or ""))
  if msg == "sell" or msg == "junk" then
    MacTechDebug:SafeCall("ManualSell", function()
      MT:SellEligible()
    end)
    return
  end
  if msg == "scan" then
    MacTechDebug:SafeCall("Scan", function()
      MT:ScanInventory(true)
    end)
    return
  end
  if msg == "clear" or msg == "forget" then
    MacTechDebug:SafeCall("ClearRemembered", function()
      MT:ClearRememberedSell()
    end)
    return
  end
  if MT.ToggleUI then
    MT:ToggleUI()
  end
end
