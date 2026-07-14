local MT = MacTechAutoSeller

function MT:ScanInventory(printSummary)
  local sellable, kept, gray = {}, {}, 0
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local _, _, quality = GetItemInfo(link)
        local keep = self:ShouldKeepItem(bag, slot, link)
        local entry = { bag = bag, slot = slot, link = link, quality = quality or 0 }
        if keep then
          kept[#kept + 1] = entry
        else
          if quality == 0 then
            gray = gray + 1
          end
          -- Only auto-sell greys unless user expands rules later
          if self.db.sellGray and quality == 0 then
            sellable[#sellable + 1] = entry
          end
        end
      end
    end
  end
  if printSummary then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "|cff55ccffMacTech AutoSeller|r scan: %d keep, %d sell candidates (%d gray)",
      #kept, #sellable, gray
    ))
  end
  return sellable, kept
end

function MT:SellEligible()
  if not MerchantFrame or not MerchantFrame:IsShown() then
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ccffMacTech AutoSeller|r Open a merchant first.")
    return
  end

  local sellable = self:ScanInventory(false)
  local sold = 0
  for _, item in ipairs(sellable) do
    local ok = pcall(UseContainerItem, item.bag, item.slot)
    if ok then
      sold = sold + 1
      self:RecordLearning("sold", { q = item.quality })
    end
  end
  DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff55ccffMacTech AutoSeller|r Sold %d item(s).", sold))
end
