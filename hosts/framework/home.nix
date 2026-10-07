{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../shared/home.nix
    ../../shared/work.nix
    ../../shared/llm.nix
  ];

  targets.genericLinux.nixGL.packages = inputs.nixgl.packages;
  targets.genericLinux.nixGL.defaultWrapper = "mesa";
  targets.genericLinux.nixGL.installScripts = ["mesa"];

  # Ubuntu's own Vulkan driver would load into Nix's glibc, which holds only
  # until the next Ubuntu update.
  llm.vulkanWrapper = lib.getExe inputs.nixgl.packages.${pkgs.system}.nixVulkanIntel;
  llm.models = [ "Qwen3.8-27B" "Qwen3.8-35B-A3B" ];

  home.packages = with pkgs; [
  ];
}
