# Simple Swing

A minimal, text-free swing timer for **WoW: Forever**. Flat bars with no numbers, icons, border, or spark.

## Features

- Move the bar in the game's **Edit Mode**.
- Set width, height, primary color, background color, and opacity in Edit Mode.
- Automatically switch between ranged and melee swings. Hunters use Automatic by default.
- When dual wielding, show two independent stacked timers: **main hand on top, off hand below**.
- Optionally lock the display to Ranged / Auto Shot or Melee. Old single-hand settings migrate to Melee.
- Hide outside combat, with a preview while editing.
- Save settings per character and Edit Mode layout.

## Install

Download the addon ZIP from [Releases](https://github.com/kolefield/SimpleSwing/releases), then extract its `SimpleSwing` folder into your Forever client's `Interface/AddOns` folder. `SimpleSwing.toc` should be directly inside that folder. Enable **Simple Swing** in the AddOns list.

If newly installed while the game is running, restart the game when convenient. Updating an already installed copy normally requires only `/reload`.

This addon targets Forever's interface version **16001**. Other WoW editions are not supported.

## Customize

Open **Escape > Edit Mode**, select **Simple Swing**, and drag it into position. Its panel provides width (40–1000), height (2–100), both colors with opacity, and attack selection. Width and height also accept typed values.

Height controls the total area of both stacked bars, including their small gap. Both rows share the width and color settings and move together. Ranged attacks and single-weapon melee use one bar filling that area. The off-hand row appears only with an off-hand weapon; a shield does not add a timer.

Edit Mode previews the primary bar at 65% and the off-hand bar at 40%. Coordinates display to two decimal places, with tiny rounding errors shown as zero. Settings save immediately, independently of Blizzard's Save/Revert buttons. Settings follow local layout copies and renames, but are not included in Blizzard's exported layout strings.

## Timing

Each bar empties on its weapon's native `PLAYER_SWING(duration, swingType)` event, fills over the reported duration, and stays full until that hand swings again. Main-hand and off-hand timers are independent. Automatic mode switches between the melee display and one ranged bar based on the latest attack.

The bar does not predict unreported movement/cast delays, mid-cycle haste changes, or parry haste. After loading or changing weapons, the next swing synchronizes it. Existing Blizzard bars and other addons are not changed.

## Development

The addon files live at the repository root. Run `npm ci` and `npm test` with Node.js to compile all Lua files, validate addon file references, and execute 174 mocked behavior checks, including the actual coordinate widget. The earlier ranged-timer fix was confirmed in game; the stacked display and coordinate fix still need in-game confirmation.

Run `pwsh -File scripts/package.ps1` to build the installable ZIP in `dist/`.

## Automatic publishing

Every push to `main` runs the addon checks in GitHub Actions, then automatically creates an annotated release tag. CurseForge project **1786390** packages those tags as **full releases**, not alpha builds. Failed checks prevent the release tag from being created.

Versions use `v<package version>.<workflow run number>`, for example `v1.0.2.1`. The packager writes the actual tag into the addon's version field. Update `package.json`, its lockfile, and `CHANGELOG.md` when changing the base version. Feature branches do not publish. Rerunning the same workflow reuses its release tag. CurseForge moderation still applies.

A private GitHub push webhook triggers CurseForge's packager; its credential is stored only in webhook settings, never in this repository. GitHub Actions uses its built-in repository token to push tags and does not receive the CurseForge credential.

`.pkgmeta` packages the addon as `SimpleSwing` and excludes development files. LibEditMode is vendored at the pinned revision, so builds do not fetch changing library versions.

See [CurseForge's automatic packaging guide](https://support.curseforge.com/support/solutions/articles/9000197281) for webhook administration.

## License and credits

Original Simple Swing code is MIT licensed. The bundled, unmodified **LibEditMode** by Adrian L Lange has its own license in `Libs/LibEditMode/LICENSE.txt`; the MIT license does not replace it.

LibEditMode source: https://github.com/p3lim-wow/LibEditMode at commit `b4816be444fec1160eac31d9a841f74636898acc`.
