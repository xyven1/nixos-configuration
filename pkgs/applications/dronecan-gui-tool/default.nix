{
  lib,
  python3Packages,
  fetchFromGitHub,
  libsForQt5,
  install-freedesktop,
  easywebdav,
  pymonocypher,
  qtwidgets,
}:
python3Packages.buildPythonApplication rec {
  pname = "dronecan-gui-tool";
  version = "1.2.25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "dronecan";
    repo = "gui_tool";
    rev = "v${version}";
    sha256 = "sha256-PtiCQTaGXfqIkGlGdiWcRxxG0CUshEr/foeqwqJa7DE=";
  };

  build-system = with python3Packages; [
    install-freedesktop
    setuptools-git
    wheel
    libsForQt5.wrapQtAppsHook
  ];

  dependencies = with python3Packages; [
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

  dontWrapQtApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  meta = with lib; {
    description = "DroneCAN GUI Tool is a cross-platform free open source application for DroneCAN bus management and diagnostics";
    mainProgram = "dronecan_gui_tool";
    homepage = "https://github.com/dronecan/gui_tool";
    license = licenses.mit;
    maintainers = with maintainers; [xyven1];
  };
}
