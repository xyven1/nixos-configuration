{
  lib,
  pkgs,
  config,
  ...
}: {
  programs.nix-index.enable = true;

  home.packages = [
    pkgs.unstable.any-nix-shell
    pkgs.unstable.fishPlugins.fzf-fish
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
      nu = "nix flake lock --update-input";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

      conf = "/etc/nixos";
    };
    functions = {
      fish_greeting = "";
      user_vi_key_bindings = ''
        function fish_user_key_bindings
          for mode in insert default visual
            bind -M $mode \cf forward-char
          end
        end
      '';
      "nvim-update" = "env -C /etc/nixos/ nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rbh";
      "nvim-update-config" = "env -C /etc/nixos/ nix flake lock --update-input neovim-config && rbh";
    };
    shellInit = let
      sv = config.home.sessionVariables;
    in ''
      ${lib.optionalString (sv ? EDITOR) "set -x EDITOR ${sv.EDITOR}"}
      set fish_vi_force_cursor 1
      set fzf_fd_opts --hidden
    '';
    interactiveShellInit = ''
    '';
    shellInitLast = ''
      any-nix-shell fish --info-right | source
      fish_vi_key_bindings
      user_vi_key_bindings
      fish_vi_cursor
    '';
  };
}
