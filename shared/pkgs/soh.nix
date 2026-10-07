{ appimageTools, fetchurl }:

# Upstream's AppImage until nixpkgs' shipwright source build catches up to
# 9.3.0, which replaced OTRExporter/ZAPD with Torch.
let
  pname = "soh";
  # Shared with scripts/windows/install-soh.ps1 so friends match this version.
  release = builtins.fromJSON (builtins.readFile ./soh-release.json);
  inherit (release) version;

  src = fetchurl { inherit (release.linux) url sha256; };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage is a portable build that saves to the working directory.
  # This is where nixpkgs' NON_PORTABLE build saves, so saves carry over.
  extraPreBwrapCmds = ''
    export SHIP_HOME="''${SHIP_HOME:-$HOME/.local/share/soh}"
    mkdir -p "$SHIP_HOME"
  '';

  extraInstallCommands = ''
    install -Dm444 ${contents}/soh.desktop $out/share/applications/soh.desktop
    substituteInPlace $out/share/applications/soh.desktop \
      --replace-fail "Exec=soh.elf" "Exec=soh"
    cp -r ${contents}/usr/share/icons $out/share/icons
  '';

  meta.mainProgram = "soh";
}
