SIMPLE SWING 1.1.0 — WoW: Forever

Flat, text-free swing bars. No icons, numbers, border, or spark.

1.1.0 adds independent stacked melee timers: main hand above off hand.
It also cleans up floating-point noise in the Edit Mode coordinate fields.

INSTALL
Place the SimpleSwing folder inside the live Forever client's Interface\AddOns
folder. Its SimpleSwing.toc must sit directly inside that folder, not inside a
second nested SimpleSwing folder. Enable "Simple Swing" in the AddOns list.
If it does not appear while the game is already running, fully exit and restart
WoW when convenient. No external addon dependencies are needed.

EDIT IN GAME
Press Escape > Edit Mode. Find the cyan bar below the center of the screen.
Click its "Simple Swing" selection, then drag it wherever you want.
The attached Edit Mode panel contains:
  Width: 40–1000 UI units (default 240).
  Height: 2–100 UI units (default 12), total height of both rows and their gap.
  Primary Color: fill color, including opacity.
  Background Color: background color, including opacity.
  Attack: Automatic (melee / ranged), Ranged / Auto Shot, or Melee.
The width and height controls also accept a typed value.
In Edit Mode the primary bar stays 65% full, and the off-hand bar 40% full.
Both rows move together and share the width and color settings.
Coordinates round to two decimal places; tiny near-zero errors display as 0.
The selection label is only an Edit Mode control; the gameplay bar has no text.
Use Reset to Default / Reset Position in this panel to restore the defaults.

Settings apply and save immediately, independently of Blizzard's Save/Revert
buttons. Close Edit Mode when finished. Settings are local to this character
and Edit Mode layout, persist through reloads, and follow layout copies/renames.
They are not embedded in Blizzard's exported layout strings or synced to servers.

HUNTER BEHAVIOR
Automatic is the default for hunters. The latest PLAYER_SWING event selects
the ranged or melee display. Ranged attacks use one bar. Melee shows main hand
on top and off hand below when dual wielding; single-weapon melee uses one bar.
Each hand has an independent timer and never resets the other hand's progress.
Each bar fills over its reported duration and holds full until its next swing.
Moving closer, changing targets, and casting an instant ability do not themselves
switch the bar. The bar always keeps your chosen primary/background colors.
Other classes default to Melee, with Automatic available. Existing Main Hand
and Off Hand settings migrate to Melee without resetting position or colors.

TIMING
Uses Forever's native PLAYER_SWING(duration, swingType) event rather than the
restricted combat log. This follows the game's reported cycle; it does not
predict unreported movement/cast delays, mid-cycle haste changes, or parry haste.
After loading or changing weapons, the next real swing synchronizes the bar.
The bar is hidden outside combat, except while adjusting it in Edit Mode.
In combat it holds full when ready. It is click-through outside Edit Mode.
Existing Blizzard swing bars and other addons are not modified or disabled.

VALIDATION
Lua syntax, addon file references, and automated mocked behavior checks passed.
174 mocked behavior checks pass, including the actual coordinate widget.
The earlier ranged fix was confirmed in game. The new stacked display and
coordinate fix still need in-game confirmation.

THIRD-PARTY COMPONENT
LibEditMode by Adrian L Lange is bundled unmodified with its license under Libs.
Source: https://github.com/p3lim-wow/LibEditMode
Pinned commit: b4816be444fec1160eac31d9a841f74636898acc
No separate library installation is needed.

API reference:
https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_SwingTimer

REMOVE
Close WoW when convenient, then remove only the SimpleSwing addon folder.
Other addons, your game settings, and existing UI layouts are not changed.
