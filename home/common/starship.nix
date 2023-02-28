{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      # format =
      #   let
      #     git = "$git_branch$git_commit$git_state$git_status";
      #     cloud = "$aws$gcloud$openstack";
      #   in
      #   ''
      #     $username$hostname($shlvl)($cmd_duration) $fill ($nix_shell)$custom
      #     $directory(${git})(- ${cloud}) $fill $time
      #     $jobs$character
      #   '';

      right_format = "$time";

      fill = {
        symbol = " ";
        disabled = false;
      };

      # Core
      username = {
        format = "[$user]($style)";
        style = "bold green";
      };
      hostname = {
        format = "[@$hostname]($style) ";
        ssh_only = true;
        style = "bold green";
      };
      shlvl = {
        format = "[$shlvl]($style) ";
        # style = "bold cyan";
        # threshold = 2;
        # repeat = true;
        # disabled = false;
      };
      cmd_duration = {
        format = "took [$duration]($style) ";
      };

      directory = {
        format = "[$path]($style)( [$read_only]($read_only_style)) ";
        truncate_to_repo = true;
        style = "bold blue";
        disabled = false;
      };

      character = {
        error_symbol = "[~~>](bold red)";
        success_symbol = "[->>](bold green)";
        vimcmd_symbol = "[<<-](bold yellow)";
        vimcmd_visual_symbol = "[<<-](bold cyan)";
        vimcmd_replace_symbol = "[<<-](bold purple)";
        vimcmd_replace_one_symbol = "[<<-](bold purple)";
      };

      time = {
        format = "\\\[[$time]($style)\\\]";
        disabled = false;
      };
    };
  };
}
