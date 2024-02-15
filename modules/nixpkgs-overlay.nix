{ inputs, config, lib, ... }:
{
  # options.nixpkgs.config.useDefaultOverlays = lib.mkOption {
  #   type = lib.types.bool;
  #   default = false;
  #   description = "Whether to use the default overlays from nixpkgs";
  # };
  # config = lib.mkIf config.nixpkgs.config.useDefaultOverlays {
  nixpkgs.overlays = builtins.attrValues (import ../overlay { inherit inputs config; });
  nixpkgs.config.allowUnfree = false;
  # };
}
