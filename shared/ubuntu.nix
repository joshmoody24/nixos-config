{ pkgs, lib, inputs, ... }:

# What a host needs purely because it runs Ubuntu rather than NixOS.
{
  # Ubuntu's own GL and Vulkan drivers would load into nix's glibc, which holds
  # only until the next Ubuntu update.
  targets.genericLinux.nixGL.packages = inputs.nixgl.packages;
  targets.genericLinux.nixGL.defaultWrapper = "mesa";
  targets.genericLinux.nixGL.installScripts = [ "mesa" ];

  llm.vulkanWrapper =
    lib.getExe inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixVulkanIntel;
}
