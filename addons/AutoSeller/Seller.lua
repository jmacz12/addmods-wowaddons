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

function MT:TryAutoRepair()
  if not self.db or not self.db.autoRepair then return end
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
  local sellable, kept, gray, remembered = {}, {}, 0, 0
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local _, _, quality = GetItemInfo(link)
        quality = quality or 0
        local keep = self:ShouldKeepItem(bag, slot, link)
        local entry = { bag = bag, slot = slot, link = link, quality = quality }
        if keep then
          kept[#kept + 1] = entry
        else
          if quality == 0 then
            gray = gray + 1
          end
          if self:IsRememberedSell(link) then
            remembered = remembered + 1
          end
          if self:ShouldSellItem(bag, slot, link, quality) then
            sellable[#sellable + 1] = entry
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
  for _, item in ipairs(sellable) do
    local ok = pcall(UseContainerItem, item.bag, item.slot)
    if ok then
      sold = sold + 1
      self:RememberSellItem(item.link, item.quality)
      self:RecordLearning("sold", { q = item.quality, id = self:GetItemId(item.link) })
    end
  end
  self:Print(string.format("Sold %d item(s). Remembered list: %d.", sold, self:CountRememberedSell()))
  if self.RefreshRememberList then
    self:RefreshRememberList()
  end
end
