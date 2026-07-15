local MT = MacTechAutoSeller

-- Heuristic item classification for Ascension / classic-era tooltip scanning
local RESOURCE_SUBTYPES = {
  ["Herb"] = true,
  ["Metal & Stone"] = true,
  ["Cooking"] = true,
  ["Elemental"] = true,
  ["Cloth"] = true,
  ["Leather"] = true,
  ["Parts"] = true,
  ["Enchanting"] = true,
  ["Device"] = true,
  ["Other"] = true,
}

-- Lua patterns: literal "+" must be "%+" (a leading "+" crashes string.find and aborts auto-sell).
local STAT_PATTERNS = {
  intellect = { "%+(%d+) Intellect", "Intellect %+(%d+)" },
  stamina = { "%+(%d+) Stamina", "Stamina %+(%d+)" },
  spirit = { "%+(%d+) Spirit", "Spirit %+(%d+)" },
  agility = { "%+(%d+) Agility", "Agility %+(%d+)" },
  strength = { "%+(%d+) Strength", "Strength %+(%d+)" },
  haste = { "[Ii]ncreases? your haste", "Haste Rating" },
  crit = { "[Cc]ritical [Ss]trike", "Crit Rating" },
  hit = { "[Ii]mproves? hit", "Hit Rating" },
}

local scanTip = CreateFrame("GameTooltip", "AddModsASScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

function MT:GetItemId(link)
  if not link then return nil end
  return tonumber(link:match("item:(%d+)"))
end

function MT:GetTooltipLines(bag, slot)
  scanTip:ClearLines()
  scanTip:SetBagItem(bag, slot)
  local lines = {}
  for i = 1, scanTip:NumLines() do
    local left = _G["AddModsASScanTipTextLeft" .. i]
    if left then
      local text = left:GetText()
      if text and text ~= "" then
        lines[#lines + 1] = text
      end
    end
  end
  return lines
end

function MT:IsResourceItem(itemType, itemSubType, itemEquipLoc)
  if itemEquipLoc and itemEquipLoc ~= "" then
    return false
  end
  -- Trade Goods / Reagent only — consumables have their own keep toggle
  if itemType == "Trade Goods" or itemType == "Reagent" then
    if itemSubType and RESOURCE_SUBTYPES[itemSubType] then
      return true
    end
    return true
  end
  return false
end

function MT:IsConsumableItem(itemType, itemEquipLoc)
  if itemEquipLoc and itemEquipLoc ~= "" then
    return false
  end
  return itemType == "Consumable"
end

function MT:ItemHasKeptStat(bag, slot)
  local by = self.db.keep.byStats
  if not by or not by.enabled then
    return false
  end
  local lines = self:GetTooltipLines(bag, slot)
  local blob = table.concat(lines, "\n")
  for stat, patterns in pairs(STAT_PATTERNS) do
    if by[stat] then
      for _, pat in ipairs(patterns) do
        local ok, found = pcall(string.find, blob, pat)
        if ok and found then
          return true
        end
      end
    end
  end
  return false
end

function MT:IsRememberedSell(link)
  local id = self:GetItemId(link)
  if not id or type(self.db.rememberedSell) ~= "table" then
    return false
  end
  local v = self.db.rememberedSell[id]
  return v == true or type(v) == "table"
end

function MT:RememberSellItem(link, quality)
  if not self.db.learnOnSell then return end
  -- Skip qualities already covered by auto-sell toggles
  quality = quality or 0
  if quality < 1 then return end
  if quality == 1 and self.db.sellWhite then return end
  if quality == 2 and self.db.sellGreen then return end
  if quality == 3 and self.db.sellBlue then return end
  if quality == 4 and self.db.sellEpic then return end
  local id = self:GetItemId(link)
  if not id then return end
  if type(self.db.rememberedSell) ~= "table" then
    self.db.rememberedSell = {}
  end
  local name = GetItemInfo(link)
  local prev = self.db.rememberedSell[id]
  local wasNew = prev == nil
  if type(prev) == "table" and not name then
    name = prev.n
  end
  self.db.rememberedSell[id] = {
    t = time(),
    q = quality or (type(prev) == "table" and prev.q) or 0,
    n = name or ("Item #" .. id),
  }
  if wasNew then
    self:RecordLearning("remembered", { id = id, q = quality })
  end
  if self.RefreshRememberList then
    self:RefreshRememberList()
  end
end

function MT:ForgetSellItem(id)
  if type(self.db.rememberedSell) ~= "table" or not id then return end
  self.db.rememberedSell[id] = nil
  if self.RefreshRememberList then
    self:RefreshRememberList()
  end
end

function MT:GetRememberedEntries(filter)
  local list = {}
  if type(self.db.rememberedSell) ~= "table" then return list end
  filter = filter and string.lower(filter) or ""
  for id, v in pairs(self.db.rememberedSell) do
    local name, q, t
    if type(v) == "table" then
      name, q, t = v.n, v.q or 0, v.t or 0
    else
      name, q, t = nil, 0, 0
    end
    local infoName, _, infoQ = GetItemInfo(id)
    if infoName then
      name = infoName
      q = infoQ or q
    end
    if not name or name == "" then
      name = "Item #" .. id
    end
    if filter == "" or string.find(string.lower(name), filter, 1, true) then
      list[#list + 1] = { id = id, name = name, quality = q or 0, t = t or 0 }
    end
  end
  table.sort(list, function(a, b)
    if a.t ~= b.t then return a.t > b.t end
    return a.id > b.id
  end)
  return list
end

function MT:CountRememberedSell()
  local n = 0
  if type(self.db.rememberedSell) ~= "table" then return 0 end
  for _ in pairs(self.db.rememberedSell) do
    n = n + 1
  end
  return n
end

function MT:ClearRememberedSell()
  self.db.rememberedSell = {}
  self:Print("Cleared remembered sell list.")
  if self.RefreshRememberList then
    self:RefreshRememberList()
  end
end

function MT:QualitySellEnabled(quality)
  quality = quality or 0
  local db = self.db
  if not db then return false end
  if quality == 0 then return db.sellGray and true or false end
  if quality == 1 then return db.sellWhite and true or false end
  if quality == 2 then return db.sellGreen and true or false end
  if quality == 3 then return db.sellBlue and true or false end
  if quality == 4 then return db.sellEpic and true or false end
  return false
end

-- Equip locations → inventory slots (WotLK / Ascension)
local EQUIP_LOC_TO_SLOTS = {
  INVTYPE_HEAD = { 1 },
  INVTYPE_NECK = { 2 },
  INVTYPE_SHOULDER = { 3 },
  INVTYPE_BODY = { 4 },
  INVTYPE_CHEST = { 5 },
  INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 },
  INVTYPE_LEGS = { 7 },
  INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 },
  INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 },
  INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16, 17 },
  INVTYPE_2HWEAPON = { 16 },
  INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_HOLDABLE = { 17 },
  INVTYPE_SHIELD = { 17 },
  INVTYPE_RANGED = { 18 },
  INVTYPE_RANGEDRIGHT = { 18 },
  INVTYPE_THROWN = { 18 },
  INVTYPE_RELIC = { 18 },
}

local WEAKER_MAX_QUALITY = 2 -- green and below only

function MT:GetItemLevel(link)
  if not link then return nil end
  local _, _, _, ilvl = GetItemInfo(link)
  return tonumber(ilvl)
end

-- True when bag gear is strictly weaker (ilvl) than every filled equipped slot for that type.
-- Empty slot → not weaker (might be an upgrade). Dual slots (rings/trinkets/1H): must beat both.
function MT:IsWeakerThanEquipped(link)
  if not link or not self.db or not self.db.sellWeakerThanEquipped then
    return false
  end
  local name, _, quality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(link)
  if not name or not itemEquipLoc or itemEquipLoc == "" then
    return false
  end
  quality = quality or 0
  if quality > WEAKER_MAX_QUALITY then
    return false
  end
  itemLevel = tonumber(itemLevel)
  if not itemLevel then
    return false
  end
  local slots = EQUIP_LOC_TO_SLOTS[itemEquipLoc]
  if not slots then
    return false
  end

  local compared = 0
  for _, invSlot in ipairs(slots) do
    local eqLink = GetInventoryItemLink("player", invSlot)
    if not eqLink then
      -- Empty slot: bag piece could be an upgrade
      return false
    end
    local eqIlvl = self:GetItemLevel(eqLink)
    if not eqIlvl then
      return false
    end
    compared = compared + 1
    if itemLevel >= eqIlvl then
      return false
    end
  end
  return compared > 0
end

-- Hard/soft keeps only. Priority for keeps: resources → consumables → keep-by-stats → soulbound/high-end fallbacks.
-- Returns reason string if item is kept, otherwise nil.
function MT:GetKeepReason(bag, slot, link)
  local db = self.db
  if not link then return "no-link" end

  local name, _, quality, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
  if not name then
    return "unknown-item"
  end
  quality = quality or 0
  local colorSell = self:QualitySellEnabled(quality)

  -- 1) Hard safety: mats / consumables (above stats)
  if db.keep.resources and self:IsResourceItem(itemType, itemSubType, itemEquipLoc) then
    return "resources"
  end
  if db.keep.consumables and self:IsConsumableItem(itemType, itemEquipLoc) then
    return "consumables"
  end

  -- 2) Keep-by-stats (wins over color / weaker)
  if self:ItemHasKeptStat(bag, slot) then
    return "keep-by-stats"
  end

  -- Soft fallbacks when that color is NOT set to sell (do not override Color)
  if db.keep.soulbound and not colorSell then
    local lines = self:GetTooltipLines(bag, slot)
    for _, line in ipairs(lines) do
      if line:find("Soulbound", 1, true) or line:find("Binds when picked up", 1, true) then
        return "soulbound"
      end
    end
  end

  if db.keep.highEnd and quality >= (db.minQualityKeep or 3) and not colorSell then
    return "high-end"
  end

  return nil
end

function MT:ShouldKeepItem(bag, slot, link)
  return self:GetKeepReason(bag, slot, link) ~= nil
end

function MT:ItemIsVendorable(bag, slot, link)
  if not link then return false end
  -- 3.3+/Ascension: vendor price is the 11th GetItemInfo return (copper). 0 = cannot sell.
  local sellPrice = select(11, GetItemInfo(link))
  if type(sellPrice) == "number" then
    return sellPrice > 0
  end
  -- Tooltip fallback when the client omits price
  local lines = self:GetTooltipLines(bag, slot)
  for _, line in ipairs(lines) do
    local lower = string.lower(line)
    if lower:find("no sell price", 1, true)
        or lower:find("cannot be sold", 1, true)
        or lower:find("vendor will not buy", 1, true) then
      return false
    end
  end
  -- Unknown: allow quality/remember rules (don't block everything if API has no price field)
  return true
end

-- Sell reason after keeps: color → remembered → weaker. Returns reason or nil.
function MT:GetSellReason(bag, slot, link, quality)
  if self:ShouldKeepItem(bag, slot, link) then
    return nil
  end
  if not self:ItemIsVendorable(bag, slot, link) then
    return nil
  end
  quality = quality or select(3, GetItemInfo(link)) or 0

  -- 3) Color sells
  if self:QualitySellEnabled(quality) then
    if quality == 1 then
      -- Whites like junk, but never auto-sell resources (even if Keep resources is off)
      local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
      if self:IsResourceItem(itemType, itemSubType, itemEquipLoc) then
        return nil
      end
    end
    return "color"
  end

  -- 4) Remembered list
  if self:IsRememberedSell(link) then
    return "remembered"
  end

  -- 5) Weaker than equipped (ilvl; green and below; opt-in)
  if self:IsWeakerThanEquipped(link) then
    return "weaker"
  end

  return nil
end

function MT:ShouldSellItem(bag, slot, link, quality)
  return self:GetSellReason(bag, slot, link, quality) ~= nil
end

function MT:RecordLearning(eventType, payload)
  if not self.db.optInLearning then return end
  local events = self.db.learningEvents
  events[#events + 1] = {
    t = time(),
    e = eventType,
    p = payload,
  }
  while #events > 200 do
    table.remove(events, 1)
  end
end

function MT:InstallSellHook()
  if self._sellHookInstalled then return end
  self._sellHookInstalled = true
  hooksecurefunc("UseContainerItem", function(bag, slot)
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    if not MT.db or not MT.db.learnOnSell then return end
    local link = GetContainerItemLink(bag, slot)
    if not link then return end
    local _, _, quality = GetItemInfo(link)
    MacTechDebug:SafeCall("LearnOnSell", function()
      MT:RememberSellItem(link, quality or 0)
      if MT.RefreshRememberList then
        MT:RefreshRememberList()
      end
    end)
  end)
end
