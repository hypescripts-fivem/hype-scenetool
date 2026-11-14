# hype-scenetool

An in-game film set for FiveM. Spawn vehicles, NPCs and props, pose them to the centimetre, give them animations and tasks, freeze time around you and save the whole set to load it again later. Built for recording server trailers, TikTok clips and roleplay showcases without a separate editor.

Standalone: it only needs **ox_lib** and works on any framework.

---

## Features

### Spawning
- **Vehicles, NPCs and props** from preset lists in `config.lua`, or type any model name from the game or your server.
- **Clone yourself**: spawns an exact copy of your character, so one person can play both sides of a scene.
- Spawns where you are looking (raycast up to 30 m), otherwise a few metres in front of you.
- Spawned vehicles get the plate from the config, a full tank (also as a `fuel` state bag), no hotwiring, and **vehicle keys** through `fast-vehiclekeysv2`, `qbx_vehiclekeys` or `qb-vehiclekeys`, whichever is running.
- **Select what I'm looking at** adds an existing world vehicle, NPC or prop to the scene so you can edit it too (players can't be selected).

### Positioning
- **Keyboard editor** that moves along the camera direction, with fine and fast steps, pitch and roll for vehicles and props, and a live readout of coordinates and rotation.
- **Exact coordinates**: type X, Y, Z, heading, pitch and roll by hand.
- **Bring in front of me**, **freeze** (no physics, stays in place) and **copy coordinates** as `vec4(...) -- rot vec3(...)`.

### Vehicles
- Teleport into any seat, attach a trailer behind a truck (8 preset trailers).
- Engine, headlights (off / on / high beam), 2 second horn, open any combination of doors, hood and trunk.
- Custom primary and secondary colours, plate text, livery.
- Dirt level and damage presets: repair, light front damage, heavy damage with broken windows and a burst tyre.

### NPCs
- **22 preset animations** (talking, arguing, gestures, phone, tablet, clipboard, radio, carrying a box ...), some with a prop in hand, and **11 scenarios** (welding, drilling, smoking, coffee, leaning ...).
- Custom animation (dict, clip and playback mode) and custom scenario by name.
- Talking animations also move the NPC's lips.
- Put an NPC in any seat of a scene vehicle, get it out, **drive to the waypoint** at a chosen speed, wander in traffic or on foot, **walk / run / sprint to the waypoint**, follow you, face you, stop its task, random outfit.
- The same animation menu works on your own character.

### Filming settings
All of these only change **your own screen**, so other players are not affected.

| Setting | What it does |
| --- | --- |
| Hide HUD and map | Hides the game HUD and radar (a custom server HUD has to be hidden separately) |
| Traffic and pedestrians off | Zero traffic, parked cars and pedestrians for clean shots |
| **Stop time** | NPCs, vehicles and scene props within the radius freeze mid-motion, animations pause mid-pose, you move freely. On resume every vehicle continues with its old speed |
| Time and weather | Local clock and weather override, then one click to sync back to the server |
| Clear the area | Removes nearby NPCs and traffic vehicles (scene and player vehicles stay) |
| Lip sync | Mouths of players talking in voice chat move |
| Talking gestures | Your hands gesture while you talk in voice chat |

Talking gestures have their own command (`/konusma` by default) that every player can use without the tool permission, so the actors on a set can turn it on for themselves.

### Scenes
- **Save** everything you spawned under a name: position, rotation, freeze state, full vehicle properties, engine state, trailer links, NPCs in seats, clones and running animations or scenarios.
- **Load** it back exactly where it was saved, or **delete** it. The list shows the entity count, date and author.
- Scenes are JSON files in `scenes/`, so you can back them up or share them between servers.

### Other
- Multi-language through ox_lib locales: English, Turkish, German, Spanish and French included.
- ACE permission check on the client and on every server callback.
- Everything the tool spawned is cleaned up when the resource stops.

---

## Requirements

| Resource | Link |
| --- | --- |
| **ox_lib** | https://github.com/overextended/ox_lib/releases/latest |
| Vehicle keys (optional) | `fast-vehiclekeysv2`, `qbx_vehiclekeys` or `qb-vehiclekeys` |
| Weather sync (optional) | `qb-weathersync` or Renewed-Weathersync are paused while you override time or weather |

---

## Installation

1. Put `hype-scenetool` in your `resources` folder.
2. Add to `server.cfg` after ox_lib:

```cfg
ensure ox_lib
ensure hype-scenetool

# who may use the tool (set Config.Ace = false to allow everyone)
add_ace group.admin hypescene.use allow

# language: en, tr, de, es, fr
setr ox:locale "en"
```

3. Make sure the server can write to `hype-scenetool/scenes/`, saved scenes are stored there.

---

## Usage

Open the menu with **`/scene`** or **F7** (players can rebind the key in *Settings > Key Bindings > FiveM*).

Main menu: **Spawn vehicle**, **Spawn NPC**, **Spawn object**, **Scene entities** (everything in the scene with its distance), **Select what I'm looking at**, **Animate me**, **Filming settings**, **Scenes** and **Delete everything**.

Choose an entity to open its menu with the positioning, vehicle or NPC options above.

### Editor controls

| Key | Action |
| --- | --- |
| `W` `A` `S` `D` | Move (follows the camera) |
| `Q` / `E` | Down / up |
| `←` / `→` | Turn |
| `↑` / `↓` | Pitch (vehicles and props) |
| `Z` / `C` | Roll (vehicles and props) |
| `Shift` / `Ctrl` | Fast / slow |
| `H` | Move to where you are looking |
| `G` | Place on the ground |
| `R` | Reset pitch and roll |
| `X` | Toggle freeze |
| `Enter` | Save |
| `Backspace` | Cancel and restore the old position |

### Stop time shortcut

The *stop / resume time* key is unbound by default. Bind it in *Settings > Key Bindings > FiveM* or set `Config.TimeStop.key`, so you can freeze a moving scene in the middle of a take.

---

## Configuration

Everything is in `config.lua`.

| Key | Default | Description |
| --- | --- | --- |
| `Config.Command` | `'scene'` | Command that opens the menu |
| `Config.Keybind` | `'F7'` | Default key, `false` for command only |
| `Config.Ace` | `'hypescene.use'` | ACE needed to use the tool, `false` for everyone |
| `Config.Plate` | `'HYPE'` | Plate text of spawned vehicles |
| `Config.SpawnDistance` | `6.0` | Spawn distance when you are not looking at the ground |
| `Config.Editor` | | Move and rotate step per frame, fast and slow multipliers |
| `Config.TimeStop` | `radius = 150.0` | Freeze radius and optional quick toggle key |
| `Config.Drive` | `speed = 15.0` | Default NPC driving speed (m/s) and driving style |
| `Config.Talk` | `command = 'konusma'` | Gesture command, lip sync distance, gesture clips and pauses |
| `Config.Vehicles` / `Trailers` / `Peds` / `Props` | | Preset spawn lists |
| `Config.Animations` / `Scenarios` | | Preset animation and scenario lists |
| `Config.Weathers` | | Weather types offered in the filming menu |

### Presets

Each preset has a `label` and a `model`:

```lua
Config.Vehicles = {
    { label = 'preset.vehicle.phantom', model = 'phantom' },
    { label = 'My Custom Truck', model = 'mycustomtruck' },
}
```

`label` can be a key from `locales/*.json` (shown in each player's language) or plain text (shown as is).

Animations take a dict, clip and playback flag, optionally a held prop and lip movement:

```lua
-- flag: 0 once, 1 loop, 2 hold last frame, 48 once upper body, 49 loop upper body (can walk)
{ label = 'Use a tablet', dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base', flag = 49,
  prop = { model = 'prop_cs_tablet', bone = 60309, pos = vec3(0.03, 0.002, 0.0), rot = vec3(10.0, 160.0, 0.0) } },
{ label = 'Argue', dict = 'misscarsteal4@actor', clip = 'actor_berating_loop', flag = 49, talk = true },
```

---

## Languages

Texts come from `locales/*.json` through the ox_lib locale module. Included: `en`, `tr`, `de`, `es`, `fr`.

- The server language is set with `setr ox:locale "<code>"`.
- Players can pick their own language in the ox_lib settings menu (on by default, turn it off with `setr ox:userLocales 0`).
- A missing key falls back to English.

To add a language, copy `locales/en.json` to `locales/<code>.json` and translate the values. Keep the `%s`, `%d`, `%.0f` and `%02d` placeholders.

---

## Tips for filming

- **Two roles, one person**: spawn *My own clone*, give it an animation, then stand opposite it.
- **Frozen moment shots**: set NPCs driving or walking, stop time at the right moment and walk the camera through the frozen scene.
- **Repeatable takes**: save the set before the first take and load it again for every retry.
- **Clean background**: turn traffic off, clear the area and hide the HUD before recording.

---

## License

MIT, see [LICENSE](LICENSE).
