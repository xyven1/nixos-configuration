self: super:
with self; {
  dronecan-gui-tool = callPackage ../applications/dronecan-gui-tool {};

  tlpui = callPackage ../applications/tlpui {};
}
