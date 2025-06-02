{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  options.neovim = {
    local-config = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    use-nix-parsers = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
  config = let
    cfg = config.neovim;
  in {
    nixpkgs.allowUnfreePackages = [
      "vscode-extension-github-copilot"
    ];
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      withRuby = false;
      withPython3 = false;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

      extraPackages = with pkgs.unstable; [
        # For plugin functionality
        ripgrep
        fzf
        lazygit
        (writeShellScriptBin "copilot-lsp" ''
          exec ${lib.getExe nodejs} ${vscode-extensions.github.copilot}/share/vscode/extensions/github.copilot/dist/language-server.js $@
        '')
        # LSP & Formatting Providers
        marksman
        lua-language-server
        nixd
        alejandra
      ];
      extraLuaPackages = ps: with ps; [magick];
    };
    programs.git.ignores = [
      ".lazy.lua"
      ".nvim.lua"
    ];

    xdg.configFile = {
      "nvim" = lib.mkIf (!cfg.local-config) {
        recursive = true;
        source = inputs.neovim-config;
      };
      "nvim/lua/plugins/treesitter-parsers.lua" = lib.mkIf cfg.use-nix-parsers {
        text = ''
          vim.opt.runtimepath:append("${pkgs.symlinkJoin {
            name = "treesitter-parsers";
            paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
          }}")
          return {}
        '';
      };
    };
  };
}
