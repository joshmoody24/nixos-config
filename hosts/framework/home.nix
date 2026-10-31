{ pkgs, lib, inputs, ... }:

let
  nixVulkan = inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixVulkanIntel;

  # Dusklight only renders through Vulkan, and nixGL's Vulkan toggle is global
  # (home-manager warns it can break other wrapped apps), so it gets its own.
  dusklight = pkgs.symlinkJoin {
    name = "dusklight";
    paths = [
      (pkgs.writeShellScriptBin "dusklight" ''
        exec ${lib.getExe nixVulkan} ${lib.getExe pkgs.dusklight} "$@"
      '')
      pkgs.dusklight
    ];
  };
in
{
  imports = [
    ../../shared/home.nix
    ../../shared/ubuntu.nix
    ../../shared/work.nix
    ../../shared/llm.nix
    ../../shared/niri.nix
  ];

  niri.standalone = true;
  niri.monitors = "hosts/framework/monitor.kdl";

  home.packages = [ dusklight ];
}
