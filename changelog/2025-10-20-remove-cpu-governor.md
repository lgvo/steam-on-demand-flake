# Remove CPU Governor Switching

**Date:** 2025-10-20

## Summary

Removed automatic CPU governor switching in favor of recommending the `schedutil` governor for intelligent automatic performance scaling.

## Changes

- **Removed**: `optimize.cpuGovernor` option from `modules/optimization/system.nix`
- **Removed**: `setGovernorScript` and associated systemd service hooks (`ExecStartPre`, `ExecStopPost`)
- **Removed**: Security-related directives that were attempting to grant CPU frequency access (`CapabilityBoundingSet`, `AmbientCapabilities`, `ReadWritePaths`, `PrivateDevices`, `ProtectSystem`, `ProtectHome`)
- **Removed**: `cpupower` package from `environment.systemPackages`
- **Updated**: README.md System optimization section to recommend `schedutil` governor

## Breaking Changes

### Configuration Change

**Before:**
```nix
services.steam-on-demand.optimize.cpuGovernor = true;  # Manual switching
```

**After:**
```nix
# Recommended global configuration:
powerManagement.cpuFreqGovernor = "schedutil";  # Automatic scaling
```

## Migration Guide

Users who had `cpuGovernor = true` (or used the default) should add this to their NixOS configuration:

```nix
powerManagement.cpuFreqGovernor = "schedutil";
```

This provides better automatic performance scaling without requiring manual service hooks.

## Rationale

1. **Simpler implementation**: No need for privileged service hooks or security workarounds
2. **Better performance**: `schedutil` intelligently scales based on CPU scheduler utilization, responding faster to load changes than manual switching
3. **Eliminates permission issues**: Previous implementation had systemd security conflicts (service ran as non-root user but needed root to write to `/sys/devices/system/cpu/*/cpufreq/scaling_governor`)
4. **Modern approach**: `schedutil` is the recommended governor for modern kernels (default on most distributions)
5. **No manual switching needed**: The governor automatically boosts to maximum performance during gaming and scales down when idle

## Technical Details

The previous implementation attempted to use systemd service hooks with capabilities to switch governors, but failed because:
- The service runs as a non-root user (`cfg.user`)
- `ExecStartPre`/`ExecStopPost` inherit the service user context by default
- Security directives (`PrivateDevices`, `ProtectSystem`) blocked sysfs access
- Capabilities (`CAP_SYS_ADMIN`) don't grant sysfs write access to unprivileged users

While this could be fixed using the `+` prefix to run hooks as root, the `schedutil` governor provides superior automatic performance scaling without requiring any manual intervention.

## Validation

✅ `just validate` - All checks passed
✅ `statix check .` - No linting issues  
✅ `nix flake check` - Module evaluation successful
✅ `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

- `modules/optimization/system.nix` - Removed cpuGovernor option and implementation
- `README.md` - Replaced CPU governor switching docs with schedutil recommendation
- `changelog/2025-10-20-remove-cpu-governor.md` - This changelog
