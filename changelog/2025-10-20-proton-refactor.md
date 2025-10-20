# Proton Configuration Refactor

**Date:** 2025-10-20

## Summary

Refactored Proton package management from imperative Proton-GE-specific approach to flexible declarative package list with automatic symlinking.

## Changes

### Breaking Changes

- **Removed** `services.steam-on-demand.optimize.protonGE` namespace entirely
  - Previously had: `enable`, `autoUpdate`, `pinned` options
  - These options are no longer available

### New Options

- **Added** `services.steam-on-demand.extraProtonPackages`
  - Type: `listOf package`
  - Default: `[]`
  - Description: "Additional Proton packages to install"
  - Example: `[ nix-gaming.packages.x86_64-linux.proton-ge ]`

### Implementation Changes

- **modules/optimization/proton.nix**:
  - Moved option from nested `optimize.protonGE` to top-level `extraProtonPackages`
  - Changed from `environment.systemPackages` installation to systemd `preStart` symlinking
  - Implemented automatic symlinking into `compatibilitytools.d`:
    ```nix
    compatDir="${homeDir}/${cfg.directory}/compatibilitytools.d"
    mkdir -p "$compatDir"
    ln -sf ${package} "$compatDir/$(basename ${package})"
    ```
  - Uses `concatMapStringsSep` to handle multiple packages
  - Service only activates when `cfg.extraProtonPackages != []`

## Migration Guide

### Before (Old Configuration)
```nix
services.steam-on-demand.optimize.protonGE = {
  enable = true;
  autoUpdate = true;
  pinned = {
    "Counter-Strike 2" = pkgs.proton-ge-bin;
  };
};
```

### After (New Configuration)
```nix
services.steam-on-demand.extraProtonPackages = [
  pkgs.proton-ge-bin
];
```

For per-game Proton pinning, use the existing `services.steam-on-demand.games.<name>.proton.version` option.

## Rationale

1. **Simplification**: Single list of packages is clearer than nested namespace
2. **Flexibility**: Not limited to Proton-GE; supports any Proton-compatible package
3. **Declarative**: Packages managed via Nix, symlinked at service start
4. **Integration**: Works seamlessly with nix-gaming and other Proton sources
5. **Reduced Complexity**: Removed imperative `autoUpdate` logic in favor of pure Nix management

## Validation

- ✅ `just validate` - All checks pass
- ✅ Module evaluation succeeds
- ✅ Flake check succeeds

## Files Modified

- `modules/optimization/proton.nix` - Complete rewrite of option structure and implementation
