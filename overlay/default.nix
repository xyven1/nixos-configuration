{
  inputs,
  config,
}: {
  unstable = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.system;
      config = config.nixpkgs.config;
    };
  };

  additions = final: _prev: import ../pkgs {pkgs = final;};

  wpi-wireless-install = inputs.wpi-wireless-install.overlays.default;

  neovimNightly = inputs.neovim-nightly-overlay.overlays.default;

  rust-overlay = inputs.rust-overlay.overlays.default;
}
