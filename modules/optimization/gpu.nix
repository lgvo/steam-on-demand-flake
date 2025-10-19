{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  gpuCfg = cfg.optimize.gpu;
  inherit (lib) mkOption mkIf types optionalAttrs;

  isAMD = gpuCfg.vendor == "amd";
  isNvidia = gpuCfg.vendor == "nvidia";

  amdEnv = {
    rdna2 = {
      AMD_VULKAN_ICD = "RADV";
    };
    rdna3 = {
      AMD_VULKAN_ICD = "RADV";
      RADV_DEBUG = "nonggc";
    };
    rdna4 = {
      AMD_VULKAN_ICD = "RADV";
    };
  };

  nvidiaEnv = generation: {
    __GL_THREADED_OPTIMIZATION = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
  };
in {
  options.services.steam-on-demand.optimize.gpu = {
    vendor = mkOption {
      type = types.nullOr (types.enum ["amd" "nvidia" "intel"]);
      default = null;
      description = "GPU vendor";
    };

    generation = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "GPU generation (rdna2/rdna3/rdna4 for AMD, rtx20/rtx30/rtx40/rtx50 for Nvidia)";
    };
  };

  config = mkIf (cfg.enable && gpuCfg.vendor != null) {
    hardware.graphics.enable = true;

    hardware.nvidia = mkIf isNvidia {
      package = mkIf (gpuCfg.generation == "rtx30" || gpuCfg.generation == "rtx40" || gpuCfg.generation == "rtx50") config.boot.kernelPackages.nvidiaPackages.beta;
      open = gpuCfg.generation == "rtx30" || gpuCfg.generation == "rtx40" || gpuCfg.generation == "rtx50";
      powerManagement.enable = true;
    };

    systemd.services.steam-on-demand.serviceConfig.Environment = mkIf isAMD (
      lib.mapAttrsToList (k: v: "${k}=${v}") (amdEnv.${gpuCfg.generation} or {})
    );

    assertions = [
      {
        assertion = !isNvidia || gpuCfg.generation != "rtx50" || config.hardware.nvidia.open;
        message = "RTX 50 series requires open Nvidia driver";
      }
      {
        assertion = !isAMD || gpuCfg.generation != "rdna4" || (builtins.compareVersions pkgs.mesa.version "25.1" >= 0);
        message = "RDNA4 requires Mesa 25.1 or newer";
      }
    ];
  };
}
