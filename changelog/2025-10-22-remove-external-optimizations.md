# Remove External Optimizations and Simplify to Core Functionality

**Date**: 2025-10-22

## Summary

Removed all external optimization features (kernel, scheduler, audio, bleeding-edge packages) to focus the module on its core purpose: Steam on-demand with controller activation and essential GPU configuration. Moved GPU configuration from `optimize.gpu` to top-level `gpu` namespace.

## Changes

### Modules Removed

**`modules/optimization/kernel.nix`**:
- Removed kernel selection options (zen, xanmod, cachyos)
- Removed `optimize.kernel` option

**`modules/optimization/scheduler.nix`**:
- Removed sched-ext scheduler options (scx_rusty, scx_rustland, scx_lavd)
- Removed `optimize.scheduler` option

**Directory Structure**:
- Removed `modules/optimization/` directory entirely
- Moved `modules/optimization/gpu.nix` → `modules/gpu.nix`

### Namespace Changes

**GPU Configuration** (BREAKING):
```nix
# Before
services.steam-on-demand.optimize.gpu = {
  vendor = "amd";
  generation = "rdna3";
};

# After
services.steam-on-demand.gpu = {
  vendor = "amd";
  generation = "rdna3";
};
```

### Options Removed

All removed options were external optimizations that added complexity and external dependencies:

- `optimize.lowLatencyAudio` - Required nix-gaming input
- `optimize.kernel` - Kernel variant selection
- `optimize.scheduler` - sched-ext scheduler selection
- `optimize.bleedingEdge.enable` - Required chaotic-nyx input
- `optimize.bleedingEdge.graphics` - mesa_git, gamescope_git
- `optimize.bleedingEdge.hdr` - HDR support
- `optimize` namespace entirely - Replaced with direct `gpu` namespace

### Options Retained (Renamed)

- `gpu.vendor` (formerly `optimize.gpu.vendor`)
- `gpu.generation` (formerly `optimize.gpu.generation`)

These are **essential** GPU configurations, not optimizations:
- AMD: RADV driver forcing, VRS fixes, environment variables
- Nvidia: Open driver selection for RTX 30/40/50, power management
- Assertions: Mesa version checks for RDNA4, driver requirements for RTX 50

### Module Changes

**`modules/default.nix`**:
```nix
# Before
imports = [
  ./core.nix
  ./activation.nix
  ./optimization/gpu.nix
  ./optimization/kernel.nix
  ./optimization/scheduler.nix
];

# After
imports = [
  ./core.nix
  ./activation.nix
  ./gpu.nix
];
```

**`modules/gpu.nix`**:
- Changed option path: `services.steam-on-demand.optimize.gpu` → `services.steam-on-demand.gpu`
- No functional changes to GPU configuration logic
- Retained all AMD/Nvidia generation-specific settings

### Documentation Changes

**README.md**:
- Removed "With Optimizations" Quick Start example
- Removed sections:
  - Audio (lowLatencyAudio)
  - Kernel (zen/xanmod/cachyos)
  - Scheduler (scx_rusty/scx_rustland/scx_lavd)
  - CPU Governor (external optimization advice)
  - Bleeding-Edge Features
  - Dependency Matrix
- Simplified Quick Start to single example with nixpkgs only
- Updated all `optimize.gpu` → `gpu` references
- Removed references to nix-gaming and chaotic-nyx inputs
- Updated Credits section to remove external optimization sources
- Updated Project Status to reflect simplified scope

## Rationale

### Why Remove External Optimizations?

**Focus on Core Purpose**:
- This module's primary value: **Steam on-demand + Controller activation + Essential GPU config**
- External optimizations (kernels, schedulers, audio) are:
  - User preference, not module requirements
  - Better configured at system level
  - Add maintenance burden
  - Introduce external dependencies (nix-gaming, chaotic-nyx)

**Reduce Complexity**:
- 3 fewer module files
- No external flake dependencies required
- Simpler configuration API
- Less documentation to maintain
- Clearer scope and purpose

**GPU Config is Essential, Not Optional**:
- AMD: Force RADV driver, fix VRS artifacts (RDNA3)
- Nvidia: Open driver required for RTX 30/40/50, power management
- These are **requirements** for proper Steam gaming, not optimizations
- Moving to `gpu` namespace reflects this

### What Users Should Do Instead

**Kernel Selection**:
```nix
# System-level kernel configuration
boot.kernelPackages = pkgs.linuxPackages_zen;
```

**Scheduler Selection**:
```nix
# System-level scheduler configuration
services.scx.enable = true;
services.scx.scheduler = "scx_rusty";
```

**Audio Optimization**:
```nix
# System-level PipeWire configuration
services.pipewire.extraConfig.pipewire."92-low-latency" = {
  "context.properties" = {
    "default.clock.rate" = 48000;
    "default.clock.quantum" = 64;
  };
};
```

**Bleeding-Edge Packages**:
```nix
# Use chaotic-nyx directly for bleeding-edge packages
programs.steam.package = pkgs.steam_git;
```

## Breaking Changes

### Configuration Migration Required

**GPU Namespace Change**:
```nix
# Before
services.steam-on-demand = {
  enable = true;
  optimize.gpu = {
    vendor = "amd";
    generation = "rdna3";
  };
};

# After
services.steam-on-demand = {
  enable = true;
  gpu = {
    vendor = "amd";
    generation = "rdna3";
  };
};
```

**Removed Options** - No direct replacement (configure at system level):
- `optimize.lowLatencyAudio` → Use `services.pipewire` configuration
- `optimize.kernel` → Use `boot.kernelPackages`
- `optimize.scheduler` → Use `services.scx`
- `optimize.bleedingEdge.*` → Use chaotic-nyx packages directly

**External Dependencies No Longer Required**:
```nix
# Before
inputs = {
  steam-on-demand.url = "...";
  nix-gaming.url = "...";          # No longer needed
  chaotic-nyx.url = "...";         # No longer needed
};

# After
inputs = {
  steam-on-demand.url = "...";     # Only this needed
};
```

## Validation

✅ `just validate` - All checks pass:
- `statix check .` - No linting errors
- `nix flake check` - Flake evaluation successful
- `nix eval '.#nixosModules.default'` - Module valid

## Files Modified

- `modules/default.nix` - Updated imports
- `modules/gpu.nix` - Moved from modules/optimization/, changed namespace
- `README.md` - Removed external optimization documentation

## Files Deleted

- `modules/optimization/kernel.nix`
- `modules/optimization/scheduler.nix`
- `modules/optimization/` directory

## Files Created

- `changelog/2025-10-22-remove-external-optimizations.md`

## Migration Example

### Before (Full Configuration)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    steam-on-demand.url = "github:yourname/steam-on-demand";
    nix-gaming.url = "github:fufexan/nix-gaming";
    chaotic-nyx.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };
  
  outputs = { nixpkgs, steam-on-demand, ... }: {
    nixosConfigurations.gaming = nixpkgs.lib.nixosSystem {
      modules = [
        steam-on-demand.nixosModules.default
        {
          services.steam-on-demand = {
            enable = true;
            optimize = {
              lowLatencyAudio = true;
              kernel = "cachyos";
              scheduler = "scx_rusty";
              gpu = {
                vendor = "amd";
                generation = "rdna3";
              };
              bleedingEdge = {
                enable = true;
                graphics = true;
              };
            };
          };
        }
      ];
    };
  };
}
```

### After (Equivalent Configuration)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    steam-on-demand.url = "github:yourname/steam-on-demand";
    chaotic-nyx.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";  # Optional, if you want cachyos/scx
  };
  
  outputs = { nixpkgs, steam-on-demand, ... }: {
    nixosConfigurations.gaming = nixpkgs.lib.nixosSystem {
      modules = [
        steam-on-demand.nixosModules.default
        {
          # Steam on-demand with GPU config
          services.steam-on-demand = {
            enable = true;
            gpu = {
              vendor = "amd";
              generation = "rdna3";
            };
          };
          
          # System-level optimizations (optional)
          boot.kernelPackages = pkgs.linuxPackages_cachyos;
          
          services.scx = {
            enable = true;
            scheduler = "scx_rusty";
          };
          
          services.pipewire.extraConfig.pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 64;
            };
          };
          
          programs.steam.package = pkgs.steam_git;  # Bleeding-edge if desired
        }
      ];
    };
  };
}
```

**Key differences**:
1. `optimize.gpu` → `gpu` (required change)
2. External optimizations moved to system-level configuration
3. More explicit control over each optimization
4. Clearer separation of concerns
