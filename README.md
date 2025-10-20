# steam-on-demand

Declarative, isolated, and optimized Steam gaming on NixOS with controller-activated systemd service.

## Features

- **Isolated environment** - Dedicated user isolation with configurable home directory
- **Controller activation** - Auto-start/stop Steam via udev when controllers connect
- **Generation-aware GPU optimization** - Automatic settings based on GPU vendor/generation
- **Declarative optimization** - Kernel, scheduler, audio, graphics configurable via Nix
- **Bleeding-edge support** - Optional integration with nix-gaming and Chaotic-Nyx
- **Proton package management** - Declarative Proton version control via extraProtonPackages
- **Per-game overrides** - Fine-grained configuration for specific titles
- **Automatic power management** - GPU performance mode during gaming, restored on exit

## Quick Start

### Minimal Setup (nixpkgs only)

```nix
{
  inputs.steam-on-demand.url = "github:yourname/steam-on-demand";
  
  outputs = { nixpkgs, steam-on-demand, ... }: {
    nixosConfigurations.gaming = nixpkgs.lib.nixosSystem {
      modules = [
        steam-on-demand.nixosModules.default
        {
          services.steam-on-demand = {
            enable = true;
            optimize.gpu = {
              vendor = "amd";
              generation = "rdna3";
            };
          };
        }
      ];
    };
  };
}
```

### With Optimizations

```nix
{
  inputs = {
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
                hdr = true;
              };
            };
          };
        }
      ];
    };
  };
}
```

## Configuration Reference

### Core Options

```nix
services.steam-on-demand = {
  enable = false;                    # Enable module
  user = "games";                    # Dedicated isolation user
  directory = ".local/share/steam-games";  # Relative to /home/games/
};
```

### Controller Activation

```nix
activation = {
  controllers = [                    # Controller names triggering service
    "Xbox Wireless Controller"
    "Wireless Controller"            # PlayStation
    "Steam Deck Controller"
  ];
  stopOnDisconnect = false;          # Stop service on disconnect
};
```

**Finding controller names:**
```bash
# Connect controller, then:
udevadm monitor --subsystem-match=input --property | grep 'NAME='
```

### Remote Play

```nix
remotePlay = {
  enable = false;                    # Enable Steam Remote Play
  openFirewall = true;               # Open required ports
};
```

### Optimization Options

#### Audio

```nix
optimize.lowLatencyAudio = false;    # Default: false
# Requires: nix-gaming input
# Effect: 1.33ms audio latency (quantum=64, rate=48000)
# Use case: Rhythm games, competitive FPS
```

#### Kernel

```nix
optimize.kernel = "standard";        # Default: "standard"
# Options:
#   "standard" - nixpkgs default
#   "zen"      - 1000Hz timer, TkG scheduler, gaming patches
#   "xanmod"   - PREEMPT_RT, BBRv3 TCP
#   "cachyos"  - BORE scheduler, sched-ext, LTO (requires chaotic-nyx)
```

#### Scheduler

```nix
optimize.scheduler = null;           # Default: null
# Requires: chaotic-nyx + kernel 6.12+
# Options:
#   null           - Kernel default (EEVDF on 6.11+)
#   "scx_rusty"    - Rust-based, balanced
#   "scx_rustland" - Alternative Rust scheduler
#   "scx_lavd"     - Low-latency desktop/gaming
```

#### CPU Core Pinning

```nix
optimize.cpuCores = null;            # Default: null
# Examples:
#   null                 - No pinning
#   [ 0 1 2 3 4 5 6 7 ]  - Pin to specific cores
#
# Intel 14700K P-cores (0-15): [ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ]
# AMD 7950X3D CCD0 (0-7):      [ 0 1 2 3 4 5 6 7 ]
#
# Find your topology: lscpu -e
```

#### GPU Configuration

```nix
optimize.gpu = {
  vendor = "amd";                    # "amd" | "nvidia" | "intel"
  generation = "rdna3";              # See generation table below
};
```

**AMD Generations:**
- `rdna2` - RX 6000 series
- `rdna3` - RX 7000 series  
- `rdna4` - RX 9000 series

**Nvidia Generations:**
- `rtx20` - RTX 20 series (Turing)
- `rtx30` - RTX 30 series (Ampere)
- `rtx40` - RTX 40 series (Ada)
- `rtx50` - RTX 50 series (Blackwell)

**Auto-applied optimizations by generation:**

| Generation | Driver | Optimizations |
|------------|--------|---------------|
| RDNA2 | RADV | Force RADV, VRS recommended |
| RDNA3 | RADV | Force RADV, VRS artifact fix |
| RDNA4 | RADV | Force RADV, Mesa 25.1+ required |
| RTX 20 | Proprietary | Manual power management |
| RTX 30 | Open | Auto RTD3, threaded optimization |
| RTX 40 | Open | Auto RTD3, threaded optimization |
| RTX 50 | Open (required) | Driver 570+ required |

#### System

```nix
optimize.gameMode = true;            # Default: true
# Effect: Auto CPU governor switching, process priority boost
```

#### Bleeding-Edge Features

```nix
optimize.bleedingEdge = {
  enable = false;                    # Default: false
  graphics = true;                   # mesa_git, gamescope_git daily builds
  hdr = false;                       # HDR support (requires graphics = true)
};
# Requires: chaotic-nyx input
# HDR requirements: AMD GPU + kernel 6.8+ + HDR display
```

#### Proton Packages

```nix
extraProtonPackages = [];            # Default: []

# Example: Install Proton-GE from nix-gaming
extraProtonPackages = [
  nix-gaming.packages.x86_64-linux.proton-ge
];
```

Packages are automatically symlinked to `compatibilitytools.d` on service start.

### Per-Game Configuration

```nix
games."Game Name" = {
  proton.version = pkgs.proton-ge-9-20;
  
  environment = {
    RADV_PERFTEST = "nggc";
    DXVK_ASYNC = "1";
  };
  
  gamescope = {
    enable = true;
    args = "-w 1920 -h 1080 -W 2560 -H 1440 -F fsr --fsr-sharpness 2";
  };
};
```

## Dependency Matrix

| Feature | Required Input | Cache Available |
|---------|---------------|-----------------|
| Basic Steam | nixpkgs | ✓ |
| `kernel = "zen/xanmod"` | nixpkgs | ✓ |
| `lowLatencyAudio` | nix-gaming | ✓ |
| `kernel = "cachyos"` | chaotic-nyx | ✓ |
| `scheduler = "scx_*"` | chaotic-nyx | ✓ |
| `bleedingEdge.*` | chaotic-nyx | ✓ |

## How It Works

### Isolation

Steam runs as dedicated `games` user with:
- Isolated home directory (`/home/games/.local/share/steam-games/`)
- Systemd service with `User=games`, `PrivateTmp=true`
- FHS environment via `buildFHSUserEnv`

### Controller Activation

Udev rules trigger systemd service:
```bash
# Controller connects → systemctl start steam-on-demand
# Controller disconnects → optional systemctl stop steam-on-demand
```

### GPU Power Management

```bash
# On service start:
ExecStartPre: Save current GPU state → Set performance mode

# On service stop:
ExecStopPost: Restore previous GPU state
```

### Generation-Aware Optimization

GPU vendor + generation determines:
- Driver selection (Nvidia open vs proprietary)
- Environment variables (`AMD_VULKAN_ICD`, `RADV_DEBUG`)
- Required package versions (Mesa 25.1+ for RDNA4)
- Assertions (RTX 50 requires open driver)

## Project Status

**Stable:**
- Core isolation and systemd service
- Controller activation
- GPU power management
- Kernel/scheduler selection
- Per-game configuration

**Experimental:**
- HDR support (requires kernel 6.8+, HDR display)
- sched-ext schedulers (kernel 6.12+)
- RDNA4 support (Mesa 25.1+ maturing through 2025)

## License

MIT

## Credits

Built on excellent work from:
- [nixpkgs](https://github.com/NixOS/nixpkgs) - FHS Steam support
- [nix-gaming](https://github.com/fufexan/nix-gaming) - Low-latency audio, Wine optimization
- [Chaotic-Nyx](https://github.com/chaotic-cx/nyx) - Bleeding-edge packages
- [Jovian-NixOS](https://github.com/Jovian-Experiments/Jovian-NixOS) - Steam Deck inspiration
