local MT = MacTechAutoSeller

function MT:FormatCopper(copper)
  copper = math.max(0, tonumber(copper) or 0)
  local g = math.floor(copper / 10000)
  local s = math.floor((copper % 10000) / 100)
  local c = copper % 100
  if g > 0 then
    return string.format("%dg %ds %dc", g, s, c)
  end
  if s > 0 then
    return string.format("%ds %dc", s, c)
  end
  return string.format("%dc", c)
end

function MT:CanUseGuildRepair(cost)
  if not CanGuildBankRepair or not CanGuildBankRepair() then
    return false
  end
  if GetGuildBankWithdrawMoney then
    local withdraw = GetGuildBankWithdrawMoney()
    -- -1 = unlimited
    if withdraw ~= -1 and cost and withdraw < cost then
      return false
    end
  end
  return true
end

-- force=true: manual "Repair now" (ignores auto-repair toggle). Default: only when auto-repair is on.
function MT:TryAutoRepair(force)
  if not self.db then return end
  if not force and not self.db.autoRepair then return end
  if not MerchantFrame or not MerchantFrame:IsShown() then return end
  if not CanMerchantRepair or not CanMerchantRepair() then return end

  local cost, needsRepair = GetRepairAllCost()
  if not needsRepair or not cost or cost <= 0 then return end

  local mode = self.db.repairPay or "personal"
  local usedGuild = false
  local ok = false

  if mode == "guild" then
    if self:CanUseGuildRepair(cost) then
      RepairAllItems(1)
      usedGuild = true
      ok = true
    else
      self:Print("Auto-repair skipped: guild bank unavailable or not enough guild funds.")
      return
    end
  elseif mode == "guild_first" then
    if self:CanUseGuildRepair(cost) then
      RepairAllItems(1)
      usedGuild = true
      ok = true
    elseif GetMoney() >= cost then
      RepairAllItems()
      ok = true
    else
      self:Print("Auto-repair skipped: not enough guild or personal gold.")
      return
    end
  else
    -- personal (character gold / "inventory")
    if GetMoney() >= cost then
      RepairAllItems()
      ok = true
    else
      self:Print("Auto-repair skipped: not enough gold.")
      return
    end
  end

  if ok then
    self:Print(string.format(
      "Auto-repaired for %s (%s).",
      self:FormatCopper(cost),
      usedGuild and "guild bank" or "your gold"
    ))
  end
end

function MT:ScanInventory(printSummary)
  local sellable, kept = {}, {}
  local gray, remembered = 0, 0
  local keepReasons, sellReasons = {}, {}
  local greenKept, greenSell = 0, 0
  local statsHeld, weakerSell, armorSell = 0, 0, 0

  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local _, _, quality = GetItemInfo(link)
        quality = quality or 0
        local keepReason = self:GetKeepReason(bag, slot, link)
        local entry = { bag = bag, slot = slot, link = link, quality = quality }
        if keepReason then
          entry.reason = keepReason
          kept[#kept + 1] = entry
          keepReasons[keepReason] = (keepReasons[keepReason] or 0) + 1
          if keepReason == "keep-by-stats" then
            statsHeld = statsHeld + 1
          end
          if quality == 2 then
            greenKept = greenKept + 1
          end
        else
          if quality == 0 then
            gray = gray + 1
          end
          local sellReason = self:GetSellReason(bag, slot, link, quality)
          if sellReason then
            entry.reason = sellReason
            sellable[#sellable + 1] = entry
            sellReasons[sellReason] = (sellReasons[sellReason] or 0) + 1
            if sellReason == "remembered" then
              remembered = remembered + 1
            end
            if sellReason == "weaker" then
              weakerSell = weakerSell + 1
            end
            if sellReason == "armor" then
              armorSell = armorSell + 1
            end
            if quality == 2 then
              greenSell = greenSell + 1
            end
          elseif quality == 2 and self.db.sellGreen then
            keepReasons["unsellable"] = (keepReasons["unsellable"] or 0) + 1
            greenKept = greenKept + 1
          end
        end
      end
    end
  end

  if printSummary then
    self:Print(string.format(
      "scan: %d keep, %d sell (%d gray, %d remembered)",
      #kept, #sellable, gray, remembered
    ))
    if statsHeld > 0 or weakerSell > 0 or armorSell > 0
        or self.db.sellWeakerThanEquipped
        or (self.db.sellArmor and (self.db.sellArmor.cloth or self.db.sellArmor.leather
            or self.db.sellArmor.mail or self.db.sellArmor.plate)) then
      self:Print(string.format(
        "priority: keep-by-stats=%d held, armor=%d / weaker=%d will sell",
        statsHeld, armorSell, weakerSell
      ))
    end
    if self.db.sellGreen then
      self:Print(string.format("green: %d will sell, %d held back", greenSell, greenKept))
    end
    local holdParts = {}
    for reason, n in pairs(keepReasons) do
      holdParts[#holdParts + 1] = string.format("%s=%d", reason, n)
    end
    table.sort(holdParts)
    if #holdParts > 0 then
      self:Print("held by: " .. table.concat(holdParts, ", "))
    end
    local sellParts = {}
    for reason, n in pairs(sellReasons) do
      sellParts[#sellParts + 1] = string.format("%s=%d", reason, n)
    end
    table.sort(sellParts)
    if #sellParts > 0 then
      self:Print("sell via: " .. table.concat(sellParts, ", "))
    end
  end
  return sellable, kept
end

function MT:SellEligible()
  if not MerchantFrame or not MerchantFrame:IsShown() then
    self:Print("Open a merchant first.")
    return
  end

  local sellable = self:ScanInventory(false)
  local sold = 0
  local countBefore = self:CountRememberedSell()
  for _, item in ipairs(sellable) do
    local ok = pcall(UseContainerItem, item.bag, item.slot)
    if ok then
      sold = sold + 1
      -- UseContainerItem wrapper remembers from the pre-sell link
      self:RecordLearning("sold", { q = item.quality, id = self:GetItemId(item.link) })
    end
  end
  local newlyRemembered = math.max(0, self:CountRememberedSell() - countBefore)
  if newlyRemembered > 0 then
    self:Print(string.format(
      "Sold %d item(s). Added %d to remembered list (%d total).",
      sold, newlyRemembered, self:CountRememberedSell()
    ))
  else
    self:Print(string.format(
      "Sold %d item(s). Remembered list: %d (non-gray items not already covered by color rules get added).",
      sold, self:CountRememberedSell()
    ))
  end
  if self.RefreshRememberList then
    self:RefreshRememberList()
  end
end
