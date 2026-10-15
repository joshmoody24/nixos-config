{ ... }:

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
}
