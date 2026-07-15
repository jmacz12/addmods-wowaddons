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

local STAT_PATTERNS = {
  intellect = { "+(%d+) Intellect", "Intellect %+(%d+)" },
  stamina = { "+(%d+) Stamina", "Stamina %+(%d+)" },
  spirit = { "+(%d+) Spirit", "Spirit %+(%d+)" },
  agility = { "+(%d+) Agility", "Agility %+(%d+)" },
  strength = { "+(%d+) Strength", "Strength %+(%d+)" },
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
  if itemType == "Trade Goods" or itemType == "Reagent" or itemType == "Consumable" then
    if itemSubType and RESOURCE_SUBTYPES[itemSubType] then
      return true
    end
    if itemType == "Trade Goods" or itemType == "Reagent" then
      return true
    end
  end
  return false
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
        if blob:find(pat) then
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

function MT:ShouldKeepItem(bag, slot, link)
  local db = self.db
  if not link then return true end

  local name, _, quality, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
  if not name then
    return true -- unknown: safe keep
  end

  if db.keep.soulbound then
    local lines = self:GetTooltipLines(bag, slot)
    for _, line in ipairs(lines) do
      if line:find("Soulbound") or line:find("Binds when picked up") then
        return true
      end
    end
  end

  if db.keep.highEnd and quality and quality >= (db.minQualityKeep or 3) then
    return true
  end

  if db.keep.resources and self:IsResourceItem(itemType, itemSubType, itemEquipLoc) then
    return true
  end

  if self:ItemHasKeptStat(bag, slot) then
    return true
  end

  return false
end

function MT:ShouldSellItem(bag, slot, link, quality)
  if self:ShouldKeepItem(bag, slot, link) then
    return false
  end
  quality = quality or 0
  if self.db.sellGray and quality == 0 then
    return true
  end
  if self.db.sellWhite and quality == 1 then
    -- Whites like junk, but never auto-sell resources (even if Keep resources is off)
    local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
    if self:IsResourceItem(itemType, itemSubType, itemEquipLoc) then
      return false
    end
    return true
  end
  if self.db.sellGreen and quality == 2 then
    return true
  end
  if self.db.sellBlue and quality == 3 then
    return true
  end
  if self.db.sellEpic and quality == 4 then
    return true
  end
  if self:IsRememberedSell(link) then
    return true
  end
  return false
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
