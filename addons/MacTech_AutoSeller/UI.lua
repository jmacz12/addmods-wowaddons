local MT = MacTechAutoSeller

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
  return cb
end

function MT:UpdateRememberedLabel()
  if self.rememberedLabel then
    self.rememberedLabel:SetText(string.format("Remembered sell items: %d", self:CountRememberedSell()))
  end
end

function MT:CreateUI()
  if self.frame then return end

  local f = CreateFrame("Frame", "AddModsAutoSellerFrame", UIParent)
  f:SetSize(380, 480)
  f:SetPoint("CENTER")
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("AutoSeller")

  local y = -48
  MakeCheck(f, "Enable auto-sell at merchants", 24, y, function() return MT.db.enabled end, function(v) MT.db.enabled = v end)
  y = y - 28
  MakeCheck(f, "Sell gray junk", 24, y, function() return MT.db.sellGray end, function(v) MT.db.sellGray = v end)
  y = y - 28
  MakeCheck(f, "Remember items I sell (auto next time)", 24, y,
    function() return MT.db.learnOnSell end,
    function(v) MT.db.learnOnSell = v end)
  y = y - 28
  MakeCheck(f, "Keep resources / trade goods", 24, y, function() return MT.db.keep.resources end, function(v) MT.db.keep.resources = v end)
  y = y - 28
  MakeCheck(f, "Keep high-end (Rare+)", 24, y, function() return MT.db.keep.highEnd end, function(v) MT.db.keep.highEnd = v end)
  y = y - 28
  MakeCheck(f, "Keep soulbound", 24, y, function() return MT.db.keep.soulbound end, function(v) MT.db.keep.soulbound = v end)
  y = y - 36

  local statsTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  statsTitle:SetPoint("TOPLEFT", 28, y)
  statsTitle:SetText("Keep gear with these stats:")
  y = y - 24

  MakeCheck(f, "Enable keep-by-stats", 24, y, function() return MT.db.keep.byStats.enabled end, function(v) MT.db.keep.byStats.enabled = v end)
  y = y - 26

  local stats = { "intellect", "stamina", "spirit", "agility", "strength", "haste", "crit", "hit" }
  local col, row = 0, 0
  for _, stat in ipairs(stats) do
    local sx = 40 + (col * 150)
    local sy = y - (row * 24)
    MakeCheck(f, stat:gsub("^%l", string.upper), sx, sy,
      function() return MT.db.keep.byStats[stat] end,
      function(v) MT.db.keep.byStats[stat] = v end)
    col = col + 1
    if col > 1 then col = 0; row = row + 1 end
  end
  y = y - (math.ceil(#stats / 2) * 24) - 12

  local rememberedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  rememberedLabel:SetPoint("TOPLEFT", 28, y)
  rememberedLabel:SetText("Remembered sell items: 0")
  self.rememberedLabel = rememberedLabel
  y = y - 28

  MakeCheck(f, "Opt-in learning buffer (Mission Control export)", 24, y,
    function() return MT.db.optInLearning end,
    function(v) MT.db.optInLearning = v end)

  local sellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  sellBtn:SetSize(100, 24)
  sellBtn:SetPoint("BOTTOMLEFT", 24, 24)
  sellBtn:SetText("Sell junk")
  sellBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UISell", function() MT:SellEligible() end)
  end)

  local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  scanBtn:SetSize(80, 24)
  scanBtn:SetPoint("LEFT", sellBtn, "RIGHT", 6, 0)
  scanBtn:SetText("Scan")
  scanBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIScan", function() MT:ScanInventory(true) end)
  end)

  local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBtn:SetSize(90, 24)
  clearBtn:SetPoint("LEFT", scanBtn, "RIGHT", 6, 0)
  clearBtn:SetText("Forget all")
  clearBtn:SetScript("OnClick", function()
    MacTechDebug:SafeCall("UIClearRemembered", function() MT:ClearRememberedSell() end)
  end)

  local debugBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  debugBtn:SetSize(70, 24)
  debugBtn:SetPoint("LEFT", clearBtn, "RIGHT", 6, 0)
  debugBtn:SetText("Debug")
  debugBtn:SetScript("OnClick", function()
    SlashCmdList.ADDMODSDEBUG("export")
  end)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  f:SetScript("OnShow", function()
    MT:UpdateRememberedLabel()
  end)

  self.frame = f
  self:UpdateRememberedLabel()
end

function MT:ToggleUI()
  if not self.frame then self:CreateUI() end
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end
