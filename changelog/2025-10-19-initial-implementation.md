# Initial Implementation

**Date:** 2025-10-19

## Summary

Implemented complete NixOS module for declarative, isolated, and optimized Steam gaming with controller-activated systemd service.

## Features Implemented

### Core Functionality

- **NixOS Module System**
  - Created `nixosModules.default` export in flake.nix
  - Modular architecture with separate concerns (core, service, activation, optimization, games)
  - Full integration with nixpkgs, nix-gaming, and chaotic-nyx inputs

- **Isolated Steam Environment**
  - Dedicated user account (`games` by default, configurable)
  - Configurable home directory (`.local/share/steam-games` by default)
  - systemd service with proper isolation (`PrivateTmp=true`)
  - FHS environment via Steam's buildFHSUserEnv

- **Controller Activation**
  - udev rules for automatic service start on controller connection
  - Support for Xbox, PlayStation, and Steam Deck controllers
  - Optional auto-stop on controller disconnect
  - Configurable controller name list

- **Remote Play Support**
  - Optional Steam Remote Play enablement
  - Automatic firewall port opening
  - Integrated with nixpkgs Steam module

### Optimization Features

#### GPU Configuration (`modules/optimization/gpu.nix`)
- Vendor detection: AMD, Nvidia, Intel
- Generation-aware optimization:
  - **AMD RDNA2**: Force RADV driver
  - **AMD RDNA3**: Force RADV + VRS artifact fix (`RADV_DEBUG=nonggc`)
  - **AMD RDNA4**: Force RADV with Mesa 25.1+ requirement assertion
  - **Nvidia RTX 20**: Manual power management
  - **Nvidia RTX 30/40**: Open driver, auto RTD3, threaded optimization
  - **Nvidia RTX 50**: Open driver (required), driver 570+ assertion
- Hardware graphics enablement
- Automatic environment variable injection per generation

#### Kernel Selection (`modules/optimization/kernel.nix`)
- **standard**: Default nixpkgs kernel
- **zen**: 1000Hz timer, TkG scheduler, gaming patches
- **xanmod**: PREEMPT_RT, BBRv3 TCP
- **cachyos**: BORE scheduler, sched-ext, LTO (requires chaotic-nyx)

#### Scheduler Support (`modules/optimization/scheduler.nix`)
- sched-ext integration (requires kernel 6.12+ and chaotic-nyx)
- **scx_rusty**: Rust-based balanced scheduler
- **scx_rustland**: Alternative Rust scheduler
- **scx_lavd**: Low-latency desktop/gaming scheduler
- Automatic services.scx configuration

#### System Optimization (`modules/optimization/system.nix`)
- **GameMode Integration**: Automatic CPU governor switching, process priority boost
- **CPU Core Pinning**: Configurable CPU affinity for Steam process
  - Useful for hybrid CPUs (Intel P/E cores, AMD X3D chiplets)
  - Example configurations for Intel 14700K, AMD 7950X3D

#### Proton-GE Management (`modules/optimization/proton.nix`)
- Hybrid declarative/imperative approach
- Optional automatic installation
- Per-game version pinning via `optimize.protonGE.pinned`
- User-managed auto-updates via Steam

### Per-Game Configuration (`modules/games.nix`)

- **Custom Environment Variables**: Per-game environment override
- **Proton Version Pinning**: Declarative Proton-GE version per title
- **Gamescope Integration**: 
  - Per-game gamescope enablement
  - Custom command-line arguments (resolution, FSR, upscaling)
  - Automatic gamescope package installation when used

## Module Structure

```
modules/
├── default.nix                  # Module entry point
├── core.nix                     # Core options and user management
├── service.nix                  # systemd service definition
├── activation.nix               # udev rules for controllers
├── games.nix                    # Per-game configuration
└── optimization/
    ├── gpu.nix                  # GPU vendor/generation detection
    ├── kernel.nix               # Kernel variant selection
    ├── scheduler.nix            # sched-ext scheduler support
    ├── system.nix               # GameMode and CPU pinning
    └── proton.nix               # Proton-GE management
```

## Configuration Options Added

### `services.steam-on-demand`
- `enable`: Enable the module
- `user`: Isolation user (default: "games")
- `directory`: Steam directory relative to home (default: ".local/share/steam-games")

### `services.steam-on-demand.activation`
- `controllers`: List of controller names (default: Xbox, PlayStation, Steam Deck)
- `stopOnDisconnect`: Auto-stop on disconnect (default: false)

### `services.steam-on-demand.remotePlay`
- `enable`: Enable Remote Play
- `openFirewall`: Open firewall ports (default: true)

### `services.steam-on-demand.optimize`
- `kernel`: Kernel variant ("standard", "zen", "xanmod", "cachyos")
- `scheduler`: sched-ext scheduler (null, "scx_rusty", "scx_rustland", "scx_lavd")
- `gameMode`: Enable GameMode (default: true)
- `cpuCores`: CPU core pinning (default: null)

### `services.steam-on-demand.optimize.gpu`
- `vendor`: GPU vendor ("amd", "nvidia", "intel")
- `generation`: GPU generation (rdna2/3/4, rtx20/30/40/50)

### `services.steam-on-demand.optimize.protonGE`
- `enable`: Enable Proton-GE (default: true)
- `autoUpdate`: User-managed updates (default: true)
- `pinned`: Per-game version pinning (default: {})

### `services.steam-on-demand.games.<name>`
- `proton.version`: Package for this game's Proton version
- `environment`: Environment variables
- `gamescope.enable`: Enable gamescope
- `gamescope.args`: Gamescope arguments

## Flake Integration

### Inputs Added
- `nix-gaming`: Low-latency audio, Wine optimization
- `chaotic-nyx`: CachyOS kernel, sched-ext schedulers, bleeding-edge packages

### Outputs
- `nixosModules.default`: Main NixOS module
- `devShells.aarch64-darwin.default`: Development environment with nil, alejandra, statix, deadnix

## Validation

All validations passing:
- ✅ `just lint` - statix checks pass
- ✅ `just check` - nix flake check succeeds
- ✅ `just verify-modules` - module evaluation succeeds
- ✅ `just fmt` - alejandra formatting applied

## Dependencies

### Required
- nixpkgs (nixos-unstable)

### Optional
- nix-gaming (for low-latency audio - future feature)
- chaotic-nyx (for CachyOS kernel, sched-ext schedulers)

## Known Limitations

### Not Yet Implemented
- GPU power management (ExecStartPre/ExecStopPost scripts)
- Low-latency audio integration (nix-gaming)
- Bleeding-edge graphics (mesa_git, gamescope_git)
- HDR support
- Stop-on-disconnect udev logic (partial implementation)

### Platform Support
- Module designed for NixOS (x86_64-linux, aarch64-linux)
- Dev environment configured for aarch64-darwin
- No runtime testing performed (requires NixOS environment)

## Testing Status

- ✅ Module syntax validation
- ✅ Nix evaluation
- ✅ Flake check passes
- ⚠️  Runtime testing pending (requires NixOS system)

## Next Steps

To complete the implementation as described in README:
1. Add GPU power management scripts (save/restore performance mode)
2. Implement low-latency audio via nix-gaming
3. Add bleeding-edge graphics options (chaotic-nyx mesa_git)
4. Implement HDR support detection and configuration
5. Add runtime integration tests
6. Create example configurations for common use cases

## Files Created

- `modules/default.nix`
- `modules/core.nix`
- `modules/service.nix`
- `modules/activation.nix`
- `modules/games.nix`
- `modules/optimization/gpu.nix`
- `modules/optimization/kernel.nix`
- `modules/optimization/scheduler.nix`
- `modules/optimization/system.nix`
- `modules/optimization/proton.nix`

## Files Modified

- `flake.nix` - Added nixosModules.default, nix-gaming and chaotic-nyx inputs
- `flake.lock` - Updated with new input dependencies
- `justfile` - Fixed verify-modules command to check nixosModules.default
