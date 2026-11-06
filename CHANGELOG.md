# Changelog

## 1.1.0

- Show independent vertically stacked timers when dual wielding: main hand on top, off hand below.
- Replace separate Main Hand / Off Hand choices with Melee; migrate existing settings automatically.
- Keep Automatic switching between a single ranged bar and the combined melee display.
- Keep both rows in one movable Edit Mode area with shared size and color settings.
- Round saved and displayed coordinates to two decimal places, fixing tiny scientific-notation values after entering zero.
- Preserve the ammunition/inventory timer fix. The bundled LibEditMode files remain unchanged.

## 1.0.2

- Keep active swing timers running when ammunition or ordinary inventory updates occur.
- Reset on actual weapon changes using `WEAPON_SLOT_CHANGED`.

## 1.0.1

- Hide outside combat, except during Edit Mode.

## 1.0.0

- Initial text-free swing timer with native Edit Mode placement, sizing, and colors.
- Automatic switching between ranged and melee swings, with manual attack selection.
