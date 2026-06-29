{
  nixpkgs = import ../shared/nixpkgs.nix;
  clear-linux = import ./clear-linux.nix;
  vopono = import ./vopono.nix;
  nginx = import ./nginx.nix;
}
