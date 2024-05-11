self: super:
with self; {
  install-freedesktop = callPackage ./python-modules/install-freedesktop {};
  easywebdav = callPackage ./python-modules/easywebdav {};
  pymonocypher = callPackage ./python-modules/pymonocypher {};
  qtwidgets = callPackage ./python-modules/qtwidgets {};
}
