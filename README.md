# steam-on-demand

Declarative, isolated, and optimized Steam gaming on NixOS with controller-activated display manager and gamescope session.

## Features

- **Isolated environment** - Dedicated user isolation with autologin
- **Controller activation** - Auto-start Steam session via udev when controllers connect
- **Display manager integration** - SDDM with Wayland and gamescope session
- **Generation-aware GPU optimization** - Automatic settings based on GPU vendor/generation
- **Declarative optimization** - Kernel, scheduler, audio, graphics configurable via Nix
- **Bleeding-edge support** - Optional integration with nix-gaming and Chaotic-Nyx
- **Compatibility tools** - Declarative Proton version control via extraCompatPackages

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
  user = "gamer";                    # Dedicated isolation user
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

**How it works:**
When a controller connects, udev triggers the display manager service which starts a gamescope session with the configured user automatically logged in.

**Finding controller names:**
```bash
# Connect controller, then:
udevadm monitor --subsystem-match=input --property | grep 'NAME='
```

### Gamescope Configuration

```nix
gamescope.args = ["-e" "-f"];        # Default: []
steam.args = [];                     # Default: []
```

**Common configurations:**

```nix
# FSR upscaling (1080p → 1440p)
gamescope.args = [
  "-e" "-f"
  "-w" "1920" "-h" "1080"            # Game resolution
  "-W" "2560" "-H" "1440"            # Output resolution
  "-F" "fsr"                         # FSR upscaling
  "--fsr-sharpness" "2"              # Sharpness level (0-20)
];

# VRR + framerate limit
gamescope.args = [
  "-e" "-f"
  "--adaptive-sync"                  # Enable VRR
  "-r" "144"                         # Framerate cap
];

# HDR (requires HDR display + kernel 6.8+)
gamescope.args = [
  "-e" "-f"
  "--hdr-enabled"
  "--hdr-itm-enable"
];

# Steam arguments (e.g., force Big Picture)
steam.args = ["-bigpicture"];
```

**Display manager:**
- Uses SDDM with Wayland
- Autologin enabled for gaming user
- Gamescope session runs as default session

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

#### CPU Governor

```nix
# Recommended: Use schedutil for automatic performance scaling
powerManagement.cpuFreqGovernor = "schedutil";
# Effect: Auto-scales CPU frequency based on scheduler utilization
# No manual switching needed - automatically boosts during gaming
```

**Governor options:**
- `schedutil` - Recommended: intelligent auto-scaling based on CPU load
- `ondemand` - Legacy auto-scaling, scales up quickly on demand
- `performance` - Always max frequency (high power usage)
- `powersave` - Always min frequency (poor gaming performance)

Find current governor: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`


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

#### Compatibility Tools

```nix
extraCompatPackages = [];            # Default: []

# Example: Install Proton-GE from nixpkgs
extraCompatPackages = with pkgs; [
  proton-ge-bin
];
```

Packages are automatically managed by `programs.steam.extraCompatPackages`.

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

Steam runs as dedicated `gamer` user with:
- Isolated home directory (`/home/gamer/`)
- Automatic login via display manager
- FHS environment via `programs.steam`

### Controller Activation

Udev rules trigger display manager:
```bash
# Controller connects → systemctl start display-manager
# SDDM starts with Wayland
# Gamer user automatically logs in
# Steam gamescope session starts as default session
# Controller disconnects → optional session termination
```

### Display Manager

- **SDDM**: Display manager with Wayland support
- **Autologin**: Gamer user logs in automatically
- **Default Session**: "steam" session via `programs.steam.gamescopeSession`
- **Gamescope**: Wayland compositor running Steam

### Generation-Aware Optimization

GPU vendor + generation determines:
- Driver selection (Nvidia open vs proprietary)
- Session environment variables (`AMD_VULKAN_ICD`, `RADV_DEBUG`)
- Required package versions (Mesa 25.1+ for RDNA4)
- Assertions (RTX 50 requires open driver)

## Project Status

**Stable:**
- Core isolation with display manager
- Controller activation
- SDDM + Wayland + gamescope session
- Kernel/scheduler selection

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
