{ stdenv }: stdenv.mkDerivation {
  name = "wpi-wireless-install";
  version = "0.1.0";
  src = ./src;
  description = "A flake encapsulating the wpi-wireless installation script";
  installPhase = ''
    mkdir -p $out/bin/ $out/lib/
    cp * $out/lib/
    echo "echo 'Please connect to WPI-Open before running this installer'; cd $out/lib/; nix-shell --run 'python $out/lib/main.py' $out/lib/shell.nix" > $out/bin/wpi-wireless-install
    chmod +x $out/bin/wpi-wireless-install
  '';
}
