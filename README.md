# MacTech WoW Addons

Ascension-first World of Warcraft addons, shared debug tooling, and a control panel for errors / downloads / donations.

## What’s in this repo

| Path | Purpose |
|------|---------|
| `addons/MacTech_AutoSeller` | First addon — auto-sell junk with keep rules (resources, rare+, soulbound, stats) |
| `apps/control` | Next.js control site (deploy to Vercel → `control.mactech`) |
| Mission Control Supabase | `wow_addon_debug_reports` + `wow_addon_learning_events` |

## Install AutoSeller (Ascension 1.0.102)

1. Copy `addons/MacTech_AutoSeller` into Ascension `Interface\AddOns\`
2. Or run: `powershell -File scripts/install-to-ascension.ps1 -AscensionPath "D:\Path\To\Ascension"`
3. In game: `/mtas` options · `/mtas sell` · `/mtdb` debug · `/mtdb export`

## Publish / downloads

1. **GitHub Releases** — zip `MacTech_AutoSeller`, attach to a Release (users download + unzip into AddOns)
2. **control.mactech/download** — install instructions + later direct zip links
3. **Retail later** — CurseForge / Wago (separate retail-flavored build; Blizzard TOS: no paid addons; donations OK)

## Money (donations)

- Stripe Payment Link → `STRIPE_PAYMENT_LINK` → `/api/donate`
- Retail: CurseForge Rewards + Ko-fi/Patreon OK; selling the addon itself is not allowed by Blizzard
- Ascension: donations still the clean default

## Debug → control.mactech

1. Addon captures errors via MacTechDebug (`/mtdb`)
2. Player runs `/mtdb export` and pastes at `/debug` (Ascension has no reliable addon HTTP)
3. Rows land in Supabase `wow_addon_debug_reports`
4. You unlock `/errors` with `CONTROL_ADMIN_PASSWORD`

## Learning (opt-in)

Players can enable a local event buffer in the addon UI. Next step: export/upload aggregates so rules improve over time. No silent uploads.

## Control app (local)

```bash
cd apps/control
cp .env.example .env.local   # already seeded for Mission Control anon key locally
npm run dev
```

Admin password default in local `.env.local`: set your own before any public deploy.

## Stack auth status

- GitHub: ready (`gh` as `jmacz12`)
- Vercel: team available; deploy `apps/control`
- Stripe: MCP auth needed once to create the Payment Link
- Supabase: Mission Control project wired for reports
