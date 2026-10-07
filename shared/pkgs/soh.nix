{ appimageTools, fetchurl }:

# Upstream's AppImage until nixpkgs' shipwright source build catches up to
# 9.3.0, which replaced OTRExporter/ZAPD with Torch.
let
  pname = "soh";
  version = "9.3.0";

  src = fetchurl {
    url = "https://github.com/HarbourMasters/Shipwright/releases/download/${version}/soh.appimage";
    hash = "sha256-hQe7cEE+Ew5FLrr18Va/14AT7gFENkt5aGgOjPBkoPo=";
  };

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
