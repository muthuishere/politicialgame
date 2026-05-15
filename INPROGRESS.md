# In Progress — Salamia: Grassroots Rising

Snapshot for the next working session. Last touched 2026-05-16.

Live build: **https://muthuishere.github.io/politicialgame/**
(Auto-deploys on push to `main` via `.github/workflows/deploy.yaml`.)

---

## Where the game is right now

A walkable 2.5D isometric political simulation. The original spike was text-only;
the world layer was added on top of the existing scenario / stats backend so the
political mechanics stayed intact.

### Playable loop
1. Title screen → "Begin a New Career" → starts a `modest` background career
2. Walkable ward (14×14 isometric, Kenney CC0 city tiles)
3. WASD / arrows move the player; camera follows (zoom 1.4)
4. Three NPCs in the ward (Lakshmi-bai, Ramesh, Devi) — press **E** in range to trigger a political scenario
5. Two doors lead into interiors:
   - **House interior** (8×8) — "Your mother" NPC, back-door warps to ward at `HouseReturn` marker
   - **Panchayat office interior** (10×8) — Ramesh the clerk + Mr. Mishra, back-door warps to `OfficeReturn`
6. Scenarios use the original ScenarioLoader / GameState backend → choice consequences feed back into stats

### Visuals (placeholder)
- Player: stack of ColorRects (head + body + saffron sash + shadow) — no sprite art
- NPCs: same approach, different colors
- World: Kenney CC0 isometric city tiles (chunky building blocks, not residential housing)
- Doors: code-drawn arch (terracotta polygon + brown base + signage)
- HUD: none in the world; old text-based stats panel is unwired

---

## Architecture

```
project.godot         input map (move_up/down/left/right + interact = E/Space)
                      autoloads: GameState, ScenarioLoader, Palette
                      stretch: canvas_items + expand

scenes/
  title.tscn          title screen → goes straight to ward (skips text intro)
  ward.tscn           walkable outdoor map (Node2D root)
                      static Marker2Ds: HouseReturn (-66,165), OfficeReturn (462,429)
  house_interior.tscn 8x8 room (Node2D root)
                      static Marker2D: DoorIn (-132,330)
  office_interior.tscn 10x8 room (Node2D root)
                      static Marker2Ds: DoorIn (132,396), DoorOut (198,495)
  door.tscn           reusable Area2D w/ arch graphic + interact prompt
  npc.tscn            reusable Area2D w/ talk-radius + interact prompt
  scenario.tscn       (legacy) text-based scenario presenter, unchanged
  intro.tscn          (legacy) text intro — currently bypassed by title

scripts/
  iso.gd              static Iso.grid_to_screen / screen_to_grid helpers
                      TILE_W=132, TILE_H=66
  player.gd           CharacterBody2D, isometric 8-way movement
                      _ready handles spawn_marker meta — jumps to named
                      Node2D in current_scene if a door warped us here
  ward.gd             builds the ward in code (paint_ground/roads/buildings/doors)
                      _position_player is a FALLBACK only (skips if marker moved player)
  house_interior.gd   builds house in code; adds DoorOut + exit Door at runtime
  office_interior.gd  builds office in code; adds exit Door at runtime
                      (DoorIn + DoorOut are static .tscn nodes)
  door.gd             Area2D, polls Input.is_action_just_pressed("interact")
                      sets spawn_marker meta → change_scene_to_file
  npc.gd              Area2D, same polling pattern, opens scenario via ScenarioLoader

assets/
  kenney_iso/         128 CC0 isometric city tiles (https://kenney.nl)
                      assets/kenney_iso/LICENSE.txt
```

### Subtle invariants
- **Spawn-marker timing.** Player.gd `_ready` runs before scene-root `_ready` (children first). So return markers (HouseReturn, OfficeReturn) and entry markers (DoorIn) **must** be declared statically in `.tscn` files — if a scene script adds them in `_ready`, the player can't find them. Exit doors (DoorOut markers + Door instances) can be runtime since the player doesn't search for them on entry.
- **`_position_player` is a fallback.** If `player.position != Vector2.ZERO` at scene-root `_ready` time, the marker-based warp already moved them; don't override.
- **z_index ordering.** Tile z_index = int(gx + gy) for painters' sort. Entities live in a y_sorted node with z_index=500; Player has z_index=1000 + dynamic offset.
- **Linux runner case sensitivity.** GitHub Actions runner is case-sensitive. `firebelley/godot-export` emits to `build/<PresetName>/` (capital W). Workflow's "Find the Godot export and stage as the Pages site root" step does a wildcard `find . -name index.html` to handle this.

---

## Open decisions (DEFERRED)

### Art direction
The current placeholder ColorRect + Kenney tile look is functional but bland.
Options researched but **not decided**:

- **A. Suzerain-style cinematic** — drop the walkable world, build out illustrated portraits + scenario cards. Cheapest, fits the genre best (Democracy 4, Suzerain, This Is The Police are all 2D-static).
- **B. LimeZu pixel art** — $19 total, top-down 3/4 style, character generator, comprehensive interiors/exteriors. Rejected by user — "why do we need pixel art."
- **C. Synty 2D vector** — $50–80, flat clean vector "corporate / infographic" look, fits political genre tone.
- **D. Custom illustration commission** — $300–800, hand-drawn Indian-aesthetic art. Best result, longest turnaround.
- **E. 3D rebuild (Synty Polygon)** — $120+, multi-day engine rewrite. Considered and recommended against for this genre.

User explicitly asked for "corporate" not "pixel" and is open to $50 budget. Path B (LimeZu) was the original recommendation but does not match user's taste. Path C (Synty 2D vector) is the most likely next move; Path A is the architecturally honest choice (matches what successful games in this genre actually do).

**Next session should start by deciding A vs C.** Don't repeat the LimeZu pitch — that's settled as a "no."

---

## Known gaps / next things

- **No perimeter walls in the ward.** Player can walk off the tiled area into empty cream background. Add `StaticBody2D` walls along the grid edges in `ward.gd`.
- **Player and NPC sprites are placeholder.** Will be replaced once art direction is settled.
- **HUD missing.** GameState stats (volunteer / week / funds / reform%) aren't visible in the walkable world. The old `stats_panel.gd` exists but isn't wired into the new scenes.
- **Title screen still uses the text-only Salamia title.** Acceptable for now but should be reskinned with the chosen art direction.
- **Scenario screen is still text-only.** When art direction lands, decide whether to keep it text-and-choices or convert to portrait + dialog overlay on top of the world (no scene change).
- **No save-game UX in the world.** Save happens implicitly in `house_hub.gd` which is no longer reached. Move the save call to scene transitions or add a "Save" interaction.
- **Old scenes (`house_hub.tscn`, `intro.tscn`, `election.tscn`, `ending.tscn`) are orphaned** but kept in the repo. Decide whether to integrate or delete after art direction.
- **`ScenarioLoader.remaining_for_phase("volunteer")` will eventually hit 0.** The election scene exists but isn't reachable from the walkable world. Add a trigger (campaign HQ door, or a date-based check) once the basic flow feels good.

---

## How to run / deploy

Local:
```bash
godot --headless --export-release "Web" build/web/index.html
cd build/web && python3 -m http.server 8765
# open http://localhost:8765/index.html
```

Deploy (any push to main):
- `.github/workflows/deploy.yaml` runs firebelley/godot-export then deploys to GitHub Pages
- Pages site: https://muthuishere.github.io/politicialgame/

---

## Memory notes
- User strongly rejected text-only design — game must be visual / walkable.
- User strongly rejected pixel art aesthetic — wants "corporate" / clean look.
- User is willing to spend up to ~$50 on premium assets.
- User wants the agent team approach (parallel subagents) for non-overlapping work.
