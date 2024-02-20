{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.helix = {
    enable = true;
    extraPackages = [
      pkgs.unstable.nil
      pkgs.unstable.alejandra
    ];
    settings = {
      theme = "dark_plus";
      editor = {
        true-color = true;
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        shell = lib.mkIf (config.programs.fish.enable) ["fish" "-c"];
        bufferline = "multiple";
        auto-pairs = true;
        indent-guides.render = true;
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "alejandra";
          };
        }
      ];
    };
  };
}
