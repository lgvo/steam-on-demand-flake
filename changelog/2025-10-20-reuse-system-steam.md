# Reuse System Steam Package

**Date:** 2025-10-20

## Summary

Modified service.nix to reuse the system's Steam package (config.programs.steam.package) instead of creating a separate Steam FHS environment, reducing duplication and ensuring consistency with system Steam configuration.

## Changes

- **Changed**: `steamFHS` definition now uses `config.programs.steam.package.override` instead of `pkgs.steam.override`
- **Removed**: `gamemode` from `extraPkgs` (already included in base Steam package)
- **Removed**: `gamemode` from `environment.systemPackages`
- **Retained**: `mangohud` in both `extraPkgs` and `environment.systemPackages` for overlay functionality

## Migration Guide

No user-facing configuration changes required. This is an internal implementation change that maintains the same functionality while reducing code duplication.

## Rationale

1. **Avoid duplication**: Leverages existing system Steam package configuration
2. **Consistency**: Ensures steam-on-demand uses the same base Steam as the system
3. **Simplified maintenance**: Removes need to manually track Steam dependencies
4. **Cleaner code**: Base Steam package already includes all required dependencies

## Validation

✅ `just validate` - All checks passed
✅ `statix check .` - No linting issues
✅ `nix flake check` - Module evaluation successful
✅ `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

- `modules/service.nix` - Changed steamFHS to reuse config.programs.steam.package
- `changelog/2025-10-20-reuse-system-steam.md` - This changelog
