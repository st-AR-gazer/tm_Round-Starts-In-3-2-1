![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

# Round Starts In 3 2 1

A lightweight Trackmania Openplanet plugin project for a clear round-start countdown.

By default, each detected pre-start window is normalized to a clear `3 -> 0` scale; those values
are countdown steps rather than literal seconds. A setting can switch the overlay back to the real
remaining time in seconds.

## Sounds

Enable countdown sounds in the **Sounds** settings tab. Choose **None**, **Soft tick**,
**Low beep**, **High beep**, or **Chime** independently for 3, 2, and 1. A fourth
selector sets the shared sound for every tick from 4 upwards. Sounds are off by default.
The volume slider applies to all sounds; **Play** auditions an individual choice even
while disabled. **Preview countdown** uses the current countdown mode and sound settings.

Sounds follow the General tab's countdown mode, enabled state, and game UI visibility
setting. Decimal places do not add extra ticks. Missed ticks are skipped, and small
clock corrections do not repeat ticks. There is no sound at GO.

The bundled tones are generated locally with `python tools/generate_tick_sounds.py`
and included automatically by the build script. Playback uses Openplanet's
`Audio::LoadSample` and `Audio::Play`, as demonstrated by
[StartMeow](https://github.com/st-AR-gazer/tm_startmeow/blob/main/src/Main.as).

Custom audio support is prepared for the future optional `fileexplorer` plugin.
**Add audio file...** is currently disabled until its picker API exists. Its future
callback should pass an absolute file path to `Countdown::ImportCustomSound`, which
returns a new sound ID (or `-1` with an error message). Audio is validated and copied
into this plugin's storage `sounds/` folder; the original file stays untouched.
`sounds/catalog.json` preserves custom IDs across reloads. Duplicate filenames receive
a numbered suffix, and missing files keep their slots so other selections do not shift.
Custom entries appear in every tick dropdown alongside the built-in enum choices.

## Layout

- `src/initialization.as` exposes the Openplanet lifecycle callbacks.
- `src/app/` owns application state, settings, and UI composition.
- `src/countdown/` contains the detector, state machine, centered overlay, preview, and settings.
- `src/toolkit/` contains shared utility and logging helpers.
- `dev/` contains ignored development-only diagnostics; it is loaded from the source folder but excluded from packaged builds.

## Build

```powershell
python _build.py
