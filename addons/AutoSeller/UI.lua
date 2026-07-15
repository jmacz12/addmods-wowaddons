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

local function SoftNote(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetWidth(420)
  fs:SetJustifyH("LEFT")
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
    panel.pageLabel:SetText(string.format("Page %d / %d · %d items", page, pages, total))
  end
  if panel.prevBtn then
    if page <= 1 then panel.prevBtn:Disable() else panel.prevBtn:Enable() end
  end
  if panel.nextBtn then
    if page >= pages then panel.nextBtn:Disable() else panel.nextBtn:Enable() end
  end
  if panel.countLabel then
    panel.countLabel:SetText(string.format("%d remembered", self:CountRememberedSell()))
  end
end

function MT:UpdateRememberedLabel()
  self:RefreshRememberList()
end

function MT:CreateUI()
  if self.optionsPanel then return end

  -- Main: remembered list
  local panel = CreateFrame("Frame", "AutoSellerOptionsPanel", UIParent)
  panel.name = "AutoSeller"
  panel.rememberPage = 1
  panel:Hide()

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("AutoSeller")

  SoftNote(panel, "Remembered sell list. Sell & keep rules are on the Rules page.", 16, -40)

  local y = -68

  MakeCheck(panel, "Remember items I sell (auto next time)", 16, y,
    function() return MT.db.learnOnSell end,
    function(v) MT.db.learnOnSell = v end)
  y = y - 26

  MakeCheck(panel, "Opt-in learning buffer (Mission Control export)", 16, y,
    function() return MT.db.optInLearning end,
    function(v) MT.db.optInLearning = v end)
  y = y - 30

  local countLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  countLabel:SetPoint("TOPLEFT", 16, y)
  countLabel:SetText("0 remembered")
  panel.countLabel = countLabel

  local searchLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  searchLabel:SetPoint("LEFT", countLabel, "RIGHT", 24, 0)
  searchLabel:SetText("Search")

  local searchBox = CreateFrame("EditBox", "AutoSellerRememberSearch", panel, "InputBoxTemplate")
  searchBox:SetSize(180, 20)
  searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
  searchBox:SetAutoFocus(false)
  searchBox:SetScript("OnTextChanged", function()
    panel.rememberPage = 1
    MT:RefreshRememberList()
  end)
  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  panel.searchBox = searchBox
  y = y - 28

  -- List header bar
  local listHead = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  listHead:SetPoint("TOPLEFT", 20, y)
  listHead:SetText("Item")
  local listHeadDel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  listHeadDel:SetPoint("TOPLEFT", 380, y)
  listHeadDel:SetText("")
  y = y - 18

  panel.rememberRows = {}
  for i = 1, PAGE_SIZE do
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(440, 20)
    row:SetPoint("TOPLEFT", 16, y - ((i - 1) * 22))

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", 4, 0)
    label:SetWidth(350)
    label:SetJustifyH("LEFT")
    row.label = label

    local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    del:SetSize(58, 20)
    del:SetPoint("RIGHT", 0, 0)
    del:SetText("Remove")
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
  y = y - (PAGE_SIZE * 22) - 10

  local prevBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  prevBtn:SetSize(72, 22)
  prevBtn:SetPoint("TOPLEFT", 16, y)
  prevBtn:SetText("Previous")
  prevBtn:SetScript("OnClick", function()
    panel.rememberPage = math.max(1, (panel.rememberPage or 1) - 1)
    MT:RefreshRememberList()
  end)
  panel.prevBtn = prevBtn

  local pageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  pageLabel:SetPoint("LEFT", prevBtn, "RIGHT", 12, 0)
  pageLabel:SetText("Page 1 / 1")
  panel.pageLabel = pageLabel

  local nextBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  nextBtn:SetSize(72, 22)
  nextBtn:SetPoint("LEFT", pageLabel, "RIGHT", 12, 0)
  nextBtn:SetText("Next")
  nextBtn:SetScript("OnClick", function()
    panel.rememberPage = (panel.rememberPage or 1) + 1
    MT:RefreshRememberList()
  end)
  panel.nextBtn = nextBtn

  local forgetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  forgetBtn:SetSize(90, 22)
  forgetBtn:SetPoint("LEFT", nextBtn, "RIGHT", 16, 0)
  forgetBtn:SetText("Clear all")
  forgetBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIClearRemembered", function() MT:ClearRememberedSell() end)
  end)

  y = y - 36
  SoftNote(panel, "Tip: open Rules (under AutoSeller) to choose what sells and what is kept.", 16, y)

  panel:SetScript("OnShow", function()
    MT:RefreshRememberList()
  end)

  InterfaceOptions_AddCategory(panel)
  self.optionsPanel = panel
  self.frame = panel

  -- Child: Sell & Keep (Rules)
  local rules = CreateFrame("Frame", "AutoSellerKeepOptionsPanel", UIParent)
  rules.name = "Rules"
  rules.parent = "AutoSeller"
  rules:Hide()

  local rulesTitle = rules:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  rulesTitle:SetPoint("TOPLEFT", 16, -16)
  rulesTitle:SetText("Rules")

  SoftNote(rules, "Choose what AutoSeller sells at merchants, and what it never sells.", 16, -40)

  local ky = -68

  -- Selling
  SectionHeader(rules, "Selling", 16, ky)
  ky = ky - 24

  MakeCheck(rules, "Enable auto-sell at merchants", 16, ky,
    function() return MT.db.enabled end,
    function(v) MT.db.enabled = v end)
  ky = ky - 28

  MakeCheck(rules, "Gray junk", 16, ky,
    function() return MT.db.sellGray end,
    function(v) MT.db.sellGray = v end)
  MakeCheck(rules, "White (not resources)", 160, ky,
    function() return MT.db.sellWhite end,
    function(v) MT.db.sellWhite = v end)
  ky = ky - 26

  MakeCheck(rules, "Green", 16, ky,
    function() return MT.db.sellGreen end,
    function(v) MT.db.sellGreen = v end)
  MakeCheck(rules, "Blue", 120, ky,
    function() return MT.db.sellBlue end,
    function(v) MT.db.sellBlue = v end)
  MakeCheck(rules, "Purple", 220, ky,
    function() return MT.db.sellEpic end,
    function(v) MT.db.sellEpic = v end)
  ky = ky - 22

  SoftNote(rules, "Colored sells still respect Keep rules below (high-end, soulbound, stats).", 20, ky)
  ky = ky - 26

  local sellBtn = CreateFrame("Button", nil, rules, "UIPanelButtonTemplate")
  sellBtn:SetSize(100, 24)
  sellBtn:SetPoint("TOPLEFT", 16, ky)
  sellBtn:SetText("Sell now")
  sellBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UISell", function() MT:SellEligible() end)
  end)

  local scanBtn = CreateFrame("Button", nil, rules, "UIPanelButtonTemplate")
  scanBtn:SetSize(80, 24)
  scanBtn:SetPoint("LEFT", sellBtn, "RIGHT", 8, 0)
  scanBtn:SetText("Scan bags")
  scanBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIScan", function() MT:ScanInventory(true) end)
  end)

  local debugBtn = CreateFrame("Button", nil, rules, "UIPanelButtonTemplate")
  debugBtn:SetSize(110, 24)
  debugBtn:SetPoint("LEFT", scanBtn, "RIGHT", 8, 0)
  debugBtn:SetText("Debug export")
  debugBtn:SetScript("OnClick", function()
    SlashCmdList.ADDMODSDEBUG("export")
  end)

  ky = ky - 40

  -- Keep
  SectionHeader(rules, "Keep", 16, ky)
  ky = ky - 24

  MakeCheck(rules, "Resources / trade goods", 16, ky,
    function() return MT.db.keep.resources end,
    function(v) MT.db.keep.resources = v end)
  MakeCheck(rules, "High-end (Rare+)", 220, ky,
    function() return MT.db.keep.highEnd end,
    function(v) MT.db.keep.highEnd = v end)
  ky = ky - 26

  MakeCheck(rules, "Soulbound", 16, ky,
    function() return MT.db.keep.soulbound end,
    function(v) MT.db.keep.soulbound = v end)
  ky = ky - 32

  SectionHeader(rules, "Keep by stats", 16, ky)
  ky = ky - 24

  local enableStatsCb = MakeCheck(rules, "Enable keep-by-stats", 16, ky,
    function() return MT.db.keep.byStats.enabled end,
    function(v)
      MT.db.keep.byStats.enabled = v
      MT:RefreshStatChecksEnabled()
    end)
  ky = ky - 26

  SoftNote(rules, "When enabled, gear with the selected stats is never sold.", 20, ky)
  ky = ky - 22

  local stats = { "intellect", "stamina", "spirit", "agility", "strength", "haste", "crit", "hit" }
  rules.statChecks = {}
  local col, rowN = 0, 0
  for _, stat in ipairs(stats) do
    local sx = 24 + (col * 140)
    local sy = ky - (rowN * 24)
    local cb, text = MakeCheck(rules, stat:gsub("^%l", string.upper), sx, sy,
      function() return MT.db.keep.byStats[stat] end,
      function(v) MT.db.keep.byStats[stat] = v end)
    rules.statChecks[#rules.statChecks + 1] = { cb = cb, text = text }
    col = col + 1
    if col > 2 then col = 0; rowN = rowN + 1 end
  end

  function MT:RefreshStatChecksEnabled()
    local on = MT.db.keep.byStats.enabled and true or false
    for _, row in ipairs(rules.statChecks or {}) do
      SetCheckInteractive(row.cb, row.text, on)
    end
  end

  rules:SetScript("OnShow", function()
    enableStatsCb:SetChecked(MT.db.keep.byStats.enabled)
    MT:RefreshStatChecksEnabled()
  end)

  InterfaceOptions_AddCategory(rules)
  self.keepOptionsPanel = rules
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
      GameTooltip:AddLine("Click: sell now", 0.8, 0.8, 0.8)
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
