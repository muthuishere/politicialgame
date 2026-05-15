# Salamia: Grassroots Rising — Spike

A spike build of a political simulation set in the fictional Federal Republic
of Salamia. The full design pitches a career arc from neighbourhood
volunteer to Prime Minister, fighting to pass the **Local Revenue
Empowerment Act** (10% of national sales tax devolved to local bodies).

This spike covers one state — **Aryavarta** (the Hindi heartland) — and
the first arc: **Volunteer → Ward Councillor**.

## What's in the spike

| System | Status |
|---|---|
| Three-track stat model (Personal / Official / Financial) | ✅ |
| Personal stats shown as prose, not numbers | ✅ |
| Scenario engine reading from `data/scenarios.json` | ✅ |
| Branching: flags, follow-up unlocks, gated choices | ✅ |
| 5 volunteer scenarios + 4 councillor scenarios | ✅ |
| Ward election with real vote-share calculation | ✅ |
| 8 endings based on final personal × official score shape | ✅ |
| Save / Load to `user://salamia_save.json` | ✅ |
| Web export → GitHub Pages | ✅ |
| Other 8 states, MLA / Minister / CM / PM phases | ⏳ post-spike |
| Localisation, audio, purchased illustrations | ⏳ post-spike |

## Running locally

1. Install **Godot 4.3** (Standard edition, no .NET): https://godotengine.org/download
2. Open the project: `Project > Open` → select this repo's `project.godot`
3. Press **F5** to play, or **F6** to run the current scene.

Save data lives in Godot's `user://` directory:
- macOS: `~/Library/Application Support/Godot/app_userdata/Salamia/`
- Linux: `~/.local/share/godot/app_userdata/Salamia/`
- Windows: `%APPDATA%\Godot\app_userdata\Salamia\`

## Playing on the web (GitHub Pages)

The repo ships with a ready-to-use Actions workflow at
`docs/github-pages-workflow.yml` that exports an HTML5 build and publishes
it to GitHub Pages.

### One-time setup (3 minutes)

GitHub blocks OAuth tokens (the kind I push with) from creating workflow
files directly — that's a deliberate security restriction. You install it
yourself, just once:

1. **Add the workflow file via GitHub web UI**:
   - Open the repo on github.com
   - Click **Add file → Create new file**
   - Name it: `.github/workflows/deploy.yml`
   - Paste the contents of `docs/github-pages-workflow.yml` (from this repo)
   - Commit to the `claude/godot-political-game-dDIJI` branch
2. Go to **Settings → Pages**
3. Under **Build and deployment → Source**, choose **GitHub Actions**
4. The workflow runs on the next push (or click **Run workflow** under
   the Actions tab to trigger immediately)

The live URL appears under the deploy job's summary, and on
`https://<your-user>.github.io/<repo-name>/`.

Alternatively, from your laptop with the `gh` CLI:

```bash
gh workflow run deploy.yml
```

(after you've placed the file at `.github/workflows/deploy.yml`.)

### Known caveat — web threading

GitHub Pages cannot set the Cross-Origin headers that Godot 4's threaded
web export requires. The export preset in this repo intentionally turns
**threading off** (`variant/thread_support=false`). The game is text-based
so single-threaded performance is fine. If we later add heavy audio or
shader work, we may need to host on Cloudflare Pages or Netlify instead.

## Project structure

```
project.godot              Godot project config (autoloads, display)
export_presets.cfg         Web export configuration
icon.svg                   App icon

scenes/                    Scene roots (just wire to scripts; UI built in code)
  title.tscn               Title screen
  intro.tscn               Background selection + opening letter
  house_hub.tscn           Player's house — pick next scenario from here
  scenario.tscn            Scenario presentation + consequence reveal
  election.tscn            Ward councillor election (budget + result)
  ending.tscn              End-of-spike card based on player's final shape

scripts/
  palette.gd               (autoload) Salamia colour + typography constants
  game_state.gd            (autoload) Stat tracks, flags, save/load, requirements
  scenario_loader.gd       (autoload) JSON-backed scenario database
  ui.gd                    UI factories (cards, buttons, dividers, ₹ formatting)
  stats_panel.gd           Reusable side panel — reacts to GameState signals
  title_screen.gd          ─┐
  intro_screen.gd           │
  house_hub.gd              │  Per-screen controllers
  scenario_screen.gd        │
  election_screen.gd        │
  ending_screen.gd         ─┘

data/
  scenarios.json           Content database — non-programmers can write here
```

## Content schema (`data/scenarios.json`)

Each scenario is a row of structured prose + branching outcomes. **You can
add new scenarios without touching any GDScript** — just append to this
file. Schema:

```json
{
  "id": "vol_garbage",                      // unique
  "phase": "volunteer",                     // "volunteer" | "councillor"
  "state": "aryavarta",                     // for future multi-state filter
  "title": "The Garbage at Tilak Crossing",
  "speaker": "Bashir-bhai, retired postmaster",
  "scene_icon": "smoke",                    // see scenario_screen._icon_glyph
  "narrative": "...multi-paragraph prose...",
  "requires": {                             // optional — gate scenario availability
    "local_trust": 30,                      // any GameState int property
    "min_finances": 5000,                   // special: finances >= 5000
    "flag": "ajm_aligned",                  // requires flag set
    "not_flag": "took_kickback"             // blocked if flag set
  },
  "choices": [
    {
      "label": "Sit down beside him",
      "requires": {"min_finances": 0},      // same syntax as scenario.requires
      "effects": {                          // any GameState property + finances
        "integrity": 10,
        "local_trust": 18,
        "finances": -3000
      },
      "followup": "By 5 PM there are forty of you...",
      "flag": "tilak_sit_in",               // optional — sets a persistent flag
      "unlocks": ["vol_recruiter"]          // optional — preferred next scenarios
    }
  ]
}
```

### Stat keys (effects / requires)

| Track | Keys |
|---|---|
| Personal | `integrity`, `empathy`, `local_trust`, `family_harmony`, `inner_peace` |
| Official | `party_loyalty`, `reform_progress`, `media_reputation`, `coalition_strength` |
| Financial | `finances` (use `min_finances` in `requires`) |

All personal/official stats are clamped 0–100. Finances can go negative
(debt — a hook for later phases).

## Design philosophy notes

- **Numbers are hidden where they should be hidden.** Personal stats appear
  as prose phrases like *"Quietly principled"* or *"Haunted. Sleepless."* —
  never raw integers. Official stats (party loyalty, reform progress) show
  as bars because they map to real-world political metrics that ARE
  legible (vote share, party standing).
- **Every choice costs something.** No free-lunch options. Even the
  "right" choice in The Land Dispute costs family harmony.
- **Money is morally neutral, not a moral track.** Spending ₹3,000 on
  garbage trucks isn't a hit on integrity. Financial deltas render in
  indigo, not red. The morality lives in the personal track.
- **Branching is light but real.** Earlier choices set flags that gate
  later scenario availability (the GST report scenario has different
  outcomes if you previously aligned with the BLS opposition) and shape
  the ending text.

## What this spike is asking you to evaluate

1. **Does the *feel* work?** — read a couple of scenarios. Do the
   moral dilemmas land? Is the prose tone right? Does the consequence
   reveal feel weighty?
2. **Is the visual direction salvageable with placeholder primitives?** —
   the spike uses zero purchased art. If the muted-earth palette + letter
   cards already feel intentional, then minimum-viable production cost
   is much lower than the GDD assumes.
3. **Replayability** — try running independent vs. AJM-aligned, or
   playing principled vs. corrupt. Do the scenario consequences and
   ending text differ enough that a second playthrough feels distinct?

## Asset roadmap (if the spike is greenlit)

The spike was deliberately built with primitives so we can evaluate the
shape before spending money. Production assets (in priority order):

| Asset | Use | Rough cost | Source |
|---|---|---|---|
| Character portraits (5–10 expressions × 8 archetypes) | Per-scenario speakers | $200–400 | Commissioned illustrator, or AI + cleanup |
| Scenario illustrations | Header image per scenario (~50) | $1,500–3,000 | Same illustrator across all → consistent style |
| Custom serif font with Devanagari support | Production typography | $50–200 | MyFonts / Fontspring |
| Icon set | UI affordances | $30–60 | Streamline / Icons8 |
| Ambient soundscape (5–10 loops) | Per scenario type | $100–300 | Epidemic / freesound CC0 |
| Localisation strings management | Multi-language post-launch | $0–500 | Godot has built-in, but PO tooling helps |

For a 3D pivot the cost picture is very different — see project notes.

## License

The code is MIT. The narrative content (scenarios.json, prose) is © the
project author; reuse with permission. Future commissioned art will have
per-asset licensing.
