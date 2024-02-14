{ lib, python3Packages, pkgs }:
python3Packages.buildPythonApplication {
  pname = "wpi-wireless-install";
  version = "0.1.0";
  src = ./.;
  packages = [ "wpi_wireless_install" ];
  nativeBuildInputs = [ pkgs.openssl ];
  doCheck = false;
  propagatedBuildInputs = [ pkgs.openssl python3Packages.dbus-python ];
  meta = with lib; {
    description = "A flake encapsulating the wpi-wireless installation script";
    license = licenses.mit;
  };
}
