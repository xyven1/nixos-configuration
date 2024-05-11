{
  lib,
  pkgs,
  wrapGAppsHook,
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "tlpui";
  version = "1.5.0-5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "d4nj1";
    repo = "TLPUI";
    rev = "tlpui-${version}";
    sha256 = "sha256-Xzp+UrgPQ6OHEgnQ1aRvaZ+NWCSjeLdXG88zlgsaTw0=";
  };

  doCheck = false;
  build-system = with pkgs; [
    wrapGAppsHook
    python3Packages.setuptools-scm
    gtk3
    cairo
    gobject-introspection
  ];
  dependencies = with pkgs;
  with pkgs.python3Packages; [
    pycairo
    pygobject3
    tlp
    pciutils
    usbutils
  ];

  meta = {
    homepage = "https://github.com/d4nj1/TLPUI";
    description = "A GTK user interface for TLP written in Python";
    longDescription = ''
      The Python scripts in this project generate a GTK-UI to change TLP configuration files easily.
      It has the aim to protect users from setting bad configuration and to deliver a basic overview of all the valid configuration values.
    '';
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = [];
  };
}
