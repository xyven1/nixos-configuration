self: super:
with self; {
  dronecan-gui-tool = callPackage ../applications/dronecan-gui-tool {};

  neovide-nightly = callPackage ../applications/neovide {};

  scenebuilder19 = callPackage ../applications/scenebuilder {};

  tlpui = callPackage ../applications/tlpui {};
}
