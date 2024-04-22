{
  inputs,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    extraPackages = with pkgs.unstable; [
      ripgrep
      fzf
      gitui
      lua-language-server
      nil
      alejandra
    ];
  };

  xdg.configFile."nvim" = {
    recursive = true;
    source = inputs.neovim-config;
  };
}
