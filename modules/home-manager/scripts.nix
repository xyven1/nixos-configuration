{pkgs, ...}: {
  home.packages = [
    (pkgs.writeScriptBin
      "rbh"
      ''
        #!/usr/bin/env bash
        home-manager switch --flake /etc/nixos "$@"
      '')
  ];
}
