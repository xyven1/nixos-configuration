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
        shift

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
      exec $@ \$@
      EOT
        chmod +x "$alias_file"
      }
    '';
  };
  programs.git.ignores = [
    ".envrc"
    ".direnv"
  ];
}
