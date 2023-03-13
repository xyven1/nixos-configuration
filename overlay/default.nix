{ inputs }:
{
  unstable = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.system;
      config = {
        allowUnfree = true;
        allowUnfreePredicate = (_: true);
      };
    };
  };

  additions = final: _prev: import ../pkgs { pkgs = final; };

  neovimNightly = inputs.neovim-nightly-overlay.overlay;

  rust-overlay = inputs.rust-overlay.overlays.default;
}
