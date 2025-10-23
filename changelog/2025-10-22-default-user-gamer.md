# Change Default User from "games" to "gamer"

**Date**: 2025-10-22

## Summary

Changed the default value of `services.steam-on-demand.user` from `"games"` to `"gamer"` for better semantic clarity.

## Changes

- **modules/core.nix**: Changed default user from `"games"` to `"gamer"`
- **README.md**: Updated documentation examples to reflect new default user

## Breaking Changes

None. This only changes the default value. Users who explicitly set `user = "games";` will continue to work without modification.

## Migration Guide

**Before:**
```nix
services.steam-on-demand = {
  enable = true;
  # Implicitly uses user = "games"
};
```

**After:**
```nix
services.steam-on-demand = {
  enable = true;
  # Now implicitly uses user = "gamer"
};
```

**To keep old behavior:**
```nix
services.steam-on-demand = {
  enable = true;
  user = "games";  # Explicitly set to old default
};
```

## Rationale

The username `"gamer"` is more intuitive and semantically clear than `"games"`:
- Matches the purpose of the user account (a gamer)
- More natural in documentation and examples
- Aligns with common naming conventions for user accounts

## Validation

- ✅ `just validate` (lint, check, verify-modules)
- ✅ Flake evaluation successful
- ✅ Module validation passed

## Files Modified

- `modules/core.nix` (line 15: default value)
- `README.md` (lines 92, 94, 325-327: documentation examples)
