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

  additions = self: super: import ../pkgs {pkgs = super;};
}
