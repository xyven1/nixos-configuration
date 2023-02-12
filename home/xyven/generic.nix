{ outputs, inputs, ...}:

{
  imports = [
    ../common/neovim.nix
    ../common/font.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };
}

