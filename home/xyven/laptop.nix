{ pkgs, ... }:

{
	imports = [
		./generic.nix
	];

	home = {
    packages = with pkgs; [
      firefox
      wezterm
      fzf
      gitui
      ripgrep
      discord
    ];
	};
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake .#laptop";
        "rebuild-home" = "home-manager switch --flake .#xyven@laptop";
        "nvim-update" = "nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home";
        "nvim-update-config" = "nix flake lock --update-input neovim-config && rebuild-home";
      };
    };
    wezterm = {
      enable = true;
    };
  };
}


