# Add MESA_VK_DEVICE_SELECT Environment Variable

**Date**: 2025-10-22

## Summary

Added `MESA_VK_DEVICE_SELECT` environment variable for all GPU vendors to ensure the correct Vulkan device is selected in multi-GPU systems.

## Changes

- Added `MESA_VK_DEVICE_SELECT = "1002:*"` to all AMD RDNA generations (rdna2, rdna3, rdna4)
- Added `nvidiaEnv` with `MESA_VK_DEVICE_SELECT = "10de:*"` for Nvidia GPUs
- Added `intelEnv` with `MESA_VK_DEVICE_SELECT = "8086:*"` for Intel GPUs
- Updated `environment.sessionVariables` logic to apply vendor-specific variables for all GPU types

## Vendor PCI IDs

- AMD: `1002:*`
- Nvidia: `10de:*`
- Intel: `8086:*`

## Rationale

In multi-GPU systems, Mesa may select the wrong Vulkan device by default. The `MESA_VK_DEVICE_SELECT` environment variable forces Mesa to use the GPU matching the specified PCI vendor ID, ensuring games and applications run on the intended discrete GPU.

## Validation

✅ `just validate` - All checks pass
✅ `statix check .` - No linting issues
✅ `nix flake check` - Flake evaluates correctly
✅ Module evaluation succeeds

## Files Modified

- `modules/gpu.nix`

## Files Created

- `changelog/2025-10-22-mesa-vk-device-select.md`
