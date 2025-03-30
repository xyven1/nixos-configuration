self: super:
with self; {
  dronecan-gui-tool = callPackage ../applications/dronecan-gui-tool {};

  scenebuilder19 = callPackage ../applications/scenebuilder {};

  tlpui = callPackage ../applications/tlpui {};
}
