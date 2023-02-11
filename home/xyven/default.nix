{ outputs, inputs, ...}:

{
  imports = [
    ./config/neovim.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };
}

