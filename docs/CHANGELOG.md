# Changelog

Newest first. One line per ship.

**Format:** `YYYY-MM-DD:` **Feature name** **(live/local)** — plain-English outcome · `owner OK` when verified.

---

- 2026-07-15: **AutoSeller & Repair v0.3.11 (live)** — Remembered list can dump unwanted mats/consumables (still no profession/level rules); keep-by-stats still wins.
- 2026-07-15: **AutoSeller & Repair v0.3.10 (live)** — Remember list grows on right-click vendor sells (whites+); gray still skipped; clearer chat feedback.
- 2026-07-15: **AutoSeller & Repair v0.3.9 (live)** — Fix remember-on-sell (vendor click was forgetting the item); armor-type sells (Cloth/Leather/Mail/Plate); Rules split into Keep / Selling / Repair tabs.
- 2026-07-15: **AutoSeller & Repair v0.3.8 (live)** — UI polish: trim debug/learning from panels, clearer About/main copy, Rules spacing + confirms (Clear all / Sell now), Soulbound tooltip, OnShow sync; Repair now works even if auto-repair is off; drop `/mtas`; short login line.
- 2026-07-15: **AutoSeller & Repair v0.3.7 (local)** — Sell priority: resources/consumables → keep-by-stats → color → remembered → weaker-than-equipped (ilvl, opt-in, green-).
- 2026-07-15: **AutoSeller & Repair v0.3.6 (local)** — Color sells (Green/Blue/etc.) now win over Soulbound + High-end; Scan bags reports keep reasons (esp. greens held by keep-by-stats).
- 2026-07-15: **AutoSeller & Repair v0.3.5 (local)** — About tab (version, how-to, download + donate URL copy/print). Keep-by-stats crash fix from 0.3.4 included.
- 2026-07-15: **AutoSeller & Repair v0.3.4 (local)** — Fix keep-by-stats: intellect/stamina/etc patterns crashed auto-sell (escaped Lua `+`); safer match.
- 2026-07-15: **AutoSeller & Repair v0.3.3 (local)** — Rules page scroll + Keep-by-stats moved to top with aligned 2-column grid.
- 2026-07-15: **Public GitHub cleanup (live)** — Repo renamed to `addmods-wowaddons`; removed Mission Control links from public README / homepage / addon website field.
- 2026-07-15: **AutoSeller & Repair v0.3.2 (live)** — Display rename; Keep consumables; auto-repair (my gold / guild / guild first); skip unsellable items (no vendor price); bag button removed.
- 2026-07-15: **AutoSeller v0.3.1 (live)** — Rules page holds Selling + Keep; remember list cleaned up; GitHub repo renamed to `mactech-wowaddons`; other public repos set private.
- 2026-07-15: **AutoSeller v0.3.0 (live)** — Interface→AddOns settings, Selling/Remember/Keep rules, searchable paged remember list, sell gray/white/green/blue/purple (keep rules respected), bag coin button; folder `addons/AutoSeller`.
- 2026-07-15: **AutoSeller v0.2.0 (live)** — Sell junk button, remembered sell list, keep-by-stats; in-game name AutoSeller (no MacTech). Folder/SavedVariables still legacy until careful migrate.
- 2026-07-14: **AutoSeller v0.1.0 (live)** — GitHub Releases + Mission Control `/wow` inbox + Stripe Add Mods donate.
