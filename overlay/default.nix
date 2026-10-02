{
  inputs,
  config,
}: {
  unstable = self: super: {
    unstable = import inputs.nixpkgs-unstable {
      system = super.stdenv.hostPlatform.system;
      config = config.nixpkgs.config;
    };
  };
  multiverse = self: super: {
    mv = inputs.multiverse.legacyPackages.${super.stdenv.hostPlatform.system};
  };
  additions = self: super: import ../pkgs {pkgs = super;};
}
