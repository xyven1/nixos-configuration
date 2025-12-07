{
  nixpkgs = import ../shared/nixpkgs.nix;
  clear-linux = import ./clear-linux.nix;
  vopono = import ./vopono.nix;
  unpackerr = import ./unpackerr.nix;
  nginx = import ./nginx.nix;
}
