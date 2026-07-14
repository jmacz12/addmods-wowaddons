# MacTech WoW Addons

**Canonical path:** `C:\Projects\WoW-Addons`  
**Owner dashboard:** https://control.mactech.app/wow  
**Public error paste:** https://control.mactech.app/wow/submit  
**Downloads:** https://github.com/jmacz12/mactech-wow-addons/releases  
**Donate (Add Mods Stripe, live):** https://donate.stripe.com/9B628t7JXekf4B8gRu6c000

Ascension-first World of Warcraft addons with MacTech Debug export into Mission Control.

> Note: An older copy may still exist at `C:\Users\Maca_\Projects\WoW-Addons` if Cursor had it open. Use **this** folder only.

## Layout

| Path | Purpose |
|------|---------|
| `addons/MacTech_AutoSeller` | Auto-sell junk with keep rules + MacTech Debug |
| `apps/control` | Legacy mini-site (superseded by Mission Control `/wow`) |
| `scripts/` | Install into Ascension + pack zip |

## Install AutoSeller (Ascension 1.0.102)

1. Copy `addons/MacTech_AutoSeller` into Ascension `Interface\AddOns\`
2. Or: `powershell -File scripts/install-to-ascension.ps1 -AscensionPath "D:\Path\To\Ascension"`
3. In game: `/mtas` · `/mtdb export` → paste at https://control.mactech.app/wow/submit

## Mission Control

Error reports store in the **Mission Control** Supabase project (`wow_addon_debug_reports`). You view them while logged into https://control.mactech.app/wow — same place as your other MacTech ops.
