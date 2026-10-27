# Everything that customises nixpkgs itself. The standalone home-manager hosts
# and unit build their package sets by separate routes, so both import this and
# `pkgs` means the same thing on every machine.
{
  config.allowUnfree = true;

  overlays = [
    (final: prev: {
      deque = final.callPackage ./pkgs/deque.nix { };
      dusklight = final.callPackage ./pkgs/dusklight.nix { };
    })
  ];
}
