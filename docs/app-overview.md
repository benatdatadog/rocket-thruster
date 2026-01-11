# RocketThruster: Architecture & Flow Overview

## What the app is
A 2D “Thrust”-style arcade lander built with SpriteKit and hosted in a SwiftUI shell. You pilot a small rocket with left/right rotation and thrust, navigating walls, grabbing fuel, and landing on a pad. Levels get progressively harder. A start overlay gates the action; game-over and win overlays handle resets; a pause menu offers resume/restart/quit plus a debug toggle that strips walls and slows time for testing. Rotation is manual (physics rotation disabled) to keep controls symmetric and predictable.

## High-level architecture
- **SwiftUI shell**: Launches the SpriteKit view, defers system gestures, hides home indicator.
- **SpriteKit scene (GameScene.swift)**: Core game loop, rendering, physics, collisions, input handling, overlays, audio, particles, state progression.
- **Persistence**: UserDefaults for per-level bests and top-5 history; `rocket-thruster-stats.txt` in Documents mirrors stats.
- **Assets**: WAVs for thrust/landing/crash/fuel/start/gameover/win; placeholder SF2-ish loop/start/fight/win WAVs included. Background music auto-picks `sf2-loop`/`sf2_theme`/`chiptune` if present.
- **Project settings**: Dead code stripping enabled; resources bundled in Xcode target.

## Key systems inside GameScene
**Scene lifecycle**: First load per app run shows loading overlay, then builds scene (load stats/level, HUD, controls, pause button, starfield, frame, audio, particles, start gate). Later loads skip the loader; death/reset doesn’t re-show it.

**Levels & scaling**: Levels define gravity, walls, pad, fuel packs, start position/rotation. Geometry scales to screen, framed by console border; pad clamped above control overlay; right walls nudged to align with frame.

**Rendering/visuals**: Red console frame; 3-layer parallax starfield; walls with outlines; bright pad with outline/glow; orange fuel with white label; custom vector rocket (nose/body/fins) centered for rotation; rocket glow only in debug mode; particles for thruster and impacts; pad glow; HUD top-left with fuel/lives/level/best; center messages fade in/out; overlays for start/pause/game-over/win.

**Input model**: Screen thirds: left/right rotate, middle thrust. Touch IDs tracked to avoid stuck input when system gestures intrude. Home indicator deferred. No physics rotation; manual rotation each frame; angular velocity zeroed; light horizontal damping and max speed cap.

**Physics/tuning**: Gravity per level; polygon ship body; static walls/pad/fuel bodies. Thrust applies force in heading; fuel burn while thrusting; thrust sound/emitter ramp; max speed clamp. Rotation speed/thrust tuned for gentle but responsive feel; global timeScale; debug halves timeScale and removes walls. Contacts: ship-wall → crash; ship-pad → landing; ship-fuel → refill.

**Game flow**: Start overlay gates play; tap start → READY/FIGHT stings/messages → physics runs. Pause stops physics/starfield/emitter and shows resume/restart/quit/debug + stats. Landing records time, advances level or shows win. Crash reduces lives; <0 lives → game over; otherwise reload level. Level-complete messages auto-advance. Win/game-over overlays reset after a short wait. Debug removes obstacles and slows time.

**Audio**: SFX via SKAction; thrust via looping SKAudioNode. Music via SKAudioNode picks first available (`sf2-loop`, `sf2_theme`, `chiptune`), else silent. SF2-inspired stings: start/fight/win try alt filenames, fallback to defaults. Placeholder WAVs included.

**Stats/persistence**: On landing, record elapsed time; keep top-5 per level; store per-level best and total best in UserDefaults; write `rocket-thruster-stats.txt` in Documents. HUD shows current level’s best; pause shows best and total best.

**Debug aids**: Pause menu debug toggle (no walls, half speed); touch-tracking avoids stuck inputs; speed clamp and damping to reduce drift; start gate prevents instant launch.

## Framework roles
- **SwiftUI**: Hosts SKView, handles gesture deferral/home indicator.
- **SpriteKit**: Rendering, physics, contacts, actions, emitters, audio nodes, update loop.
- **Foundation/UserDefaults/FileManager**: Stats persistence and stats file writing.
- **CoreGraphics**: Geometry and scaling math.
- **AVFoundation (via SpriteKit audio)**: Audio playback.

## Runtime loop (simplified)
1) App launches → SwiftUI hosts SKView → GameScene.
2) First load: loading overlay → build scene → start overlay.
3) Tap start: READY/FIGHT stings/messages → physics runs.
4) Frame update: handle input flags; apply thrust; clamp speed; scroll starfield; update HUD; particles/audio respond.
5) Contacts: crash/landing/fuel → adjust lives/fuel/progress; landing records time and advances; final level → win; lives <0 → game over.
6) Pause overlay can stop physics and offer resume/restart/quit/debug.
7) Stats persist; loader only on app launch.

## Customizing next
- Swap audio by replacing `sf2-*.wav/mp3` with real tracks.
- Art pass: pixel textures for walls/pads/rocket; softer vignette; richer particles.
- Level design: more levels, moving hazards, zero-G segments.
- HUD polish: shadows/outlines, center HUD for intros.
- FX: stronger plume, pad highlight in zone, subtle screen shake on crash/land.
