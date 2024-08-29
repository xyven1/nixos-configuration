{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      clear_aliases(){
        rm -rf "$PWD/.direnv/aliases"
      }
      export_alias() {
        local name=$1

        local alias_dir="$PWD/.direnv/aliases"
        local alias_file="$alias_dir/$name"
        local oldpath="$PATH"

        if ! [[ ":$PATH:" == *":$alias_dir:"* ]]; then
          mkdir -p "$alias_dir"
          PATH_add "$alias_dir"
        fi

        # Write the alias file
        cat <<EOT >"$alias_file"
      #!/usr/bin/env bash
      set -e
      PATH="$oldpath"
      $2 \$@
      EOT
        chmod +x "$alias_file"
      }
    '';
  };

  programs.fish = {
    interactiveShellInit = ''
      complete -f -c dda -a "(sed -n 's/^export_alias\s\+\([^ ]\+\)\s\+\(.\+\)/\1\t\2/p' .envrc)" -n "__fish_is_first_arg"
      complete -f -c dda -n "not __fish_is_first_arg" -a ""
      complete -f -c dea -a "(sed -n 's/^export_alias\s\+\([^ ]\+\)\s\+\(.\+\)/\1\t\2/p' .envrc)" -n "__fish_is_first_arg"
      complete -f -c dea -n "not __fish_is_first_arg" -a ""
      complete -f -c dca -a "(sed -n 's/^export_alias\s\+\([^ ]\+\)\s\+\(.\+\)/\1\t\2/p' .envrc)" -n "__fish_is_first_arg"
      complete -f -c dca -n "not __fish_is_first_arg" -a ""
      complete -f -c dcs -a ""
      complete -f -c dds -a ""
    '';
    functions = {
      dca = {
        description = "Add a new local alias using direnv";
        argumentNames = ["name" "command"];
        body = ''
          # if first or second argument is empty, report usage and exit
          if test -z "$argv[1]" -o -z "$argv[2]"
            echo "Usage: dca <alias-name> <command>"
            return
          end
          # if .envrc has not been created, create it
          if not test -f .envrc
            touch .envrc
          end
          # if the file doesn't have "clear_alias" in it, add it before the first "export_alias", or at the end of the file
          if not grep -q "clear_aliases" .envrc
            if grep -q "export_alias" .envrc
              sed -i '0,/^export_alias.*/s/^export_alias.*/clear_aliases\n&/' .envrc
            else
              echo "clear_aliases" >> .envrc
            end
          end

          set name $argv[1]
          set command $argv[2]
          # if command contains single quotes, error
          if echo $command | grep -q "'"
            echo "Error: command cannot contain single quotes"
            return
          end
          # if command contains newlines, error
          if test $(echo $command | wc -l) -gt 1
            echo "Error: command must be a single line"
            return
          end

          if grep -q "export_alias $name" .envrc
            read -l -P "Alias $name already exists, what would you like to do? ([o]verwrite/[e]dit/[a]bort)" answer
            switch $answer
              case o
                sed -i "/^export_alias $name/d" .envrc
              case e
                dea $name
                return
              case a
                return
              case '*'
                echo "Invalid option"
                return
            end
          end
          echo "export_alias $name '$command'" >> .envrc
          direnv allow
        '';
      };
      dea = {
        description = "Edit a local alias using direnv";
        argumentNames = ["name"];
        body = ''
          # if first argument is empty, report usage and exit
          if test -z "$argv[1]"
            echo "Usage: dea <alias-name>"
            return
          end
          # if .envrc doesn't exist, do nothing
          if not test -f .envrc
            return
          end
          # if the alias doesn't exist, do nothing
          if not grep -q "export_alias $argv[1]" .envrc
            echo "Alias $argv[1] does not exist"
            return
          end
          set line $(grep -n "export_alias $argv[1]" .envrc | cut -d: -f1)
          # open the alias in nvim
          nvim .envrc +$line +'norm!2W'
          direnv allow
        '';
      };
      dda = {
        description = "Delete a local alias using direnv";
        argumentNames = ["name" "command"];
        body = ''
          # if first argument is empty, report usage and exitA
          if test -z "$argv[1]"
            echo "Usage: dda <alias-name>"
            return
          end
          # if .envrc doesn't exist, do nothing
          if not test -f .envrc
            return
          end
          # delete any line which starts with "export_alias $argv[1]"
          sed -i "/^export_alias $argv[1]/d" .envrc

          # if there are no more aliases, delete the "clear_aliases" line
          if not grep -q "export_alias" .envrc
            sed -i '/clear_aliases/d' .envrc
          end
          # if the file is empty, delete it, otherwise reload direnv
          if test ! -s .envrc
            rm .envrc
          else
            direnv allow
          end
        '';
      };
      dcs = {
        description = "Create a local nix shell using direnv";
        body = ''
          # if .shell.nix doesn't exist, create it, otherwise open it
          if not test -f .shell.nix
            echo >.shell.nix "\
          {pkgs ? import <nixpkgs> {}}:
          pkgs.mkShell {
            packages = with pkgs; [

            ];
          }"
            nvim .shell.nix +4 +'norm!04i ' +'star!'
          else
            nvim .shell.nix
          end
          # if .envrc doesn't exist or doesn't contain "use nix .shell.nix", append "use nix .shell.nix",
          # then reload direnv accordingly
          if begin not test -f .envrc; or not grep -q "use nix .shell.nix" .envrc; end
            echo "use nix .shell.nix" >> .envrc
            direnv allow
          else
            direnv reload
          end
        '';
      };
      dds = {
        description = "Remove the local nix shell created by 'dcs'";
        body = ''
          if test -f .shell.nix
            rm .shell.nix
          end
          if test -f .envrc
            sed -i '/use nix .shell.nix/d' .envrc
            if test ! -s .envrc
              rm .envrc
            else
              direnv allow
            end
          end
        '';
      };
    };
  };

  programs.git.ignores = [
    ".envrc"
    ".direnv"
    ".shell.nix"
  ];
}
