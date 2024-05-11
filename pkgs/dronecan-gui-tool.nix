{
  lib,
  buildPythonApplication,
  buildPythonPackage,
  fetchFromGitHub,
  fetchurl,
  dronecan,
  requests,
  ipykernel,
  jupyter-client,
  numpy,
  pygments,
  pymavlink,
  cython,
  pyqt5,
  pyqtgraph,
  pyserial,
  pyyaml,
  qtawesome,
  qtconsole,
  qtpy,
  setuptools-git,
  setuptools,
  traitlets,
  wheel,
  libsForQt5,
}: let
  install-freedesktop = buildPythonPackage rec {
    pname = "install-freedesktop";
    version = "0.1.2-1-g2673e8d";
    format = "setuptools";

    src = fetchurl {
      name = "Thann-install_freedesktop-${version}.tar.gz";
      url = "https://github.com/thann/install_freedesktop/tarball/2673e8da4a67bee0ffc52a0ea381a541b4becdd4";
      hash = "sha256-O08G0iMGsF1DSyliXOHTIsOxDdJPBabNLXRhz5osDUk=";
    };

    doCheck = false;
  };
  qtwidgets = buildPythonPackage rec {
    pname = "qtwidgets";
    version = "1.2";
    format = "setuptools";

    src = fetchurl {
      name = "pythonguis-python-qtwidgets.tar.gz";
      url = "https://github.com/xyven1/python-qtwidgets/tarball/8d49b4edccfe8fa638a54c83b864174bec55576d";
      hash = "sha256-NDDZKe62oTKDSyKWNmoPjlFuCoXdk1YNB7X7uwmhlKw=";
    };

    propagatedBuildInputs = [pyqt5];

    doCheck = false;
  };
  easywebdav = buildPythonPackage rec {
    pname = "easywebdav";
    version = "1.2.0";
    format = "setuptools";

    src = fetchurl {
      name = "amnong-easywebdav-440c6132bcdd04a5618e6b0a6d0151a1c6cec1ad.tar.gz";
      url = "https://github.com/amnong/easywebdav/tarball/440c6132bcdd04a5618e6b0a6d0151a1c6cec1ad";
      hash = "sha256-mp0owknhKsg+ehRgzO7R8V3C6QTshxFsLhBlXPjrhtw=";
    };

    nativeBuildInputs = [requests];
    propagatedBuildInputs = [];
    doCheck = false;
  };
  pymonocypher = buildPythonPackage rec {
    pname = "pymonocypher";
    version = "4.0.2.2";
    format = "pyproject";

    nativeBuildInputs = [setuptools cython];
    propagatedBuildInputs = [numpy];

    src = fetchurl {
      url = "https://github.com/jetperch/pymonocypher/archive/refs/tags/v${version}.tar.gz";
      hash = "sha256-5hjZIdAwg+bdY/DJWOOFHPhYcJoVJ9wwoSztI9/v5x8=";
    };
  };
in
  buildPythonApplication rec {
    pname = "dronecan-gui-tool";
    version = "1.2.25";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "dronecan";
      repo = "gui_tool";
      rev = "v${version}";
      sha256 = "sha256-PtiCQTaGXfqIkGlGdiWcRxxG0CUshEr/foeqwqJa7DE=";
    };

    nativeBuildInputs = [
      install-freedesktop
      setuptools-git
      wheel
      libsForQt5.wrapQtAppsHook
    ];

    preFixup = ''
      makeWrapperArgs+=("''${qtWrapperArgs[@]}")
    '';

    propagatedBuildInputs = [
      dronecan
      easywebdav
      ipykernel
      jupyter-client
      numpy
      pygments
      pymavlink
      pymonocypher
      pyqt5
      pyqtgraph
      pyserial
      pyyaml
      qtawesome
      qtconsole
      qtpy
      qtwidgets
      setuptools
      traitlets
    ];

    nativeCheckInputs = [
    ];

    meta = with lib; {
      description = "";
      mainProgram = "dronecan_gui_tool";
      homepage = "https://github.com/dronecan/gui_tool";
      license = licenses.mit;
      maintainers = with maintainers; [xyven1];
    };
  }
