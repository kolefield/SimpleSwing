SIMPLE SWING 1.0.2 — WoW: Forever

One flat, text-free swing bar. No icons, numbers, border, or spark.

1.0.2 fixes the timer snapping full on ordinary inventory/ammunition updates.
Only actual weapon-change and lifecycle events clear an active swing early.

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
  Height: 2–100 UI units (default 12).
  Primary Color: fill color, including opacity.
  Background Color: background color, including opacity.
  Attack: Automatic, Ranged / Auto Shot, Main Hand, or Off Hand.
The width and height controls also accept a typed value.
In Edit Mode the bar stays 65% full so both colors are visible.
The selection label is only an Edit Mode control; the gameplay bar has no text.
Use Reset to Default / Reset Position in this panel to restore the defaults.

Settings apply and save immediately, independently of Blizzard's Save/Revert
buttons. Close Edit Mode when finished. Settings are local to this character
and Edit Mode layout, persist through reloads, and follow layout copies/renames.
They are not embedded in Blizzard's exported layout strings or synced to servers.

HUNTER BEHAVIOR
Automatic is the default for hunters. The latest PLAYER_SWING event selects the
displayed weapon: ranged, main hand, or off hand. The bar empties on that event,
fills over the reported swing duration, then holds full until another swing.
Moving closer, changing targets, and casting an instant ability do not themselves
switch the bar. The bar always keeps your chosen primary/background colors.
Only the most recently used weapon is displayed; simultaneous weapon timers
are not shown. Other classes default to Main Hand, with Automatic available.

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
119 mocked behavior checks pass. The ranged-timer fix has also been confirmed in game. Broader client and addon combinations remain unverified.

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
