# Neovim Configuration
This is my neovim configuration. It uses recent and maintained plugins with a focus on performance and a vscode like experience in many ways. Completion with CoQ, only using nvim-lsp for language server features (which is great for standarization and simplicity) along side nvim-dap (with related plugins) and lsp-installer. 65ms load times.

# Install Steps

1. First clone this repo into ~/.config/ with the a command like the following:

`git clone https://github.com/Xyven1/neovim-config.git ~/.config/nvim`

2. Use asdf to install neovim (recommended), or use the following script:  `~/.config/nvim/scripts/nvim.sh` (need to use nightly)
3. Install the dependencies listed below (ones necessary for basic functionality are marked with !)
3. Run the command `nvim`, and then `:PackerSync`, then `:PackerCompile`
4. Restart nvim, and everything should work  (you may see some errors, but do steps 3-4 till you don't)

# External dependencies
- python3-venv (for coq_nvim)

# asdf dependencies
- !neovim (nightly)
- direnv (fpr avoiding shim slowdowns with asdf)
- !fzf
- !python > 3.8.2 for CoQ
- gitui (There is no git manager plugin installed, so use git externally using C-z, gitui, and finally fg when you are done with git)
- rust
- lua
- golang
- erlang
- elixir
- nodejs
- haskell

Notes about asdf dependencies:
- In order to run any of these command with sudo the following alias must be used ```alias psudo='sudo env "PATH=$PATH"'```
- In order to avoid any slow downs due to shims, use direnv with a .envrc at / with the following lines ```DIRENV_LOG_FORMAT=''
use asdf```
