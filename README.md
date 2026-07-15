# Add Mods — WoW Addons

**Canonical path:** `C:\Projects\WoW-Addons`  
**Owner dashboard:** https://control.mactech.app/wow  
**Public error paste:** https://control.mactech.app/wow/submit  
**Downloads:** https://github.com/jmacz12/mactech-wowaddons/releases  
**Donate (Add Mods Stripe, live):** https://donate.stripe.com/9B628t7JXekf4B8gRu6c000

Ascension-first World of Warcraft addons. Public brand: **Add Mods** (not MacTech Gear). Mission Control stays your ops hub.

> Note: An older copy may still exist at `C:\Users\Maca_\Projects\WoW-Addons` if Cursor had it open. Use **this** folder only.

## Layout

| Path | Purpose |
|------|---------|
| `addons/AutoSeller` | AutoSeller & Repair — sell, remember, keep rules, auto-repair |
| `apps/control` | Legacy mini-site (superseded by Mission Control `/wow`) |
| `scripts/` | Install into Ascension + pack zip |

## Install AutoSeller & Repair (Ascension 1.0.102)

1. Copy `addons/AutoSeller` into Ascension `Interface\AddOns\` (folder name stays `AutoSeller`)
2. Or: `powershell -File scripts/install-to-ascension.ps1 -AscensionPath "D:\Path\To\Ascension"`
3. In game: Interface → AddOns → **AutoSeller & Repair** · Rules · `/autoseller` · `/mtdb export` → paste at https://control.mactech.app/wow/submit

## Mission Control

Error reports store in the **Mission Control** Supabase project (`wow_addon_debug_reports`). You view them while logged into https://control.mactech.app/wow.
