{ pkgs ? import <nixpkgs> { } }:
let
  my-python-packages = p: with p; [
    dbus-python
  ];
  my-python = pkgs.python39.withPackages my-python-packages;
in
pkgs.mkShell {
  buildInputs = [
    pkgs.openssl
    my-python
  ];
}
