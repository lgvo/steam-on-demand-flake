# Security Module - Power Management Prevention

**Date**: 2025-10-23

## Summary

Added a new security module that prevents the gaming user from performing system power management actions (poweroff, reboot, suspend, hibernate) from within the Steam session.

## Changes

- **New Module**: Created `modules/security.nix` as a dedicated module for security-related configuration
- **New Option**: Added `services.steam-on-demand.security.preventPowerManagement` (default: `true`)
- **Polkit Rules**: Implemented polkit rules to deny all power management actions for the gaming user
- **Module Import**: Added security.nix to the module imports in `modules/default.nix`

## Configuration

```nix
services.steam-on-demand = {
  enable = true;
  security = {
    preventPowerManagement = true;  # Default: true
  };
};
```

## Rationale

Gaming sessions often expose power management options through the Steam interface or compositor shortcuts. Preventing the gaming user from executing these actions:

1. Prevents accidental system shutdown while gaming
2. Ensures system availability for other services/users
3. Provides administrative control over when the system powers down
4. Maintains system stability in multi-user or server gaming scenarios

The polkit rules block all systemd-logind power management actions including:
- `org.freedesktop.login1.power-off`
- `org.freedesktop.login1.reboot`
- `org.freedesktop.login1.suspend`
- `org.freedesktop.login1.hibernate`
- All `-multiple-sessions` variants of the above

System administrators can still manage power state through other users or root access.

## Validation

✅ `just validate` - All checks pass
✅ `just lint` - No statix warnings
✅ `just check` - Flake evaluation successful
✅ Module structure follows existing patterns (gpu.nix, activation.nix)

## Files Created

- `modules/security.nix`

## Files Modified

- `modules/default.nix` (added security.nix import)
