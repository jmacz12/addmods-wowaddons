local MT = MacTechAutoSeller

local PAGE_SIZE = 8
local QUALITY_HEX = {
  [0] = "9d9d9d",
  [1] = "ffffff",
  [2] = "1eff00",
  [3] = "0070dd",
  [4] = "a335ee",
  [5] = "ff8000",
  [6] = "e6cc80",
  [7] = "e6cc80",
}

local function SectionHeader(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(text)
  return fs
end

local function MakeCheck(parent, label, x, y, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetChecked(get())
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
  end)
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  text:SetText(label)
  return cb, text
end

local function SetCheckInteractive(cb, text, enabled)
  if enabled then
    cb:Enable()
    if text then text:SetTextColor(1, 1, 1) end
  else
    cb:Disable()
    if text then text:SetTextColor(0.5, 0.5, 0.5) end
  end
end

local function QualityColorText(name, quality)
  local hex = QUALITY_HEX[quality or 0] or "ffffff"
  return "|cff" .. hex .. (name or "?") .. "|r"
end

function MT:RefreshRememberList()
  local panel = self.optionsPanel
  if not panel or not panel.rememberRows then return end

  local filter = ""
  if panel.searchBox then
    filter = panel.searchBox:GetText() or ""
  end
  local entries = self:GetRememberedEntries(filter)
  local total = #entries
  local pages = math.max(1, math.ceil(total / PAGE_SIZE))
  panel.rememberPage = math.max(1, math.min(panel.rememberPage or 1, pages))
  local page = panel.rememberPage
  local startIdx = (page - 1) * PAGE_SIZE + 1

  for i, row in ipairs(panel.rememberRows) do
    local entry = entries[startIdx + i - 1]
    if entry then
      row:Show()
      row.label:SetText(QualityColorText(entry.name, entry.quality))
      row.itemId = entry.id
    else
      row:Hide()
      row.itemId = nil
    end
  end

  if panel.pageLabel then
    panel.pageLabel:SetText(string.format("Page %d / %d  (%d items)", page, pages, total))
  end
  if panel.prevBtn then
    if page <= 1 then panel.prevBtn:Disable() else panel.prevBtn:Enable() end
  end
  if panel.nextBtn then
    if page >= pages then panel.nextBtn:Disable() else panel.nextBtn:Enable() end
  end
  if panel.countLabel then
    panel.countLabel:SetText(string.format("Remembered: %d", self:CountRememberedSell()))
  end
end

function MT:UpdateRememberedLabel()
  self:RefreshRememberList()
end

function MT:CreateUI()
  if self.optionsPanel then return end

  local panel = CreateFrame("Frame", "AutoSellerOptionsPanel", UIParent)
  panel.name = "AutoSeller"
  panel.rememberPage = 1
  panel:Hide()

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("AutoSeller")

  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  sub:SetText("Sell junk, remember dumps, keep gear by rules. See also: Keep rules.")

  local y = -56

  -- Selling
  SectionHeader(panel, "Selling", 16, y)
  y = y - 22
  MakeCheck(panel, "Enable auto-sell at merchants", 20, y,
    function() return MT.db.enabled end,
    function(v) MT.db.enabled = v end)
  y = y - 26
  MakeCheck(panel, "Sell gray junk", 20, y,
    function() return MT.db.sellGray end,
    function(v) MT.db.sellGray = v end)
  MakeCheck(panel, "Sell white (not resources)", 220, y,
    function() return MT.db.sellWhite end,
    function(v) MT.db.sellWhite = v end)
  y = y - 26
  MakeCheck(panel, "Sell green", 20, y,
    function() return MT.db.sellGreen end,
    function(v) MT.db.sellGreen = v end)
  MakeCheck(panel, "Sell blue", 140, y,
    function() return MT.db.sellBlue end,
    function(v) MT.db.sellBlue = v end)
  MakeCheck(panel, "Sell purple", 260, y,
    function() return MT.db.sellEpic end,
    function(v) MT.db.sellEpic = v end)
  y = y - 18
  local tip = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  tip:SetPoint("TOPLEFT", 24, y)
  tip:SetText("Green/blue/purple still respect Keep rules (high-end, soulbound, stats).")
  y = y - 28

  local sellBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  sellBtn:SetSize(100, 22)
  sellBtn:SetPoint("TOPLEFT", 24, y)
  sellBtn:SetText("Sell junk")
  sellBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UISell", function() MT:SellEligible() end)
  end)

  local scanBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  scanBtn:SetSize(70, 22)
  scanBtn:SetPoint("LEFT", sellBtn, "RIGHT", 6, 0)
  scanBtn:SetText("Scan")
  scanBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIScan", function() MT:ScanInventory(true) end)
  end)

  local debugBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  debugBtn:SetSize(100, 22)
  debugBtn:SetPoint("LEFT", scanBtn, "RIGHT", 6, 0)
  debugBtn:SetText("Debug export")
  debugBtn:SetScript("OnClick", function()
    SlashCmdList.ADDMODSDEBUG("export")
  end)

  y = y - 36

  -- Remember
  SectionHeader(panel, "Remember", 16, y)
  y = y - 22
  MakeCheck(panel, "Remember items I sell (auto next time)", 20, y,
    function() return MT.db.learnOnSell end,
    function(v) MT.db.learnOnSell = v end)
  y = y - 24

  MakeCheck(panel, "Opt-in learning buffer (Mission Control export)", 20, y,
    function() return MT.db.optInLearning end,
    function(v) MT.db.optInLearning = v end)
  y = y - 26

  local countLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  countLabel:SetPoint("TOPLEFT", 24, y)
  countLabel:SetText("Remembered: 0")
  panel.countLabel = countLabel
  y = y - 22

  local searchLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  searchLabel:SetPoint("TOPLEFT", 24, y)
  searchLabel:SetText("Search:")

  local searchBox = CreateFrame("EditBox", "AutoSellerRememberSearch", panel, "InputBoxTemplate")
  searchBox:SetSize(200, 20)
  searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
  searchBox:SetAutoFocus(false)
  searchBox:SetScript("OnTextChanged", function()
    panel.rememberPage = 1
    MT:RefreshRememberList()
  end)
  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  panel.searchBox = searchBox
  y = y - 26

  panel.rememberRows = {}
  for i = 1, PAGE_SIZE do
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(420, 18)
    row:SetPoint("TOPLEFT", 24, y - ((i - 1) * 20))

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(340)
    label:SetJustifyH("LEFT")
    row.label = label

    local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    del:SetSize(54, 18)
    del:SetPoint("LEFT", label, "RIGHT", 6, 0)
    del:SetText("Delete")
    del:SetScript("OnClick", function()
      if row.itemId then
        MacTechDebug:SafeCall("UIForgetOne", function()
          MT:ForgetSellItem(row.itemId)
        end)
      end
    end)

    row:Hide()
    panel.rememberRows[i] = row
  end
  y = y - (PAGE_SIZE * 20) - 8

  local prevBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  prevBtn:SetSize(70, 20)
  prevBtn:SetPoint("TOPLEFT", 24, y)
  prevBtn:SetText("< Prev")
  prevBtn:SetScript("OnClick", function()
    panel.rememberPage = math.max(1, (panel.rememberPage or 1) - 1)
    MT:RefreshRememberList()
  end)
  panel.prevBtn = prevBtn

  local pageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  pageLabel:SetPoint("LEFT", prevBtn, "RIGHT", 10, 0)
  pageLabel:SetText("Page 1 / 1")
  panel.pageLabel = pageLabel

  local nextBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  nextBtn:SetSize(70, 20)
  nextBtn:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)
  nextBtn:SetText("Next >")
  nextBtn:SetScript("OnClick", function()
    panel.rememberPage = (panel.rememberPage or 1) + 1
    MT:RefreshRememberList()
  end)
  panel.nextBtn = nextBtn

  local forgetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  forgetBtn:SetSize(90, 20)
  forgetBtn:SetPoint("LEFT", nextBtn, "RIGHT", 12, 0)
  forgetBtn:SetText("Forget all")
  forgetBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIClearRemembered", function() MT:ClearRememberedSell() end)
  end)

  panel:SetScript("OnShow", function()
    MT:RefreshRememberList()
  end)

  InterfaceOptions_AddCategory(panel)
  self.optionsPanel = panel
  self.frame = panel

  -- Keep rules (child category — Interface AddOns list under AutoSeller)
  local keep = CreateFrame("Frame", "AutoSellerKeepOptionsPanel", UIParent)
  keep.name = "Keep rules"
  keep.parent = "AutoSeller"
  keep:Hide()

  local keepTitle = keep:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  keepTitle:SetPoint("TOPLEFT", 16, -16)
  keepTitle:SetText("Keep rules")

  local ky = -48
  MakeCheck(keep, "Keep resources / trade goods", 20, ky,
    function() return MT.db.keep.resources end,
    function(v) MT.db.keep.resources = v end)
  ky = ky - 26
  MakeCheck(keep, "Keep high-end (Rare+)", 20, ky,
    function() return MT.db.keep.highEnd end,
    function(v) MT.db.keep.highEnd = v end)
  ky = ky - 26
  MakeCheck(keep, "Keep soulbound", 20, ky,
    function() return MT.db.keep.soulbound end,
    function(v) MT.db.keep.soulbound = v end)
  ky = ky - 32

  local statsTitle = keep:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  statsTitle:SetPoint("TOPLEFT", 20, ky)
  statsTitle:SetText("Keep gear with these stats:")
  ky = ky - 24

  local enableStatsCb = MakeCheck(keep, "Enable keep-by-stats", 20, ky,
    function() return MT.db.keep.byStats.enabled end,
    function(v)
      MT.db.keep.byStats.enabled = v
      MT:RefreshStatChecksEnabled()
    end)
  ky = ky - 26

  local stats = { "intellect", "stamina", "spirit", "agility", "strength", "haste", "crit", "hit" }
  keep.statChecks = {}
  local col, rowN = 0, 0
  for _, stat in ipairs(stats) do
    local sx = 36 + (col * 150)
    local sy = ky - (rowN * 24)
    local cb, text = MakeCheck(keep, stat:gsub("^%l", string.upper), sx, sy,
      function() return MT.db.keep.byStats[stat] end,
      function(v) MT.db.keep.byStats[stat] = v end)
    keep.statChecks[#keep.statChecks + 1] = { cb = cb, text = text }
    col = col + 1
    if col > 1 then col = 0; rowN = rowN + 1 end
  end

  function MT:RefreshStatChecksEnabled()
    local on = MT.db.keep.byStats.enabled and true or false
    for _, row in ipairs(keep.statChecks or {}) do
      SetCheckInteractive(row.cb, row.text, on)
    end
  end

  keep:SetScript("OnShow", function()
    enableStatsCb:SetChecked(MT.db.keep.byStats.enabled)
    MT:RefreshStatChecksEnabled()
  end)

  InterfaceOptions_AddCategory(keep)
  self.keepOptionsPanel = keep
  self:RefreshStatChecksEnabled()

  self:CreateBagButton()
  self:RefreshRememberList()
end

function MT:CreateBagButton()
  if self.bagButton then return end
  local parent = MainMenuBarBackpackButton
  if not parent then return end

  local btn = CreateFrame("Button", "AutoSellerBagButton", parent)
  btn:SetSize(28, 28)
  btn:SetPoint("RIGHT", parent, "LEFT", -6, 0)
  btn:SetFrameStrata(parent:GetFrameStrata())
  btn:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)

  local tex = "Interface\\Icons\\INV_Misc_Coin_01"
  btn:SetNormalTexture(tex)
  btn:SetPushedTexture(tex)
  btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  local nt = btn:GetNormalTexture()
  if nt then nt:SetTexCoord(0.07, 0.93, 0.07, 0.93) end

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AutoSeller")
    if MerchantFrame and MerchantFrame:IsShown() then
      GameTooltip:AddLine("Click: sell junk", 0.8, 0.8, 0.8)
    else
      GameTooltip:AddLine("Click: open settings", 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  btn:SetScript("OnClick", function()
    if MerchantFrame and MerchantFrame:IsShown() then
      MacTechDebug:SafeCall("BagSell", function() MT:SellEligible() end)
    else
      MT:OpenSettings()
    end
  end)

  self.bagButton = btn
end

function MT:OpenSettings()
  if not self.optionsPanel then self:CreateUI() end
  -- Open Interface Options to AutoSeller (call twice — known Blizzard quirk)
  InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
  InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
end

function MT:ToggleUI()
  if not self.optionsPanel then self:CreateUI() end
  if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown()
      and InterfaceOptionsFramePanelContainer
      and InterfaceOptionsFramePanelContainer.displayedPanel == self.optionsPanel then
    HideUIPanel(InterfaceOptionsFrame)
  else
    self:OpenSettings()
  end
end
