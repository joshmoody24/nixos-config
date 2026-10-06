{ config, pkgs, lib, ... }:

{
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

    ".config/kitty/current-theme.conf".source = ./dotfiles/kitty/current-theme.conf;

    ".config/ghostty/config".source = ./dotfiles/ghostty/config;
    ".config/ghostty/cursor_tail.glsl".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/sahaj-b/ghostty-cursor-shaders/main/cursor_tail.glsl";
      sha256 = "1g9vsbsxnvcj0y6rzdkxrd4mj0ldl9aha7381g8nfs3bz829y46w";
    };

    ".config/zellij/config.kdl".source = ./dotfiles/zellij/config.kdl;
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

    ".local/bin/llm-serve" = {
      source = ./dotfiles/llm/llm-serve;
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
    LLAMA_BASE_URL = "http://127.0.0.1:8080";
    LLAMA_API_KEY = "local";
  };

  fonts.fontconfig.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
}
