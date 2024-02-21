{
  pkgs,
  hostname,
  config,
  ...
}: {
  home.packages = [
    (pkgs.writeScriptBin
      "rbh"
      ''
        #!/usr/bin/env bash
        home-manager switch --flake /etc/nixos#${config.home.username}@${hostname} "$@"
      '')
  ];
}
