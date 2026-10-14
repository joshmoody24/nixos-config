{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.theme;

  # Upstream publishes the palette as a lua table of named colors, one per line
  # at two spaces of indent. Nested tables sit deeper, so matching the indent is
  # enough to pick out the top-level names.
  upstream = lib.listToAttrs (lib.filter (x: x != null) (map
    (line:
      let m = builtins.match ''^  ([a-z0-9_]+) = "#([0-9a-f]{6})",?'' line;
      in if m == null then null else lib.nameValuePair (lib.head m) (lib.last m))
    (lib.splitString "\n"
      (builtins.readFile "${inputs.tokyonight}/extras/lua/tokyonight_${cfg.style}.lua"))));

  missing = lib.filter (name: !(upstream ? ${name})) (lib.attrValues cfg.roles);

  pinnedForNvim =
    (builtins.fromJSON (builtins.readFile ./dotfiles/nvim/lazy-lock.json))
    ."tokyonight.nvim".commit;
in
{
  options.theme = {
    style = lib.mkOption {
      type = lib.types.str;
      default = "night";
      description = "Which tokyonight variant: night, storm, moon or day.";
    };

    roles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        What each colour is for, mapped to its name in upstream's palette. The
        configs refer to the role, so nothing in this repo holds a hex code.
      '';
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Each role resolved to a bare hex colour, without the leading #.";
    };

    apply = lib.mkOption {
      type = lib.types.functionTo lib.types.path;
      readOnly = true;
      description = ''
        Replaces @role@ and @style@ in a config file. Only the names a file
        actually uses are substituted: replaceVars would be the obvious tool,
        but it rejects any @token@ it was not asked about, and niri's volume
        binds pass @DEFAULT_AUDIO_SINK@ through to wpctl.
      '';
    };
  };

  config = {
    assertions = [{
      assertion = inputs.tokyonight.rev == pinnedForNvim;
      message = ''
        The tokyonight flake input is at ${inputs.tokyonight.rev} but nvim's
        lazy-lock.json pins ${pinnedForNvim}. Point the input at that commit, or
        update the lock, so the editor and the desktop share one palette.
      '';
    }];

    theme.roles = {
      bg = "bg";
      barBg = "bg_dark";
      fg = "fg";
      dim = "fg_dark";
      dimmer = "dark3";
      border = "terminal_black";
      selected = "bg_highlight";
      accent = "blue";
      warn = "warning";
      error = "red";
      ok = "green";
    };

    theme.colors =
      assert lib.assertMsg (missing == [ ])
        "theme.roles names colours upstream does not define: ${toString missing}";
      lib.mapAttrs (_: name: upstream.${name}) cfg.roles;

    theme.apply = file:
      let
        contents = builtins.readFile file;
        tokens = cfg.colors // { inherit (cfg) style; };
        used = lib.filterAttrs (name: _: lib.hasInfix "@${name}@" contents) tokens;
      in
      pkgs.substitute {
        src = file;
        substitutions = lib.concatLists (lib.mapAttrsToList
          (name: value: [ "--replace-fail" "@${name}@" value ])
          used);
      };
  };
}
