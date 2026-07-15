local MT = MacTechAutoSeller

local PAGE_SIZE = 8
local ROW = 26 -- consistent vertical rhythm for Rules checks
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

local COL1 = 20
local COL2 = 200
local COL3 = 360
local STAT_COL_W = 170

StaticPopupDialogs["AUTOSELLER_CLEAR_REMEMBERED"] = {
  text = "Clear the entire remembered sell list?",
  button1 = YES,
  button2 = NO,
  OnAccept = function()
    MacTechDebug:SafeCall("UIClearRemembered", function()
      MT:ClearRememberedSell()
    end)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["AUTOSELLER_SELL_NOW"] = {
  text = "Sell all eligible bag items to this merchant?",
  button1 = YES,
  button2 = NO,
  OnAccept = function()
    MacTechDebug:SafeCall("UISell", function()
      MT:SellEligible()
    end)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function SectionHeader(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(text)
  return fs
end

local function SoftNote(parent, text, x, y, width)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetWidth(width or 420)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

local function AttachTooltip(frame, title, body)
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 0.82, 0)
    if body then
      GameTooltip:AddLine(body, 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function MakeCheck(parent, label, x, y, get, set, registry)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetChecked(get())
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
  end)
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  text:SetText(label)
  if registry then
    registry[#registry + 1] = { cb = cb, get = get }
  end
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

-- Scrollable content host for Interface Options child panels (WotLK-safe)
local function MakeScrollBody(panel, topInset)
  local scroll = CreateFrame("ScrollFrame", panel:GetName() .. "Scroll", panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, topInset or -52)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)

  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(520)
  child:SetHeight(200)
  scroll:SetScrollChild(child)

  function child:SetContentHeight(h)
    self:SetHeight(math.max(200, h or 200))
  end

  return child, scroll
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
  panel.name = "AutoSeller & Repair"
  panel.rememberPage = 1
  panel:Hide()

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("AutoSeller & Repair")

  SoftNote(panel, "Items you sell that aren't already covered by color rules stay on this auto-sell list.", 16, -40)

  local body = MakeScrollBody(panel, -58)
  local y = -8

  MakeCheck(body, "Remember items I sell (auto next time)", COL1, y,
    function() return MT.db.learnOnSell end,
    function(v) MT.db.learnOnSell = v end)
  y = y - 30

  local countLabel = body:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  countLabel:SetPoint("TOPLEFT", COL1, y)
  countLabel:SetText("0 remembered")
  panel.countLabel = countLabel

  local searchLabel = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  searchLabel:SetPoint("LEFT", countLabel, "RIGHT", 24, 0)
  searchLabel:SetText("Search")

  local searchBox = CreateFrame("EditBox", "AutoSellerRememberSearch", body, "InputBoxTemplate")
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

  local listHead = body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  listHead:SetPoint("TOPLEFT", COL1 + 4, y)
  listHead:SetText("Item")
  y = y - 18

  panel.rememberRows = {}
  for i = 1, PAGE_SIZE do
    local row = CreateFrame("Frame", nil, body)
    row:SetSize(440, 20)
    row:SetPoint("TOPLEFT", COL1, y - ((i - 1) * 22))

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

  local prevBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
  prevBtn:SetSize(72, 22)
  prevBtn:SetPoint("TOPLEFT", COL1, y)
  prevBtn:SetText("Previous")
  prevBtn:SetScript("OnClick", function()
    panel.rememberPage = math.max(1, (panel.rememberPage or 1) - 1)
    MT:RefreshRememberList()
  end)
  panel.prevBtn = prevBtn

  local pageLabel = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  pageLabel:SetPoint("LEFT", prevBtn, "RIGHT", 12, 0)
  pageLabel:SetText("Page 1 / 1")
  panel.pageLabel = pageLabel

  local nextBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
  nextBtn:SetSize(72, 22)
  nextBtn:SetPoint("LEFT", pageLabel, "RIGHT", 12, 0)
  nextBtn:SetText("Next")
  nextBtn:SetScript("OnClick", function()
    panel.rememberPage = (panel.rememberPage or 1) + 1
    MT:RefreshRememberList()
  end)
  panel.nextBtn = nextBtn

  local forgetBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
  forgetBtn:SetSize(90, 22)
  forgetBtn:SetPoint("LEFT", nextBtn, "RIGHT", 16, 0)
  forgetBtn:SetText("Clear all")
  forgetBtn:SetScript("OnClick", function()
    StaticPopup_Show("AUTOSELLER_CLEAR_REMEMBERED")
  end)

  y = y - 36
  body:SetContentHeight(-y + 24)

  panel:SetScript("OnShow", function()
    MT:RefreshRememberList()
  end)

  InterfaceOptions_AddCategory(panel)
  self.optionsPanel = panel
  self.frame = panel

  -- Child: Rules (category parent — options live on Keep / Selling / Repair)
  local rules = CreateFrame("Frame", "AutoSellerKeepOptionsPanel", UIParent)
  rules.name = "Rules"
  rules.parent = "AutoSeller & Repair"
  rules:Hide()

  local rulesTitle = rules:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  rulesTitle:SetPoint("TOPLEFT", 16, -16)
  rulesTitle:SetText("Rules")

  SoftNote(rules, "Open the sub-pages on the left: Keep, Selling, and Repair.", 16, -40, 460)
  SoftNote(rules, "Priority: resources/consumables → keep-by-stats → color → armor type → remembered → weaker (ilvl).", 16, -68, 460)

  InterfaceOptions_AddCategory(rules)
  self.keepOptionsPanel = rules

  local function AddRulesChild(frameName, titleText, blurb)
    local p = CreateFrame("Frame", frameName, UIParent)
    p.name = titleText
    p.parent = "Rules"
    p:Hide()

    local t = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText(titleText)

    SoftNote(p, blurb, 16, -40, 460)

    local body = MakeScrollBody(p, -58)
    local sync = {}
    p._sync = sync
    p._body = body
    return p, body, sync
  end

  -- Keep
  local keepPanel, kb, keepSync = AddRulesChild(
    "AutoSellerRulesKeepPanel",
    "Keep",
    "Safety filters — these win over sell rules."
  )

  local ky = -8
  SectionHeader(kb, "Keep by stats", COL1, ky)
  ky = ky - 22

  MakeCheck(kb, "Enable keep-by-stats", COL1, ky,
    function() return MT.db.keep.byStats.enabled end,
    function(v)
      MT.db.keep.byStats.enabled = v
      MT:RefreshStatChecksEnabled()
    end, keepSync)
  ky = ky - 22
  SoftNote(kb, "When enabled, gear with checked stats is never sold — even if Green/Blue or armor type is on.", COL1 + 4, ky, 460)
  ky = ky - 24

  local stats = { "Intellect", "Stamina", "Spirit", "Agility", "Strength", "Haste", "Crit", "Hit" }
  local statKeys = { "intellect", "stamina", "spirit", "agility", "strength", "haste", "crit", "hit" }
  kb.statChecks = {}
  local gridTop = ky
  for i, key in ipairs(statKeys) do
    local col = ((i - 1) % 2)
    local rowN = math.floor((i - 1) / 2)
    local sx = COL1 + 8 + (col * STAT_COL_W)
    local sy = gridTop - (rowN * ROW)
    local cb, text = MakeCheck(kb, stats[i], sx, sy,
      function() return MT.db.keep.byStats[key] end,
      function(v) MT.db.keep.byStats[key] = v end, keepSync)
    kb.statChecks[#kb.statChecks + 1] = { cb = cb, text = text }
  end
  ky = gridTop - (math.ceil(#statKeys / 2) * ROW) - 14

  SectionHeader(kb, "Always keep", COL1, ky)
  ky = ky - 22

  MakeCheck(kb, "Resources / trade goods", COL1, ky,
    function() return MT.db.keep.resources end,
    function(v) MT.db.keep.resources = v end, keepSync)
  MakeCheck(kb, "High-end (Rare+)", COL2, ky,
    function() return MT.db.keep.highEnd end,
    function(v) MT.db.keep.highEnd = v end, keepSync)
  ky = ky - ROW

  MakeCheck(kb, "Consumables (potions, food, scrolls...)", COL1, ky,
    function() return MT.db.keep.consumables end,
    function(v) MT.db.keep.consumables = v end, keepSync)
  ky = ky - ROW

  local soulCb = MakeCheck(kb, "Soulbound (if color not selling)", COL1, ky,
    function() return MT.db.keep.soulbound end,
    function(v) MT.db.keep.soulbound = v end, keepSync)
  AttachTooltip(soulCb, "Soulbound", "Keeps soulbound items only when that quality color is not set to sell.")
  ky = ky - 36
  kb:SetContentHeight(-ky + 24)

  function MT:RefreshStatChecksEnabled()
    local on = MT.db.keep.byStats.enabled and true or false
    for _, row in ipairs(kb.statChecks or {}) do
      SetCheckInteractive(row.cb, row.text, on)
    end
  end

  -- Selling
  local sellPanel, sb, sellSync = AddRulesChild(
    "AutoSellerRulesSellPanel",
    "Selling",
    "What to auto-sell at merchants. Keep rules always win."
  )

  local sy = -8
  SectionHeader(sb, "Auto-sell", COL1, sy)
  sy = sy - 22

  MakeCheck(sb, "Enable auto-sell at merchants", COL1, sy,
    function() return MT.db.enabled end,
    function(v) MT.db.enabled = v end, sellSync)
  sy = sy - 28

  SectionHeader(sb, "By quality", COL1, sy)
  sy = sy - 22

  MakeCheck(sb, "Gray junk", COL1, sy,
    function() return MT.db.sellGray end,
    function(v) MT.db.sellGray = v end, sellSync)
  MakeCheck(sb, "White (not resources)", COL2, sy,
    function() return MT.db.sellWhite end,
    function(v) MT.db.sellWhite = v end, sellSync)
  sy = sy - ROW

  MakeCheck(sb, "Green", COL1, sy,
    function() return MT.db.sellGreen end,
    function(v) MT.db.sellGreen = v end, sellSync)
  MakeCheck(sb, "Blue", COL2, sy,
    function() return MT.db.sellBlue end,
    function(v) MT.db.sellBlue = v end, sellSync)
  MakeCheck(sb, "Purple", COL3, sy,
    function() return MT.db.sellEpic end,
    function(v) MT.db.sellEpic = v end, sellSync)
  sy = sy - 28

  SectionHeader(sb, "By armor type", COL1, sy)
  sy = sy - 22
  SoftNote(sb, "Armor gear only (not cloth/leather crafting mats). Keep rules still apply.", COL1 + 4, sy, 460)
  sy = sy - 22

  MakeCheck(sb, "Cloth", COL1, sy,
    function() return MT.db.sellArmor.cloth end,
    function(v) MT.db.sellArmor.cloth = v end, sellSync)
  MakeCheck(sb, "Leather", COL2, sy,
    function() return MT.db.sellArmor.leather end,
    function(v) MT.db.sellArmor.leather = v end, sellSync)
  sy = sy - ROW

  MakeCheck(sb, "Mail", COL1, sy,
    function() return MT.db.sellArmor.mail end,
    function(v) MT.db.sellArmor.mail = v end, sellSync)
  MakeCheck(sb, "Plate", COL2, sy,
    function() return MT.db.sellArmor.plate end,
    function(v) MT.db.sellArmor.plate = v end, sellSync)
  sy = sy - 28

  SectionHeader(sb, "Other", COL1, sy)
  sy = sy - 22

  MakeCheck(sb, "Sell weaker than equipped (ilvl, green and below)", COL1, sy,
    function() return MT.db.sellWeakerThanEquipped end,
    function(v) MT.db.sellWeakerThanEquipped = v end, sellSync)
  sy = sy - 22
  SoftNote(sb, "Weaker never sells blue/purple. Color and armor rules run first.", COL1 + 4, sy, 460)
  sy = sy - 34

  local sellBtn = CreateFrame("Button", nil, sb, "UIPanelButtonTemplate")
  sellBtn:SetSize(100, 24)
  sellBtn:SetPoint("TOPLEFT", COL1, sy)
  sellBtn:SetText("Sell now")
  sellBtn:SetScript("OnClick", function()
    if not MerchantFrame or not MerchantFrame:IsShown() then
      MacTechDebug:SafeCall("UISell", function() MT:SellEligible() end)
      return
    end
    StaticPopup_Show("AUTOSELLER_SELL_NOW")
  end)

  local scanBtn = CreateFrame("Button", nil, sb, "UIPanelButtonTemplate")
  scanBtn:SetSize(100, 24)
  scanBtn:SetPoint("LEFT", sellBtn, "RIGHT", 8, 0)
  scanBtn:SetText("Scan bags")
  scanBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIScan", function() MT:ScanInventory(true) end)
  end)
  sy = sy - 36
  sb:SetContentHeight(-sy + 24)

  -- Repair
  local repairPanel, rb, repairSync = AddRulesChild(
    "AutoSellerRulesRepairPanel",
    "Repair",
    "Auto-repair when you talk to a repair vendor."
  )

  local ry = -8
  SectionHeader(rb, "Auto-repair", COL1, ry)
  ry = ry - 22

  MakeCheck(rb, "Repair gear when talking to a vendor", COL1, ry,
    function() return MT.db.autoRepair end,
    function(v)
      MT.db.autoRepair = v
      MT:RefreshRepairPayEnabled()
    end, repairSync)
  ry = ry - 22
  SoftNote(rb, "Runs at repair vendors. Chat shows cost and who paid.", COL1 + 4, ry)
  ry = ry - 22

  local payLabel = rb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  payLabel:SetPoint("TOPLEFT", COL1 + 4, ry)
  payLabel:SetText("Pay with:")
  ry = ry - 22

  local payChecks = {}
  local function SetRepairPay(mode)
    MT.db.repairPay = mode
    for key, row in pairs(payChecks) do
      row.cb:SetChecked(key == mode)
    end
  end
  local function MakePayCheck(key, label, x, y)
    local cb, text = MakeCheck(rb, label, x, y,
      function() return (MT.db.repairPay or "personal") == key end,
      function() end)
    cb:SetScript("OnClick", function()
      SetRepairPay(key)
    end)
    payChecks[key] = { cb = cb, text = text }
  end

  MakePayCheck("personal", "My gold", COL1 + 8, ry)
  MakePayCheck("guild", "Guild bank", COL2, ry)
  ry = ry - ROW
  MakePayCheck("guild_first", "Guild first, then my gold", COL1 + 8, ry)

  function MT:RefreshRepairPayEnabled()
    local on = MT.db.autoRepair and true or false
    if payLabel then
      if on then payLabel:SetTextColor(1, 1, 1) else payLabel:SetTextColor(0.5, 0.5, 0.5) end
    end
    local mode = MT.db.repairPay or "personal"
    for key, row in pairs(payChecks) do
      SetCheckInteractive(row.cb, row.text, on)
      row.cb:SetChecked(key == mode)
    end
  end

  ry = ry - 32
  local repairNowBtn = CreateFrame("Button", nil, rb, "UIPanelButtonTemplate")
  repairNowBtn:SetSize(100, 24)
  repairNowBtn:SetPoint("TOPLEFT", COL1, ry)
  repairNowBtn:SetText("Repair now")
  repairNowBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIRepair", function() MT:TryAutoRepair(true) end)
  end)
  ry = ry - 36
  rb:SetContentHeight(-ry + 24)

  function MT:RefreshRulesChecks()
    for _, panel in ipairs({ keepPanel, sellPanel, repairPanel }) do
      for _, row in ipairs(panel._sync or {}) do
        if row.cb and row.get then
          row.cb:SetChecked(row.get() and true or false)
        end
      end
    end
    MT:RefreshStatChecksEnabled()
    MT:RefreshRepairPayEnabled()
  end

  local function OnRulesChildShow()
    MT:RefreshRulesChecks()
  end
  keepPanel:SetScript("OnShow", OnRulesChildShow)
  sellPanel:SetScript("OnShow", OnRulesChildShow)
  repairPanel:SetScript("OnShow", OnRulesChildShow)

  InterfaceOptions_AddCategory(keepPanel)
  InterfaceOptions_AddCategory(sellPanel)
  InterfaceOptions_AddCategory(repairPanel)
  self.rulesKeepPanel = keepPanel
  self.rulesSellPanel = sellPanel
  self.rulesRepairPanel = repairPanel
  self:RefreshStatChecksEnabled()
  self:RefreshRepairPayEnabled()

  -- Child: About (info + donate)
  local about = CreateFrame("Frame", "AutoSellerAboutOptionsPanel", UIParent)
  about.name = "About"
  about.parent = "AutoSeller & Repair"
  about:Hide()

  local aboutTitle = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  aboutTitle:SetPoint("TOPLEFT", 16, -16)
  aboutTitle:SetText("About")

  local ab = MakeScrollBody(about, -52)
  local ay = -8

  SectionHeader(ab, "AutoSeller & Repair", COL1, ay)
  ay = ay - 22
  SoftNote(ab, "Free Ascension addon: auto-sell junk and auto-repair at merchants, with keep rules and a remembered sell list.", COL1, ay, 460)
  ay = ay - 36

  local verLabel = ab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  verLabel:SetPoint("TOPLEFT", COL1, ay)
  verLabel:SetText("Version: " .. (MT.VERSION or "?"))
  about.verLabel = verLabel
  ay = ay - 28

  SectionHeader(ab, "How to use", COL1, ay)
  ay = ay - 22
  SoftNote(ab, "1. Talk to a merchant — eligible junk sells and gear can auto-repair.\n2. Rules → Keep / Selling / Repair for filters, armor types, and repair.\n3. /autoseller opens options · /autoseller sell|scan for manual actions.", COL1, ay, 460)
  ay = ay - 58

  SectionHeader(ab, "Download", COL1, ay)
  ay = ay - 22
  SoftNote(ab, "Latest release (GitHub):", COL1, ay)
  ay = ay - 20
  local dlBox = CreateFrame("EditBox", "AutoSellerDownloadUrlBox", ab, "InputBoxTemplate")
  dlBox:SetSize(440, 20)
  dlBox:SetPoint("TOPLEFT", COL1, ay)
  dlBox:SetAutoFocus(false)
  dlBox:SetText(MT.DOWNLOAD_URL or "")
  dlBox:SetCursorPosition(0)
  dlBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  dlBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  ay = ay - 32

  SectionHeader(ab, "Support / donate", COL1, ay)
  ay = ay - 22
  SoftNote(ab, "Optional — any amount. Nothing in the addon is locked behind a donation.", COL1, ay, 460)
  ay = ay - 28
  SoftNote(ab, "Donate link (click the box, Ctrl+C to copy):", COL1, ay)
  ay = ay - 20

  local donateBox = CreateFrame("EditBox", "AutoSellerDonateUrlBox", ab, "InputBoxTemplate")
  donateBox:SetSize(440, 20)
  donateBox:SetPoint("TOPLEFT", COL1, ay)
  donateBox:SetAutoFocus(false)
  donateBox:SetText(MT.DONATE_URL or "")
  donateBox:SetCursorPosition(0)
  donateBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  donateBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  ay = ay - 28

  local chatDonateBtn = CreateFrame("Button", nil, ab, "UIPanelButtonTemplate")
  chatDonateBtn:SetSize(160, 24)
  chatDonateBtn:SetPoint("TOPLEFT", COL1, ay)
  chatDonateBtn:SetText("Print link in chat")
  chatDonateBtn:SetScript("OnClick", function()
    local url = MT.DONATE_URL or ""
    MT:Print("Donate (optional): " .. url)
    if ChatFrame1EditBox then
      ChatFrame1EditBox:Show()
      ChatFrame1EditBox:SetFocus()
      ChatFrame1EditBox:SetText(url)
      ChatFrame1EditBox:HighlightText()
    end
  end)
  ay = ay - 36

  SoftNote(ab, "Made by Add Mods.", COL1, ay, 460)
  ay = ay - 28
  ab:SetContentHeight(-ay + 24)

  about:SetScript("OnShow", function()
    if about.verLabel then
      about.verLabel:SetText("Version: " .. (MT.VERSION or "?"))
    end
    if dlBox then dlBox:SetText(MT.DOWNLOAD_URL or "") end
    if donateBox then donateBox:SetText(MT.DONATE_URL or "") end
  end)

  InterfaceOptions_AddCategory(about)
  self.aboutOptionsPanel = about

  self:RefreshRememberList()
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
