{
  lib,
  python3Packages,
  fetchFromGitHub,
  libsForQt5,
  imagemagick,
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
    imagemagick
  ];

  dependencies = with python3Packages; [
    pkgs.iproute2
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

  postInstall = ''
    convert icons/logo.ico icons/dronecan_gui_tool.png
    mv $out/share/applications/DroneCAN\ GUI\ Tool.desktop $out/share/applications/dronecan_gui_tool.desktop
    substituteInPlace $out/share/applications/dronecan_gui_tool.desktop \
      --replace "Exec=/dronecan_gui_tool-1.2.25.data/scripts/dronecan_gui_tool" "Exec=dronecan_gui_tool"
    install -Dm644 icons/dronecan_gui_tool-0.png $out/share/icons/hicolor/256x256/apps/dronecan_gui_tool.png
  '';

  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  meta = {
    description = "DroneCAN GUI Tool is a cross-platform free open source application for DroneCAN bus management and diagnostics";
    mainProgram = "dronecan_gui_tool";
    homepage = "https://github.com/dronecan/gui_tool";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [xyven1];
  };
}
