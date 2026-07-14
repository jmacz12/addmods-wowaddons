MacTechAutoSeller = MacTechAutoSeller or {}
local MT = MacTechAutoSeller

MT.ADDON_NAME = "MacTech AutoSeller"
MT.VERSION = "0.1.0"

local defaults = {
  enabled = true,
  optInLearning = false,
  keep = {
    resources = true,
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
  lastDebugExport = nil,
  learningEvents = {}, -- local buffer; export later for control.mactech
}

local function DeepCopy(src)
  if type(src) ~= "table" then return src end
  local t = {}
  for k, v in pairs(src) do
    t[k] = DeepCopy(v)
  end
  return t
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
  end
  self.db = MacTechAutoSellerDB
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "MacTech_AutoSeller" then
    MacTechDebug:Register(MT.ADDON_NAME, MT.VERSION)
    MT:InitDB()
  elseif event == "PLAYER_LOGIN" then
    MacTechDebug:SafeCall("CreateUI", function()
      MT:CreateUI()
    end)
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ccffMacTech AutoSeller|r loaded. /mtas for options")
  elseif event == "MERCHANT_SHOW" then
    if MT.db and MT.db.enabled then
      MacTechDebug:SafeCall("AutoSellOnMerchant", function()
        MT:SellEligible()
      end)
    end
  end
end)

SLASH_MACTECHAS1 = "/mtas"
SLASH_MACTECHAS2 = "/autoseller"
SlashCmdList.MACTECHAS = function(msg)
  msg = strtrim(string.lower(msg or ""))
  if msg == "sell" then
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
  if MT.ToggleUI then
    MT:ToggleUI()
  end
end
