{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../common/neovim.nix
    ../common/fish.nix
    ../common/starship.nix
    ../common/direnv.nix
    inputs.nix-index-database.hmModules.nix-index
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  programs = {
    home-manager.enable = true;
    fish = {
      functions = builtins.listToAttrs (map (command: {
        name = command;
        value = {
          wraps = command;
          body = "env TERM=xterm-256color ${command} $argv";
        };
      }) ["ssh" "lazygit"]);
      shellAbbrs = {
        lg = "lazygit";
        v = "nvim";
        vd = "nvim +\"Resession load_dir\"";
        vl = "nvim +\"Resession load_latest\"";
      };
    };
    git = {
      enable = true;
      userName = "xyven1";
      userEmail = "git@xyven.dev";
      package = pkgs.unstable.git;
      delta = {
        enable = true;
        package = pkgs.unstable.delta;
        options = {
          syntax-theme = "Visual Studio Dark+";
          features = "decorations";
          decorations = {
            hunk-header-style = "file line-number syntax italic";
            hunk-header-decoration-style = "cyan bold ul";
            file-style = "yellow bold";
            file-decoration-style = "yellow bold ul";
          };
        };
      };
    };
    bat = {
      enable = true;
      package = pkgs.unstable.bat;
      config.theme = "Visual Studio Dark+";
    };
    btop = {
      enable = true;
      package = pkgs.unstable.btop;
      settings = {
        color_theme = "Default";
        theme_background = false;
        vim_keys = true;
        update_ms = 1000;
      };
    };
    eza = {
      enable = true;
      icons = "auto";
      git = true;
      package = pkgs.unstable.eza;
    };
    fd = {
      enable = true;
      package = pkgs.unstable.fd;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
    gh = {
      enable = true;
      package = pkgs.unstable.gh;
    };
    lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit;
      settings.git.paging = {
        colorArg = "always";
        pager = "delta --dark --paging=never";
      };
    };
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    pay-respects = {
      enable = true;
      package = pkgs.unstable.pay-respects;
      options = ["--nocnf"];
    };
    ripgrep = {
      enable = true;
      package = pkgs.unstable.ripgrep;
    };
    yazi = {
      enable = true;
      enableFishIntegration = true;
      package = pkgs.unstable.yazi;
    };
    zoxide = {
      enable = true;
      package = pkgs.unstable.zoxide;
    };
  };

  home = {
    packages = with pkgs.unstable; [
      # networking tools
      dig
      iputils
      rustscan
      socat
      trippy
      wget

      # hardware tools
      pciutils
      usbutils

      # text tools
      jq
      ripgrep-all # ripgrep all file types
      sd # sed alternative

      # other nice-to-haves
      dua # disk usage analyzer
      duf # df alternative
      dust # du alternative
      hyperfine # benchmarking tool
      ncdu # disk usage analyzer
      nh # nix helpers
      ouch # compress/decompress tool
      pipes-rs # pipes screensaver
      pipr # interactive shell pipeline builder
      procs # ps alternative
      screen # terminal multiplexer
      tealdeer # tldr client
    ];
  };

  home.stateVersion = lib.mkDefault "24.05";
}
