{ appimageTools, fetchurl }:

let
  pname = "dusklight";
  version = "2.0.3";

  src = fetchurl {
    url = "https://github.com/TwilitRealm/dusklight/releases/download/v${version}/Dusklight-v${version}-linux-x86_64.AppImage";
    sha256 = "87ec251963c984ad2b3ac075281431d2221db2297dc19f2ab5daad92e969fc06";
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/dev.twilitrealm.dusk.desktop -t $out/share/applications
    cp -r ${contents}/usr/share/icons $out/share/icons
  '';

  meta.mainProgram = "dusklight";
}
