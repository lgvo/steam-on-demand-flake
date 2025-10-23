# Display Manager Architecture Refactor

**Date**: 2025-10-22

## Summary

Complete architectural refactor replacing the custom systemd service on TTY1 with a display manager-based approach using SDDM, autologin, and `programs.steam.gamescopeSession`. This provides a more maintainable, standard approach to running Steam in an isolated gaming environment.

## Changes

### Core Architecture

**Replaced**:
- Custom systemd service (`steam-on-demand.service`) running on TTY1
- Direct gamescope invocation via `ExecStart`
- Manual TTY management (`TTYPath`, `TTYReset`, etc.)

**With**:
- SDDM display manager with Wayland support
- Automatic login to dedicated gaming user
- `programs.steam.gamescopeSession` for Steam session management
- Controller-based activation triggers display manager service

### Module Changes

**`modules/core.nix`** - Complete rewrite:
- Added `services.xserver.enable = true`
- Added `services.displayManager.sddm` configuration with Wayland
- Added `services.displayManager.autoLogin` for isolated user
- Added `services.displayManager.defaultSession = "steam"`
- Added `programs.steam.gamescopeSession` with configurable args
- Removed `directory` option (managed by programs.steam)
- Added `steam.args` option (default: `[]`)
- Changed `gamescope.args` default from `["-e" "-f" "-W" "1920" "-H" "1080"]` to `[]`
- Renamed `extraProtonPackages` to `extraCompatPackages` (matching Steam naming)
- Removed `gamescope.enable` option (always enabled via gamescopeSession)

**`modules/activation.nix`**:
- Updated udev rules to trigger `display-manager.service` instead of `steam-on-demand.service`
- Kept controller activation logic unchanged

**`modules/optimization/gpu.nix`**:
- Replaced `systemd.services.steam-on-demand.serviceConfig.Environment` with `environment.sessionVariables`
- AMD GPU environment variables now apply session-wide
- Removed unused `nvidiaEnv` function and `optionalAttrs` import
- Kept hardware configuration (nvidia, graphics) unchanged

**Deleted**:
- `modules/service.nix` - Custom systemd service no longer needed
- `modules/optimization/system.nix` - CPU affinity feature removed
- `modules/optimization/proton.nix` - Functionality moved to `core.nix` via `programs.steam.extraCompatPackages`

**`modules/default.nix`**:
- Removed imports: `./service.nix`, `./optimization/system.nix`, `./optimization/proton.nix`
- Kept: `./core.nix`, `./activation.nix`, `./games.nix`, optimization modules

### Option Changes

**Removed Options**:
- `services.steam-on-demand.directory` - Steam manages directories automatically
- `services.steam-on-demand.optimize.cpuCores` - CPU affinity feature removed
- `services.steam-on-demand.gamescope.enable` - Always enabled via gamescopeSession

**Renamed Options**:
- `extraProtonPackages` → `extraCompatPackages` (matches `programs.steam.extraCompatPackages`)

**New Options**:
- `services.steam-on-demand.steam.args` - Arguments passed to Steam (default: `[]`)

**Modified Options**:
- `services.steam-on-demand.gamescope.args` - Now defaults to `[]` instead of `["-e" "-f" "-W" "1920" "-H" "1080"]`

## Breaking Changes

### Configuration Migration Required

#### Option Renames
```nix
services.steam-on-demand = {
  extraProtonPackages = [...];
};
```

**After**:
```nix
services.steam-on-demand = {
  extraCompatPackages = [...];
};
```

#### Removed Options

**Directory Configuration** (no longer needed):
```nix
services.steam-on-demand = {
  directory = ".local/share/steam-games";
};
```

**CPU Affinity** (feature removed):
```nix
services.steam-on-demand = {
  optimize.cpuCores = [0 1 2 3 4 5 6 7];
};
```

**Gamescope Enable Flag** (always enabled):
```nix
services.steam-on-demand = {
  gamescope.enable = true;
};
```

#### Default Gamescope Args Changed

**Before** (implicit defaults):
```nix
services.steam-on-demand = {
  gamescope.args = ["-e" "-f" "-W" "1920" "-H" "1080"];
};
```

**After** (explicit required):
```nix
services.steam-on-demand = {
  gamescope.args = ["-e" "-f" "-W" "1920" "-H" "1080"];
};
```

If you want the previous defaults, you must now explicitly set them.

#### New Steam Args Option

Configure Steam arguments separately:
```nix
services.steam-on-demand = {
  steam.args = ["-bigpicture"];
  gamescope.args = ["-e" "-f"];
};
```

### Behavioral Changes

1. **Display Manager Required**: System now uses SDDM display manager instead of direct TTY access
2. **Autologin Enabled**: Gamer user automatically logs in (no manual login required)
3. **Session-Wide GPU Variables**: AMD GPU optimizations now apply to entire session, not just Steam service
4. **No Manual Power Management**: GPU power state management handled by display manager session lifecycle
5. **Controller Activation**: Now triggers display manager service instead of custom systemd service

## Rationale

### Why This Change?

**Maintainability**:
- Removes custom systemd service complexity (TTY management, manual gamescope invocation)
- Uses standard NixOS display manager infrastructure
- Leverages `programs.steam.gamescopeSession` maintained by nixpkgs

**Reliability**:
- Display manager handles session lifecycle, authentication, environment setup
- Gamescope compositor integration tested and maintained upstream
- Proper Wayland session management

**Simplicity**:
- Fewer custom modules (deleted 3 modules)
- GPU environment variables apply naturally at session level
- Proton packages managed by `programs.steam` directly

**Standard Approach**:
- Aligns with how other NixOS gaming setups work
- Uses established display manager patterns
- Better integration with system services

### Trade-offs

**Removed Features**:
- CPU core pinning (`optimize.cpuCores`) - Removed to reduce complexity. Can be re-added if needed via systemd user slices.
- Custom directory configuration - Steam manages its own directory structure via `programs.steam`

**Added Complexity**:
- Display manager dependency (SDDM)
- Autologin configuration

**Overall**: Significant reduction in custom code (~200 lines deleted) for more maintainable, standard approach.

## Validation

✅ `just validate` - All checks pass:
- `statix check .` - No linting errors
- `nix flake check` - Flake evaluation successful
- `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

### Modified
- `modules/core.nix` - Complete rewrite with display manager configuration
- `modules/activation.nix` - Updated udev target
- `modules/optimization/gpu.nix` - Session-wide environment variables
- `modules/default.nix` - Updated imports

### Deleted
- `modules/service.nix`
- `modules/optimization/system.nix`
- `modules/optimization/proton.nix`

### Created
- `changelog/2025-10-22-display-manager-refactor.md`

## Migration Guide

### Minimal Configuration (Before)

```nix
{
  services.steam-on-demand = {
    enable = true;
    optimize.gpu = {
      vendor = "amd";
      generation = "rdna3";
    };
  };
}
```

### Minimal Configuration (After)

```nix
{
  services.steam-on-demand = {
    enable = true;
    gamescope.args = ["-e" "-f"];
    optimize.gpu = {
      vendor = "amd";
      generation = "rdna3";
    };
  };
}
```

### Full Configuration (Before)

```nix
{
  services.steam-on-demand = {
    enable = true;
    user = "gamer";
    directory = ".local/share/steam-games";
    
    gamescope = {
      enable = true;
      args = ["-e" "-f" "-W" "2560" "-H" "1440"];
    };
    
    extraProtonPackages = [
      nix-gaming.packages.x86_64-linux.proton-ge
    ];
    
    optimize = {
      cpuCores = [0 1 2 3 4 5 6 7];
      gpu = {
        vendor = "amd";
        generation = "rdna3";
      };
    };
  };
}
```

### Full Configuration (After)

```nix
{
  services.steam-on-demand = {
    enable = true;
    user = "gamer";
    
    gamescope.args = ["-e" "-f" "-W" "2560" "-H" "1440"];
    steam.args = [];
    
    extraCompatPackages = [
      nix-gaming.packages.x86_64-linux.proton-ge
    ];
    
    optimize = {
      gpu = {
        vendor = "amd";
        generation = "rdna3";
      };
    };
  };
}
```

**Changes**:
- Remove `directory` option
- Remove `gamescope.enable = true` (always enabled)
- Remove `optimize.cpuCores` (feature removed)
- Rename `extraProtonPackages` → `extraCompatPackages`
- Optionally add `steam.args` for Steam-specific arguments

## Next Steps

- Update README.md with new architecture and configuration examples
- Update AGENTS.md if needed
- Consider re-adding CPU affinity via systemd user slices if requested
- Test on real hardware with controller activation
