# Gamescope Security Wrapper

**Date**: 2025-10-20

## Summary

Added security wrapper for gamescope with `cap_sys_nice` capability to fix bubblewrap sandbox errors.

## Changes

- Added `security.wrappers.gamescope` configuration with `cap_sys_nice+pie` capability (following Jovian-NixOS pattern)
- Updated `ExecStart` to use wrapper path `/run/wrappers/bin/gamescope` instead of direct package binary
- Wrapper only configured when `cfg.gamescope.enable` is true

## Breaking Changes

None. Existing configurations continue to work.

## Rationale

Gamescope's bubblewrap sandbox requires proper capabilities to run. The error "bwrap: Unexpected capabilities but not setuid, old file caps config?" indicated missing capability configuration. Following Jovian-NixOS implementation, the `cap_sys_nice` capability allows gamescope to:
- Set real-time scheduling priorities for better performance
- Run bubblewrap sandbox without setuid bit requirement

## Validation

- ✅ `just validate` passes
- ✅ Module evaluation succeeds
- ⚠️ Runtime testing requires NixOS environment

## Files Modified

- `modules/service.nix`: Added security wrapper configuration and updated ExecStart path

## Files Created

- `changelog/2025-10-20-gamescope-security-wrapper.md`
