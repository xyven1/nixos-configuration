{ outputs, inputs }:
{
	additions = final: _prev: import ../pkgs { pkgs = final; };

	neovimNightly = inputs.neovim-nightly-overlay.overlay;

} ++ [inputs.rust-overlay.overlay.default];
