{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    themes = {
      vscode = {
        palette = [
          "0=#1f1f1f"
          "1=#f44747"
          "2=#608b4e"
          "3=#dcdcaa"
          "4=#569cd6"
          "5=#c678dd"
          "6=#56b6c2"
          "7=#d4d4d4"
          "8=#808080"
          "9=#f44747"
          "10=#608b4e"
          "11=#dcdcaa"
          "12=#569cd6"
          "13=#c678dd"
          "14=#56b6c2"
          "15=#d4d4d4"
        ];
        background = "1f1f1f";
        foreground = "d4d4d4";
        cursor-color = "d4d4d4";
      };
    };
    settings = {
      theme = "vscode";
      background-opacity = 0.9;
      gtk-titlebar = false;
      clipboard-read = "allow";
      gtk-custom-css = "${pkgs.writeText "ghostty-gtk-custom-css.css" ''
        .top-bar {
          background: #1f1f1fe6;
          box-shadow: none;
        }
      ''}";
    };
  };
}
