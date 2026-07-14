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

local scanTip = CreateFrame("GameTooltip", "MacTechASScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

function MT:GetTooltipLines(bag, slot)
  scanTip:ClearLines()
  scanTip:SetBagItem(bag, slot)
  local lines = {}
  for i = 1, scanTip:NumLines() do
    local left = _G["MacTechASScanTipTextLeft" .. i]
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

function MT:ShouldKeepItem(bag, slot, link)
  local db = self.db
  if not link then return true end

  local name, _, quality, _, _, itemType, itemSubType, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(link)
  if not name then
    return true -- unknown: safe keep
  end

  if db.keep.soulbound then
    -- bindType 1=pickup, 2=equip (classic-era APIs vary; tooltip fallback below)
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
