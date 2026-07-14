--[[
  MacTechDebug — shared in-game error capture + export for control.mactech
  Works offline in Ascension (no HTTP from Lua). Users can export reports.
]]

local ADDON = ...
MacTechDebug = MacTechDebug or {}

local MAX_ERRORS = 50
local errors = {}
local listeners = {}

local function now()
  return date("%Y-%m-%d %H:%M:%S")
end

local function truncate(s, n)
  s = tostring(s or "")
  if #s <= n then return s end
  return s:sub(1, n - 3) .. "..."
end

function MacTechDebug:Register(addonName, version)
  self.addonName = addonName or "MacTech"
  self.version = version or "0.0.0"
  self.client = GetBuildInfo and select(1, GetBuildInfo()) or "unknown"
end

function MacTechDebug:OnError(callback)
  listeners[#listeners + 1] = callback
end

function MacTechDebug:Capture(message, stack, context)
  local entry = {
    id = (#errors + 1),
    time = now(),
    addon = self.addonName,
    version = self.version,
    client = self.client,
    message = truncate(message, 1000),
    stack = truncate(stack or debugstack(2), 4000),
    context = context or {},
  }
  table.insert(errors, 1, entry)
  while #errors > MAX_ERRORS do
    table.remove(errors)
  end
  for _, cb in ipairs(listeners) do
    pcall(cb, entry)
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MacTech Debug]|r " .. truncate(entry.message, 200))
  return entry
end

function MacTechDebug:SafeCall(label, fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then
    return a, b, c, d
  end
  self:Capture(label .. ": " .. tostring(a))
end

function MacTechDebug:GetErrors()
  return errors
end

function MacTechDebug:Clear()
  wipe(errors)
end

function MacTechDebug:ExportJson()
  -- Minimal hand-rolled JSON for Ascension-era Lua (no libraries assumed)
  local function esc(s)
    s = tostring(s or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
    return '"' .. s .. '"'
  end
  local parts = {}
  parts[#parts + 1] = '{"addon":' .. esc(self.addonName)
  parts[#parts + 1] = ',"version":' .. esc(self.version)
  parts[#parts + 1] = ',"client":' .. esc(self.client)
  parts[#parts + 1] = ',"exportedAt":' .. esc(now())
  parts[#parts + 1] = ',"errors":['
  for i, e in ipairs(errors) do
    if i > 1 then parts[#parts + 1] = "," end
    parts[#parts + 1] = "{"
    parts[#parts + 1] = '"id":' .. tostring(e.id)
    parts[#parts + 1] = ',"time":' .. esc(e.time)
    parts[#parts + 1] = ',"message":' .. esc(e.message)
    parts[#parts + 1] = ',"stack":' .. esc(e.stack)
    parts[#parts + 1] = "}"
  end
  parts[#parts + 1] = "]}"
  return table.concat(parts)
end

-- Global error hook (best-effort; does not replace BugSack on retail)
local originalHandler = geterrorhandler and geterrorhandler()
if seterrorhandler then
  seterrorhandler(function(err)
    MacTechDebug:Capture(err)
    if originalHandler then
      return originalHandler(err)
    end
  end)
end

SLASH_MACTECHDEBUG1 = "/mtdb"
SLASH_MACTECHDEBUG2 = "/mactechdebug"
SlashCmdList.MACTECHDEBUG = function(msg)
  msg = strtrim(string.lower(msg or ""))
  if msg == "clear" then
    MacTechDebug:Clear()
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MacTech Debug]|r Cleared.")
    return
  end
  if msg == "export" then
    local payload = MacTechDebug:ExportJson()
    if MacTechAutoSellerDB then
      MacTechAutoSellerDB.lastDebugExport = payload
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MacTech Debug]|r Export saved. Paste it at control.mactech.app/wow/submit")
    DEFAULT_CHAT_FRAME:AddMessage(truncate(payload, 240))
    return
  end
  local list = MacTechDebug:GetErrors()
  DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff55ff55[MacTech Debug]|r %d error(s). Commands: /mtdb  /mtdb export  /mtdb clear", #list))
  for i = 1, math.min(5, #list) do
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d) %s", i, truncate(list[i].message, 160)))
  end
end
