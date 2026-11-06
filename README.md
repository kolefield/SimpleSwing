# Simple Swing

A minimal, text-free swing timer for **WoW: Forever**. One flat bar, with no numbers, icons, border, or spark.

## Features

- Move the bar in the game's **Edit Mode**.
- Set width, height, primary color, background color, and opacity in Edit Mode.
- Automatically switch between ranged, main-hand, and off-hand swings based on the last weapon used. Hunters use Automatic by default.
- Optionally lock the bar to Ranged / Auto Shot, Main Hand, or Off Hand.
- Hide outside combat, with a preview while editing.
- Save settings per character and Edit Mode layout.

## Install

Download the addon ZIP from [Releases](https://github.com/kolefield/SimpleSwing/releases), then extract its `SimpleSwing` folder into your Forever client's `Interface/AddOns` folder. `SimpleSwing.toc` should be directly inside that folder. Enable **Simple Swing** in the AddOns list.

If newly installed while the game is running, restart the game when convenient. Updating an already installed copy normally requires only `/reload`.

This addon targets Forever's interface version **16001**. Other WoW editions are not supported.

## Customize

Open **Escape > Edit Mode**, select **Simple Swing**, and drag it into position. Its panel provides width (40–1000), height (2–100), both colors with opacity, and attack selection. Width and height also accept typed values.

The preview stays 65% full. Settings save immediately, independently of Blizzard's Save/Revert buttons. Settings follow local layout copies and renames, but are not included in Blizzard's exported layout strings.

## Timing

The bar empties on Forever's native `PLAYER_SWING(duration, swingType)` event, fills over the reported duration, and stays full until the next swing. Automatic mode shows the most recently used weapon, rather than multiple simultaneous timers.

The bar does not predict unreported movement/cast delays, mid-cycle haste changes, or parry haste. After loading or changing weapons, the next swing synchronizes it. Existing Blizzard bars and other addons are not changed.

## Development

The addon lives in `SimpleSwing/`. Run `npm ci` and `npm test` with Node.js to compile all Lua files, validate addon file references, and execute 119 mocked behavior checks. The author has also confirmed the ranged-timer fix in game; broader client/addon combinations remain unverified.

Run `pwsh -File scripts/package.ps1` to build the installable ZIP in `dist/`.

## License and credits

Original Simple Swing code is MIT licensed. The bundled, unmodified **LibEditMode** by Adrian L Lange has its own license in `SimpleSwing/Libs/LibEditMode/LICENSE.txt`; the MIT license does not replace it.

LibEditMode source: https://github.com/p3lim-wow/LibEditMode at commit `b4816be444fec1160eac31d9a841f74636898acc`.
