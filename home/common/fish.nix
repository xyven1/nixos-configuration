{
  lib,
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs.unstable; [
    any-nix-shell
    fishPlugins.fzf-fish
    # https://github.com/acomagu/fish-async-prompt/issues/75#issuecomment-3920509320
    (fishPlugins.async-prompt.overrideAttrs (final: prev: {
      version = "git-fcf12e9";
      src = fetchFromGitHub {
        inherit (prev.src) owner repo;
        rev = "fcf12e9f20af4724c3981ea012a47dd8dca8d6ef";
        hash = "sha256-JxoOKodbS5sTNROFWayG+c5AYl+89otbPrfhIEkFl+o=";
      };
    }))
  ];
  programs.fish = {
    enable = true;
    shellAbbrs = {
      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";
      nfu = "nix flake update";
      gc = "nix-collect-garbage";
      gcd = "nix-collect-garbage -d";

      conf = "/etc/nixos";
    };
    functions = let
      grayedLast = {
        argumentNames = "last_prompt";
        body = ''
          echo -n "$last_prompt" | sed -r 's/\x1B\[[0-9;]*[JKmsu]//g' | read -zl uncolored_last_prompt
          echo -n (set_color brblack)"$uncolored_last_prompt"(set_color normal)
        '';
      };
    in {
      fish_greeting = "";
      fish_prompt_loading_indicator = grayedLast;
      fish_right_prompt_loading_indicator = grayedLast;
    };
    shellInit = let
      sv = config.home.sessionVariables;
    in ''
      ${lib.optionalString (sv ? EDITOR) "set -x EDITOR ${sv.EDITOR}"}
      set fish_vi_force_cursor 1
      set fzf_fd_opts --hidden
    '';
    shellInitLast = ''
      any-nix-shell fish | source
      fish_vi_key_bindings
      fish_vi_cursor
    '';
  };
}
