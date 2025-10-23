# Boot to Big Picture Option

**Date**: 2025-10-22

## Summary

Added `bootToBigPicture` option to control whether the system boots directly to Steam Big Picture mode or waits for controller activation. By default, the system boots to `multi-user.target` and only starts the display manager when a controller is connected.

## Changes

### New Options

**`services.steam-on-demand.bootToBigPicture`**:
- Type: `bool`
- Default: `false`
- Description: Automatically start Steam Big Picture mode at boot
- When `true`: System boots to `graphical.target` with automatic Steam session
- When `false`: System boots to `multi-user.target`, waits for controller activation

### Module Changes

**`modules/core.nix`**:
- Added `bootToBigPicture` option definition
- Added conditional `systemd.defaultUnit` based on `bootToBigPicture` setting
- Uses `mkForce` to override display manager's default target

## Configuration Examples

### On-Demand Mode (Default)

```nix
{
  services.steam-on-demand = {
    enable = true;
    bootToBigPicture = false;  # Default, can be omitted
  };
}
```

**Behavior**:
1. System boots to `multi-user.target` (no graphical session)
2. User connects a controller
3. Udev rule triggers `display-manager.service`
4. Display manager starts, autologin occurs, Steam session launches

### Auto-Start Mode

```nix
{
  services.steam-on-demand = {
    enable = true;
    bootToBigPicture = true;
  };
}
```

**Behavior**:
1. System boots to `graphical.target`
2. Display manager starts automatically
3. Gamer user autologin occurs
4. Steam Big Picture mode starts immediately
5. Controller activation still works as trigger

## Rationale

### Why This Change?

With the display manager refactor, the system now uses SDDM with autologin. By default, NixOS boots to `graphical.target` when a display manager is enabled, which means the system would automatically start the display manager and log in the gamer user at every boot.

This behavior conflicts with the on-demand nature of this module. However, some users may want the convenience of booting directly to Big Picture mode (e.g., dedicated gaming systems, media center PCs).

The `bootToBigPicture` option provides flexibility:
- **Default (`false`)**: Maintains on-demand behavior, preserves resources, waits for controller
- **Enabled (`true`)**: Boots directly to Steam, useful for dedicated gaming systems

## Validation

✅ `just validate` - All checks pass:
- `statix check .` - No linting errors
- `nix flake check` - Flake evaluation successful
- `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

- `modules/core.nix` - Added default target configuration

## Files Created

- `changelog/2025-10-22-boot-to-big-picture.md`
