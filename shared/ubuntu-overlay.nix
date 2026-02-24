final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--no-sandbox --test-type";
  };

  slack = final.symlinkJoin {
    name = "slack";
    paths = [ prev.slack ];
    buildInputs = [ final.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/slack --add-flags "--no-sandbox"
      rm $out/share/applications/slack.desktop
      substitute ${prev.slack}/share/applications/slack.desktop $out/share/applications/slack.desktop \
        --replace-fail ${prev.slack}/bin/slack $out/bin/slack
    '';
  };

  mongodb-compass = final.symlinkJoin {
    name = "mongodb-compass";
    paths = [ prev.mongodb-compass ];
    buildInputs = [ final.makeWrapper ];
    postBuild = ''wrapProgram $out/bin/mongodb-compass --add-flags "--no-sandbox"'';
  };
}
