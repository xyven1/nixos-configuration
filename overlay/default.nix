{ inputs }:
{
  unstable = final: prev: {
    unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
  };

  additions = final: _prev: import ../pkgs { pkgs = final; };

  neovimNightly = inputs.neovim-nightly-overlay.overlay;

  rust-overlay = inputs.rust-overlay.overlays.default;
}
