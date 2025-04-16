{pkgs, ...}: {
  imports = [
    ./generic.nix
  ];
  home = {
    packages = [
      pkgs.unstable.wezterm
    ];
  };
  programs.fish = {
    functions = {
      update-home-server = "env -C /etc/nixos/ nix flake update home-management && rb";
    };
    interactiveShellInit = ''
      eval (ssh-agent -c)
      ssh-add
    '';
  };

  home.stateVersion = "22.11";
}
