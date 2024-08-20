{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  l = lib;
  cfg = config.boot.clearLinuxPatches;
in {
  options.boot.clearLinuxPatches = {
    enable = l.mkEnableOption "Enable Clear Linux* kernel patches";
  };
  config.boot.kernelPatches = l.mkIf cfg.enable [
    {
      name = "Clear Linux* patchset";
      patch =
        pkgs.runCommand "kernel-clr-combined.patch" {
          nativeBuildInputs = [pkgs.gnugrep];
        } ''
          cd ${inputs.kernel-clr}
          grep -o '^%patch[0-9]* ' linux.spec \
            | grep -o '[0-9]*' \
            | xargs -I '{}' grep '^Patch{}:' linux.spec \
            | cut -d" " -f2- | xargs cat >> $out
        '';
    }
  ];
}
