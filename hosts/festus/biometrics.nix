{
  pkgs,
  lib,
  ...
}: {
  options.security.pam.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      config.fprintAuth = false;
    });
  };
  config = let
    tod-pkg = "libfprint-2-tod1-goodix";
  in {
    nixpkgs.allowUnfreePackages = [
      tod-pkg
    ];

    services.fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.${tod-pkg};
      };
    };
  };
}
