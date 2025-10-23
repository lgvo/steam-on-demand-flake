# Security Module - Shutdown Interception

**Date**: 2025-10-23

## Summary

Added a new security module with flexible shutdown interception that allows granular control over power management actions from the gaming session. The module can either intercept shutdown/reboot signals to gracefully manage the display manager, or block specific actions with polkit.

## Changes

- **New Module**: Created `modules/security.nix` as a dedicated module for security-related configuration
- **New Namespace**: `services.steam-on-demand.security.shutdownInterception` with fine-grained control
- **Shutdown Monitor**: Systemd service that monitors D-Bus for power management signals and intercepts them
- **Dynamic Polkit Rules**: Automatically generated polkit rules based on which actions are set to "block"
- **Module Import**: Added security.nix to the module imports in `modules/default.nix`

## Configuration

```nix
services.steam-on-demand.security.shutdownInterception = {
  enable = true;  # Default: true

  onReboot = "restart-display-manager";  # Default: intercept and restart DM
  onPowerOff = "stop-display-manager";   # Default: intercept and stop DM
  onSuspend = "block";                    # Default: block with polkit
  onHibernate = "block";                  # Default: block with polkit
};
```

### Available Options Per Action

**onReboot:**
- `"restart-display-manager"` (default) - Intercept via D-Bus monitor and restart display-manager
- `"allow"` - Allow system reboot
- `"block"` - Block with polkit

**onPowerOff:**
- `"stop-display-manager"` (default) - Intercept via D-Bus monitor and stop display-manager
- `"allow"` - Allow system poweroff
- `"block"` - Block with polkit

**onSuspend / onHibernate:**
- `"block"` (default) - Block with polkit
- `"allow"` - Allow action

## Implementation Details

### D-Bus Monitor Service

When `onReboot` or `onPowerOff` is set to intercept, a systemd service `steam-shutdown-monitor` is created that:
- Monitors system D-Bus for `org.freedesktop.login1.Manager` method calls
- Detects `PowerOff` and `Reboot` signals
- Executes `systemctl stop display-manager` or `systemctl restart display-manager` accordingly
- Runs as part of display-manager.service lifecycle
- Auto-restarts if it crashes (Restart=always, RestartSec=5)

### Dynamic Polkit Rules

Polkit rules are generated only for actions set to "block":
- Rules check if `subject.user == "gamer"` (or configured user)
- Returns `polkit.Result.NO` for blocked actions
- No rules generated if nothing is set to "block"

### Service Dependencies

```nix
systemd.services.steam-shutdown-monitor = {
  partOf = [ "display-manager.service" ];
  after = [ "display-manager.service" ];
};

systemd.services.display-manager = {
  wants = [ "steam-shutdown-monitor.service" ];
};
```

## Rationale

Gaming sessions often expose power management options through the Steam interface or compositor shortcuts. This module provides flexible control:

1. **Graceful Session Management**: Intercept shutdown attempts and convert them to display-manager control
2. **System Availability**: Prevents gaming user from shutting down the entire system
3. **Administrative Control**: System administrators retain full power management through other users
4. **Flexibility**: Choose between blocking, allowing, or intercepting on a per-action basis
5. **Consistency**: Aligns with existing controller disconnect behavior (stops display-manager)

### Default Behavior Benefits

- Shutdown from Steam → stops display manager (system stays running)
- Reboot from Steam → restarts display manager (returns to login/gaming session)
- Suspend/Hibernate → blocked (typically not desired in dedicated gaming setups)

## Example Configurations

### Conservative (block everything)
```nix
shutdownInterception = {
  enable = true;
  onReboot = "block";
  onPowerOff = "block";
  onSuspend = "block";
  onHibernate = "block";
};
```

### Permissive (allow everything)
```nix
shutdownInterception = {
  enable = false;  # Or set all to "allow"
};
```

### Custom (intercept shutdown only, allow others)
```nix
shutdownInterception = {
  enable = true;
  onReboot = "allow";
  onPowerOff = "stop-display-manager";
  onSuspend = "allow";
  onHibernate = "allow";
};
```

## Validation

✅ `just validate` - All checks pass
✅ `just lint` - No statix warnings  
✅ `just check` - Flake evaluation successful
✅ Module structure follows existing patterns (gpu.nix, activation.nix)
✅ Conditional service creation (monitor only runs when needed)
✅ Dynamic polkit rule generation

## Files Modified

- `modules/security.nix` (complete rewrite)
