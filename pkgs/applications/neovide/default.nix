{
  lib,
  rustPlatform,
  clangStdenv,
  fetchFromGitHub,
  linkFarm,
  fetchgit,
  runCommand,
  gn,
  neovim,
  ninja,
  makeWrapper,
  pkg-config,
  python3,
  removeReferencesTo,
  xcbuild,
  SDL2,
  fontconfig,
  xorg,
  stdenv,
  darwin,
  libglvnd,
  libxkbcommon,
  enableWayland ? stdenv.isLinux,
  wayland,
}:
rustPlatform.buildRustPackage.override {stdenv = clangStdenv;} rec {
  pname = "neovide";
  version = "af98449980c139edfc240ef9bb9649f784c5815a";

  src = fetchFromGitHub {
    owner = "neovide";
    repo = "neovide";
    rev = version;
    sha256 = "sha256-h047mMicnoNO/UPQ5LQhxPa5ghIsdNIj3AvtDWVtYWg=";
  };

  cargoHash = "sha256-03DLyAHaHLfaR1zBx7eBm3Akb0e/YQRVsmqLmy5hW88=";

  SKIA_SOURCE_DIR = let
    repo = fetchFromGitHub {
      owner = "rust-skia";
      repo = "skia";
      rev = "m124-0.72.3";
      sha256 = "sha256-zlHUJUXukE4CsXwwmVl3KHf9mnNPT8lC/ETEE15Gb4s=";
    };
    # The externals for skia are taken from skia/DEPS
    externals = linkFarm "skia-externals" (lib.mapAttrsToList
      (name: value: {
        inherit name;
        path = fetchgit value;
      })
      (lib.importJSON ./skia-externals.json));
  in
    runCommand "source" {} ''
      cp -R ${repo} $out
      chmod -R +w $out
      ln -s ${externals} $out/third_party/externals
    '';

  SKIA_GN_COMMAND = "${gn}/bin/gn";
  SKIA_NINJA_COMMAND = "${ninja}/bin/ninja";

  nativeBuildInputs =
    [
      makeWrapper
      pkg-config
      python3 # skia
      removeReferencesTo
    ]
    ++ lib.optionals stdenv.isDarwin [xcbuild];

  nativeCheckInputs = [neovim];

  buildInputs =
    [
      SDL2
      fontconfig
      rustPlatform.bindgenHook
    ]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.AppKit
    ];

  postFixup = let
    libPath = lib.makeLibraryPath ([
        libglvnd
        libxkbcommon
        xorg.libXcursor
        xorg.libXext
        xorg.libXrandr
        xorg.libXi
      ]
      ++ lib.optionals enableWayland [wayland]);
  in ''
    # library skia embeds the path to its sources
    remove-references-to -t "$SKIA_SOURCE_DIR" \
      $out/bin/neovide

    wrapProgram $out/bin/neovide \
      --prefix LD_LIBRARY_PATH : ${libPath}
  '';

  postInstall = ''
    for n in 16x16 32x32 48x48 256x256; do
      install -m444 -D "assets/neovide-$n.png" \
        "$out/share/icons/hicolor/$n/apps/neovide.png"
    done
    install -m444 -Dt $out/share/icons/hicolor/scalable/apps assets/neovide.svg
    install -m444 -Dt $out/share/applications assets/neovide.desktop
  '';

  disallowedReferences = [SKIA_SOURCE_DIR];

  meta = with lib; {
    description = "This is a simple graphical user interface for Neovim.";
    mainProgram = "neovide";
    homepage = "https://github.com/neovide/neovide";
    changelog = "https://github.com/neovide/neovide/releases/tag/${version}";
    license = with licenses; [mit];
    maintainers = with maintainers; [ck3d];
    platforms = platforms.all;
  };
}
