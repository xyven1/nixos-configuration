{
  inputs,
  config,
  lib,
  ...
}: let
  l = lib;
  t = lib.types;
in {
  options.nixpkgs = {
    myOverlays = {
      enable = l.mkEnableOption "Enable my overlays";
      exclude = l.mkOption {
        type = t.listOf t.str;
        default = [];
        description = "List of overlays to exclude";
      };
      include = l.mkOption {
        type = t.listOf t.str;
        default = [];
        description = "List of overlays to include. If empty, all overlays are included.";
      };
    };
    allowUnfreePackages = l.mkOption {
      type = t.listOf t.str;
      default = [];
      description = "List of packages that are allowed to be unfree. Regex supported";
      example = ["steam" "nvidia-.*"];
    };
  };
  config.nixpkgs = {
    config.allowUnfreePredicate = pkg: let
      pkgName = lib.getName pkg;
      matchPackges = reg: ! builtins.isNull (builtins.match reg pkgName);
    in
      builtins.any matchPackges config.nixpkgs.allowUnfreePackages;

    overlays =
      l.mkIf
      config.nixpkgs.myOverlays.enable
      (let
        overlays = import ../../overlay {inherit inputs config;};
        included =
          if config.nixpkgs.myOverlays.include == []
          then overlays
          else
            l.attrsets.filterAttrs
            (name: _: l.elem name config.nixpkgs.myOverlays.include)
            overlays;
        withoutExcluded =
          l.attrsets.filterAttrs
          (name: _: ! l.elem name config.nixpkgs.myOverlays.exclude)
          included;
      in
        builtins.attrValues withoutExcluded);
  };
}
