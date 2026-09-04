![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

# Round Starts In 3 2 1

A lightweight Trackmania Openplanet plugin project for a clear round-start countdown.

By default, each detected pre-start window is normalized to a clear `3 -> 0` scale; those values
are countdown steps rather than literal seconds. A setting can switch the overlay back to the real
remaining time in seconds.

## Layout

- `src/initialization.as` exposes the Openplanet lifecycle callbacks.
- `src/app/` owns application state, settings, and UI composition.
- `src/countdown/` contains the detector, state machine, centered overlay, preview, and settings.
- `src/toolkit/` contains shared utility and logging helpers.
- `dev/` contains ignored development-only diagnostics; it is loaded from the source folder but excluded from packaged builds.

## Build

```powershell
python _build.py
