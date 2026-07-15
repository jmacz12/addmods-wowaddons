local MT = MacTechAutoSeller

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
  if self.UpdateRememberedLabel then
    self:UpdateRememberedLabel()
  end
end
