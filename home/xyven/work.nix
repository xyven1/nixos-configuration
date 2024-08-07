{
  pkgs,
  inputs,
  lib,
  ...
}: let
  nixGLWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${lib.getExe pkgs.nixgl.nixGLIntel} $bin \"\$@\"" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';
in {
  imports = [
    ../xyven/generic.nix
    ../common/font.nix
    ../common/gnome.nix
    ../common/helix.nix
    ../common/wezterm
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nixgl.overlay
    ];
  };

  rbh.profile = "xyven@work";

  home = {
    username = lib.mkForce "bbruell";
    packages = with pkgs.unstable; [
      (nixGLWrap neovide)
      libreoffice-qt
      scc
      vscode
      wike
      xclip
      firefox
      google-chrome
      docker
      glab
    ];
    sessionVariables.TERMINFO_DIRS = "${pkgs.wezterm.passthru.terminfo}/share/terminfo";
  };

  programs = {
    wezterm.package = lib.mkForce (nixGLWrap pkgs.unstable.wezterm);
    fish.package = pkgs.fish.override {
      # fix for using fish as login shell
      fishEnvPreInit = source: source "/etc/profile.d/nix.sh";
    };
  };

  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.stateVersion = "24.05";
}
