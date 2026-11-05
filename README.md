# The Mimic: Lost in the Wood — Godot Prototype

A small, original first-person horror-game prototype built with Godot 4 and primitive, generated geometry. This is a playable slice, not the complete AAA-scale game described in the original brief.

## Run it

1. Install Godot 4.x.
2. Clone or download this repository.
3. In Godot, choose **Import** and select `project.godot`.
4. Press **F6** or **F5** to play.

No third-party assets are required. The room, forest edge, lighting, key, and creature are created from built-in Godot primitives at runtime.

## Controls

- **WASD** — move
- **Mouse** — look
- **Shift** — sprint
- **Ctrl** — crouch / move slowly
- **E** — interact
- **F** — toggle flashlight
- **Esc** — release / recapture the mouse

## Current playable slice

- First-person movement and mouse look
- Flashlight
- Interaction prompt and a collectible spare key
- Locked exit door that opens after collecting the key
- Small house interior and forest-edge setting
- A simple creature that pursues the player at close range
- Objective text, escape message, and caught/restart-at-room response

This prototype does not yet include mobile controls, save/load, voice acting, the full story, puzzles, or six endings. The simple creature logic and primitive visuals are placeholders for later iteration. It has not been run in a Godot editor as part of this repository update, so please treat runtime validation as still needed.
