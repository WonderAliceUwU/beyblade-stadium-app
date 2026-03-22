# Beyblade Stadium App

A stylized local Beyblade battle companion built with Flutter.

It currently includes a Metal Fight battle flow with animated bey selection, round intros, countdowns, finish calls, winner screens, music playback, voice clips, and keyboard shortcuts. The codebase is also now structured so a full Beyblade X presentation can be added on top of the same game logic without rebuilding the whole screen from scratch.

## Screenshot

![Beyblade Stadium gameplay screenshot](docs/images/screenshot-game.png)

## Features

- Metal Fight themed battle screen with custom fonts, music, finish calls, and motif effects
- Local 1v1 bey selection with lock-in flow for both players
- Round tracking, scoring, warning flow, and winner detection
- Configurable keyboard shortcuts for fast match control
- Series-based architecture so visuals, sounds, roster, and presenters can differ per series
- Asset-driven bey roster with support for per-bey overrides such as custom select/win voices or image scaling

## Controls

### Mouse / Touch

- Select a bey by scrolling or tapping
- Lock a bey by tapping the current selection
- Press `PLAY` once both players are locked
- Use the finish buttons during countdown/battle resolution

### Keyboard

These bindings are configurable in [lib/features/battle/domain/battle_series_config.dart](/Users/alice/Documents/Projects/beyblade-stadium-app/lib/features/battle/domain/battle_series_config.dart).

- `Space`: primary action in order `left lock -> right lock -> play`
- `Q`: left spin finish
- `A`: left over finish
- `P`: right spin finish
- `L`: right over finish
- `Z`: warning

## Running The App

### Requirements

- Flutter SDK
- A platform target supported by Flutter, such as macOS, iOS, Android, web, Linux, or Windows

### Start

```bash
flutter pub get
flutter run
```

## Assets

Game assets live under [assets/metal/](/Users/alice/Documents/Projects/beyblade-stadium-app/assets/metal).

This includes:

- bey images
- motif images
- round / finish / select / win sounds
- background music
- fonts
- opening video

When adding a new bey, the clean path is to update the series roster in [lib/features/battle/domain/battle_series_config.dart](/Users/alice/Documents/Projects/beyblade-stadium-app/lib/features/battle/domain/battle_series_config.dart). If a bey needs special handling, `BeyInfo` supports overrides for image asset, motif asset, type logo, voices, and display name.

## Beyblade X Readiness

The app is already set up for a separate Beyblade X implementation through `BattleSeriesConfig` and `BattleSeriesPresenter`.

That means X can eventually provide:

- its own roster
- its own audio pack
- its own fonts
- its own opening behavior
- its own battle screen and win screen visuals

while still reusing the same match flow, round handling, score rules, and winner logic.

## Status

Current focus:

- Metal Fight mode is playable
- Beyblade X mode is scaffolded architecturally, but still needs its own dedicated assets and presentation layer
