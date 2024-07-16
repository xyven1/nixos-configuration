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
    {
      programs.nix-index-database.comma.enable = true;
    }
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
        vi = "nvim";
        vim = "nvim";
      };
    };
    git = {
      enable = true;
      userName = "xyven1";
      userEmail = "git@xyven.dev";
      package = pkgs.unstable.git;
      ignores = [
        ".direnv"
      ];
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
      icons = true;
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
    gitui = {
      enable = true;
      package = pkgs.unstable.gitui;
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
      wget
      # hardware tools
      pciutils
      usbutils
      # text tools
      jq
      # compression tools
      unzip
      zip
      # other nice-to-haves
      duf
      hyperfine
      ncdu
      pipes-rs
      screen
      tldr
    ];
  };

  home.stateVersion = lib.mkDefault "24.05";
}
