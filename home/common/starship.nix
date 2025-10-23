{...}: {
  programs.starship = {
    enable = true;
    settings = {
      right_format = "\${custom.nix_env}$time";

      fill = {
        symbol = " ";
        disabled = false;
      };

      # Core
      username = {
        format = "[$user]($style)";
        style_user = "bold green";
        style_root = "bold red";
      };
      hostname = {
        format = "[@$hostname]($style) ";
        ssh_only = true;
        style = "bold green";
      };
      shlvl = {
        style = "bold cyan";
        symbol = " ";
        disabled = false;
      };
      cmd_duration = {
        format = "took [$duration]($style) ";
      };

      command_timeout = 100;

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

      nix_shell = {
        symbol = " ";
        format = "via [$symbol]($style)⠀";
        heuristic = true;
      };

      time = {
        format = "\\\[[$time]($style)\\\]";
        disabled = false;
      };
      custom = {
        nix_env = {
          command = "nix-shell-info";
          when = true;
        };
      };
    };
  };
}
