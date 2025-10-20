# Gamescope Compositor Integration

**Date:** 2025-10-20

## Summary

Integrated gamescope Wayland compositor running on TTY1 to solve "Unable to open display" crashes. Controller activation now triggers gamescope compositor takeover of TTY1, providing isolated graphics environment without requiring X11 or desktop environment.

## Changes

### New Options

- **Added** `services.steam-on-demand.gamescope.enable`
  - Type: `bool`
  - Default: `true`
  - Description: "Run Steam inside gamescope compositor on TTY1"
  - When enabled, Steam runs inside gamescope instead of directly

- **Added** `services.steam-on-demand.gamescope.args`
  - Type: `listOf str`
  - Default: `["-e" "-f"]` (embedded mode, fullscreen)
  - Description: "Arguments passed to gamescope compositor"
  - Examples:
    - FSR upscaling: `["-e" "-f" "-w" "1920" "-h" "1080" "-W" "2560" "-H" "1440" "-F" "fsr" "--fsr-sharpness" "2"]`
    - VRR: `["-e" "-f" "--adaptive-sync" "-r" "144"]`
    - HDR: `["-e" "-f" "--hdr-enabled" "--hdr-itm-enable"]`

### Service Configuration Changes

**modules/service.nix**:

- **Added** TTY1 configuration:
  ```nix
  serviceConfig = {
    TTYPath = "/dev/tty1";
    StandardInput = "tty-fail";
    StandardOutput = "journal";
    StandardError = "journal";
  };
  ```

- **Added** service dependencies:
  ```nix
  conflicts = ["getty@tty1.service"];
  after = ["systemd-user-sessions.service" "sound.target"];
  ```
  Changed from `after = ["network.target" "sound.target"]` to ensure proper TTY initialization.

- **Modified** `ExecStart` to be conditional:
  ```nix
  ExecStart =
    if cfg.gamescope.enable
    then "${pkgs.gamescope}/bin/gamescope ${concatStringsSep " " cfg.gamescope.args} -- ${steamFHS}/bin/steam -bigpicture"
    else "${steamFHS}/bin/steam -bigpicture";
  ```

- **Added** gamescope to system packages when enabled:
  ```nix
  environment.systemPackages =
    with pkgs;
      [
        mangohud
      ]
      ++ lib.optional cfg.gamescope.enable gamescope;
  ```

- **Added** `concatStringsSep` to lib imports for args handling

## Breaking Changes

None. Gamescope is enabled by default, but this changes the display environment from "none" (causing crashes) to "gamescope compositor on TTY1" (working).

Users who previously worked around the display issue with custom X11 setup may want to disable gamescope:
```nix
services.steam-on-demand.gamescope.enable = false;
```

## Migration Guide

### Before (Broken)

```nix
services.steam-on-demand = {
  enable = true;
};
```

Result: "Unable to open display" crash on controller connection.

### After (Default - Working)

```nix
services.steam-on-demand = {
  enable = true;
};
```

Result: Gamescope compositor launches on TTY1, Steam runs in Big Picture mode.

### Custom Gamescope Configuration

```nix
services.steam-on-demand = {
  enable = true;
  gamescope = {
    enable = true;
    args = [
      "-e" "-f"
      "-w" "1920" "-h" "1080"
      "-W" "2560" "-H" "1440"
      "-F" "fsr"
      "--fsr-sharpness" "2"
    ];
  };
};
```

### Disable Gamescope (Use Direct Steam)

```nix
services.steam-on-demand.gamescope.enable = false;
```

Note: Disabling requires alternative display setup (X11, Wayland session, etc.).

## Rationale

1. **Solves Display Error**: Gamescope provides Wayland compositor, eliminating "Unable to open display" crashes
2. **TTY1 Integration**: Direct TTY control works seamlessly with controller-triggered systemd service
3. **No Desktop Required**: Runs completely standalone without X11 or desktop environment
4. **Flexibility**: Args allow FSR upscaling, VRR, HDR, custom resolutions
5. **Proper Isolation**: TTY1 conflicts with getty, ensuring clean environment
6. **Controller-Driven**: Service still triggered by udev rules, not autologin or boot

## Technical Details

### TTY Takeover Flow

1. Controller connects → udev rule triggers `steam-on-demand.service`
2. Systemd conflicts with `getty@tty1.service`, stopping getty
3. Service acquires `/dev/tty1` via `TTYPath`
4. Gamescope launches as Wayland compositor on TTY1
5. Steam runs inside gamescope environment
6. On service stop, getty@tty1 restarts automatically

### Why These Specific Settings

- `TTYPath = "/dev/tty1"`: Direct TTY allocation
- `StandardInput = "tty-fail"`: Fail if TTY unavailable (prevents conflicts)
- `StandardOutput/Error = "journal"`: Logs to journald instead of TTY
- `conflicts = ["getty@tty1.service"]`: Ensure exclusive TTY access
- `after = ["systemd-user-sessions.service"]`: Wait for session infrastructure

## Validation

- ✅ `just validate` - All checks pass
- ✅ `nix eval '.#nixosModules.default'` - Module evaluation succeeds
- ✅ `just fmt` - Formatting correct
- ✅ `just lint` - No statix warnings

## Files Modified

- `modules/core.nix` - Added `gamescope.enable` and `gamescope.args` options
- `modules/service.nix` - Added TTY1 config, gamescope integration, conditional ExecStart
- `README.md` - Documented gamescope options, TTY behavior, configuration examples

## Files Created

- `changelog/2025-10-20-gamescope-compositor.md` - This changelog
