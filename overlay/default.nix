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
  jetbrains = final: prev: {
    # Override jetbrains idea-ultimate until the newer version is available
    jetbrains =
      prev.jetbrains
      // {
        idea-ultimate = prev.jetbrains.idea-ultimate.overrideAttrs (_: {
          version = "2022.3";
          src = prev.fetchurl {
            url = "https://download-cdn.jetbrains.com/idea/ideaIU-2022.3.3.tar.gz";
            sha256 = "sha256-wwK9hLSKVu8bDwM+jpOg2lWQ+ASC6uFy22Ew2gNTFKY=";
          };
        });
      };
  };
  additions = final: _prev: import ../pkgs {pkgs = final;};

  wpi-wireless-install = inputs.wpi-wireless-install.overlays.default;

  neovimNightly = inputs.neovim-nightly-overlay.overlay;

  rust-overlay = inputs.rust-overlay.overlays.default;
}
