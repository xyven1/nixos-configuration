{ outputs, inputs }:
{
	master = final: prev: {
		master = inputs.nixpkgs-master.legacyPackages.${final.system};
	};
	unstable = final: prev: {
		unstable = nixpkgs-unstable.legacyPackages.${prev.system};
	};
	neovimNightly = neovim-nightly-overlay.overlay;
}
