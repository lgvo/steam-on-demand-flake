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
            gpu = {
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

## Configuration Reference

### Core Options

```nix
services.steam-on-demand = {
  enable = false;                    # Enable module
  user = "gamer";                    # Dedicated isolation user
  bootToBigPicture = false;          # Boot directly to Steam Big Picture (default: false)
};
```

**Boot behavior:**
- `bootToBigPicture = false` (default): System boots to `multi-user.target`, Steam starts only when controller connects
- `bootToBigPicture = true`: System boots to `graphical.target`, Steam Big Picture starts automatically at boot

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
When a controller connects, udev triggers the display manager service which starts a gamescope session with the configured user automatically logged in. If `bootToBigPicture` is enabled, the display manager starts at boot instead of waiting for controller activation.

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

### GPU Configuration

```nix
gpu = {
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

### Compatibility Tools

```nix
extraCompatPackages = [];            # Default: []

# Example: Install Proton-GE from nixpkgs
extraCompatPackages = with pkgs; [
  proton-ge-bin
];
```

Packages are automatically managed by `programs.steam.extraCompatPackages`.

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
- **Boot Target**: `multi-user.target` by default (on-demand), `graphical.target` if `bootToBigPicture` enabled

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
- GPU-based configuration (AMD/Nvidia)

**Experimental:**
- RDNA4 support (Mesa 25.1+ maturing through 2025)

## License

MIT

## Credits

Built on excellent work from:
- [nixpkgs](https://github.com/NixOS/nixpkgs) - FHS Steam support, gamescope session
- [Jovian-NixOS](https://github.com/Jovian-Experiments/Jovian-NixOS) - Steam Deck inspiration
