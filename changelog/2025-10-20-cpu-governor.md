# Replace GameMode with CPU Governor Management

**Date:** 2025-10-20

## Summary

Replaced the GameMode-based CPU optimization with direct CPU governor management, eliminating the external GameMode dependency while maintaining automatic performance mode switching.

## Changes

- **Removed**: `optimize.gameMode` option
- **Removed**: `programs.gamemode.enable` configuration
- **Added**: `optimize.cpuGovernor` option (type: bool, default: true)
- **Added**: systemd service hooks for CPU governor control:
  - `ExecStartPre`: Sets all CPU cores to "performance" governor on service start
  - `ExecStopPost`: Restores all CPU cores to "powersave" governor on service stop
- **Implementation**: Used `pkgs.writeShellScript` for governor switching scripts

## Breaking Changes

### Configuration Change

**Before:**
```nix
services.steam-on-demand.optimize.gameMode = true;
```

**After:**
```nix
services.steam-on-demand.optimize.cpuGovernor = true;
```

## Migration Guide

Users with explicit `gameMode = false` settings should update to `cpuGovernor = false`. Users relying on the default `true` value need no action—CPU governor management is enabled by default.

## Rationale

1. **Reduced dependencies**: Eliminates GameMode package dependency
2. **Simpler implementation**: Direct sysfs writes via systemd hooks
3. **Maintained functionality**: CPU performance mode still auto-enabled during gaming
4. **Better integration**: Tightly coupled with steam-on-demand service lifecycle

## Validation

✅ `just validate` - All checks passed
✅ `statix check .` - No linting issues
✅ `nix flake check` - Module evaluation successful
✅ `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

- `modules/optimization/system.nix` - Replaced gameMode with cpuGovernor implementation
- `README.md` - Updated System optimization documentation
- `changelog/2025-10-20-cpu-governor.md` - This changelog
