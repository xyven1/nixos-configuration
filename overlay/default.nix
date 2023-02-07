{ outputs, inputs }:
{
	master = final: prev: {
		master = inputs.nixpkgs-master.legacyPackages.${final.system};
	};
	unstable = final: prev: {
		unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
	};
	neovimNightly = inputs.neovim-nightly-overlay.overlay;
}
