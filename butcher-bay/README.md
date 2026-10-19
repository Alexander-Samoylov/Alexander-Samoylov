# Butcher Bay

2D side-view horror endless runner on **Godot 4.7** (GDScript). You are a victim in a butcher's cellar: run the flesh-and-bone corridor, swap three depth lanes, jump, slide — and do not let the chainsaw catch you.

## Controls

- **Swipe left / right** (or A/D, arrows) — change lane (near / mid / far)
- **Swipe up** (or W, Up, Space) — jump; during a squeeze, enter the ventilation
- **Swipe down** (or S, Down) — slide under hanging hooks
- Mouse drag works the same as a swipe (browser / desktop)

## Mechanics

- Auto-run to the right; camera stays side-on, profile sprites
- Blood puddles slow you; the butcher closes in
- Corpses and floor saws — jump; overhead hooks — slide
- Gut walls smash only at full speed (speed amulet helps; puddle slow blocks it)
- Victim amulets: temporary **shield** (one hit) or **speed**
- The butcher sometimes vanishes and bursts from a wall, trash pile, or corpse — leave that lane
- Corridor squeeze: swipe up into the vent or get crushed
- Chase meter at 0, or a lethal hit, opens the death screen (chainsaw close-up)

## Open in Godot

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET)
2. Import `butcher-bay/project.godot`
3. Play (`F5`)

Regenerate placeholder pixel art / SFX:

```bash
python3 tools/generate_assets.py
```

## Export

Export presets are in `export_presets.cfg`:

| Preset | Path | Notes |
| --- | --- | --- |
| Web | `build/web/index.html` | Compatibility renderer, single-thread. Best way to share a demo. |
| Android | `build/android/ButcherBay.apk` | Package `com.butcherbay.game`, landscape, arm64. Needs Android SDK + debug keystore in Editor Settings. |
| iOS | `build/ios/ButcherBay.ipa` | Bundle `com.butcherbay.game`, landscape. Export from macOS with Xcode and a team id. |

Editor: **Project → Export**, download 4.7.2 export templates, then Export Project.

CLI example after templates are installed:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

Signed store builds are not produced in this repo; add your keystore / Apple team locally.

## Tests

```bash
godot --headless --path . --script res://tests/test_runner.gd
```
