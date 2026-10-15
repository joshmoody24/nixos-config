{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./theme.nix ];

  home.username = "josh";
  home.homeDirectory = "/home/josh";

  news.display = "silent";

  home.file = {
    # Lets `home-manager switch` (no args) find the flake and pick josh@$(hostname).
    ".config/home-manager/flake.nix".text = let
      repoPath = "${config.home.homeDirectory}/code/nixos-config";
    in ''
      {
        description = "Home Manager entrypoint (managed by nixos-config)";

        inputs.nixos-config.url = "path:${repoPath}";

        outputs = { nixos-config, ... }: {
          homeConfigurations = nixos-config.homeConfigurations;
        };
      }
    '';
    ".bashrc".source = ./dotfiles/.bashrc;

    ".config/nvim/lua" = {
      source = ./dotfiles/nvim/lua;
      recursive = true;
    };

    # lazy.nvim rewrites this on update, so it points at the checkout rather
    # than the store. A store copy would be read-only, and a committed lock
    # would never reach nvim.
    ".config/nvim/lazy-lock.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/code/nixos-config/shared/dotfiles/nvim/lazy-lock.json";

    # Both terminals take the palette from upstream directly, so they cannot
    # drift from each other or from nvim.
    ".config/kitty/current-theme.conf".source =
      "${inputs.tokyonight}/extras/kitty/tokyonight_${config.theme.style}.conf";

    ".config/ghostty/config".source = config.theme.apply ./dotfiles/ghostty/config;
    ".config/ghostty/themes/tokyonight_${config.theme.style}".source =
      "${inputs.tokyonight}/extras/ghostty/tokyonight_${config.theme.style}";
    ".config/ghostty/cursor_tail.glsl".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/sahaj-b/ghostty-cursor-shaders/main/cursor_tail.glsl";
      sha256 = "1g9vsbsxnvcj0y6rzdkxrd4mj0ldl9aha7381g8nfs3bz829y46w";
    };

    ".config/zellij/config.kdl".source = config.theme.apply ./dotfiles/zellij/config.kdl;
    ".config/zellij/themes/tokyonight.kdl".source =
      config.theme.apply ./dotfiles/zellij/themes/tokyonight.kdl;
    ".config/zellij/layouts" = {
      source = ./dotfiles/zellij/layouts;
      recursive = true;
    };
    ".local/bin/zj" = {
      source = ./dotfiles/zellij/zj;
      executable = true;
    };

    # Startup: one kitty window hosting a zellij session, so a crash or a closed
    # terminal costs no history.
    ".config/autostart/kitty.desktop".source = ./dotfiles/autostart/kitty.desktop;

    ".local/bin/dashboard" = {
      source = ./dotfiles/dashboard/dashboard;
      executable = true;
    };

    ".gitconfig".source = ./dotfiles/.gitconfig;

    ".claude/CLAUDE.md".source = ./dotfiles/agents/AGENTS.md;
    ".codex/AGENTS.md".source = ./dotfiles/agents/AGENTS.md;
    ".gemini/GEMINI.md".source = ./dotfiles/agents/AGENTS.md;
  };

  programs.neovim = {
    enable = true;
    withRuby = false;
    withPython3 = false;
    initLua = builtins.readFile ./dotfiles/nvim/init.lua;
    plugins = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      json javascript typescript tsx yaml html css
      markdown markdown_inline bash dockerfile lua vim
      gitignore sql astro clojure glsl fennel scheme
      elixir heex python gdscript vimdoc query
    ];
  };

  home.packages = with pkgs; [
    ripgrep
    xclip
    git
    delta
    wget
    (config.lib.nixGL.wrap google-chrome)
    (config.lib.nixGL.wrap firefox)
    gnome-tweaks
    unzip
    python314
    nodejs
    tsx
    gcc
    tree-sitter
    jq
    deque

    cascadia-code
    (config.lib.nixGL.wrap ghostty)
    gimp
    gnomeExtensions.clipboard-history
    gnomeExtensions.blur-my-shell
    antigravity-cli
    codex
    claude-code
    opencode
    gh
    glab
    github-copilot-cli
    onlyoffice-desktopeditors
    fd
    zellij
    rlwrap

    swi-prolog
    racket
    factor-lang

    # Clojure
    clojure
    openjdk
    clojure-lsp
    cljfmt

    typescript
    ast-grep
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  fonts.fontconfig.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Was an unmanaged file that drifted to firefox on its own. Managing it means
  # the GUI "default apps" pickers can no longer change it, since it becomes a
  # read-only store symlink.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = let
      chrome = [ "google-chrome.desktop" ];
    in {
      "text/html" = chrome;
      "application/xhtml+xml" = chrome;
      "application/x-extension-htm" = chrome;
      "application/x-extension-html" = chrome;
      "application/x-extension-shtml" = chrome;
      "application/x-extension-xhtml" = chrome;
      "application/x-extension-xht" = chrome;
      "video/webm" = chrome;
      "x-scheme-handler/http" = chrome;
      "x-scheme-handler/https" = chrome;
      "x-scheme-handler/about" = chrome;
      "x-scheme-handler/unknown" = chrome;
      "x-scheme-handler/chrome" = chrome;

      "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
      "x-scheme-handler/slack" = [ "slack.desktop" ];
      "x-scheme-handler/mongodb" = [ "mongodb-compass.desktop" ];
      "x-scheme-handler/mongodb+srv" = [ "mongodb-compass.desktop" ];
      "x-scheme-handler/grokbot" = [ "grok-bot.desktop" ];
      "x-scheme-handler/sand" = [ "grok-bot.desktop" ];

      "application/sql" = [ "nvim.desktop" ];
    };
  };

  programs.git.enable = true; # config in dotfiles/.gitconfig

  programs.kitty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.kitty;
    extraConfig = builtins.readFile ./dotfiles/kitty/kitty.conf;
  };

  home.stateVersion = "25.05";

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Tools that write ssh config of their own, like `coder config-ssh`, get a
    # file each in here instead of fighting us over ~/.ssh/config. Included
    # first, and ssh takes the first value it is given, so their host blocks
    # beat the catch-all below.
    includes = [ "config.d/*" ];

    settings = let
      tailnet = name: {
        # Stale registrations hold the unsuffixed names, so the live machines are -1.
        HostName = "joshm-${name}-1";
        User = "josh";
        # Keep long remote jobs alive across lid closes and Wi-Fi hops.
        ServerAliveInterval = 30;
        ServerAliveCountMax = 6;
        ControlMaster = "auto";
        ControlPersist = "10m";
      };
    in {
      framework = tailnet "framework";
      thinkpad = tailnet "thinkpad";
      unit = (tailnet "unit") // { HostName = "unit"; };

      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Generating them warns about a missing store reference, a home-manager bug,
  # and the same options are a web search away.
  manual.manpages.enable = false;
}
