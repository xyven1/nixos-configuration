# My NixOS configuration

## Installation
1. Create installation media, and boot into nix installer.
2. Cancel installer if using gui.
3. Clone this repo using `git clone https://github.com/xyven1/nixos-configuration.git`
4. Check if host uses disko or not, then proceed with one of the following:
#### Without disko: (this kind of sucks, easier to just proceed with installer, then clone and install in already working nixos system)
- Maually parition disks according to hardware-configuration.nix, or generate hardware-configuration.nix if not present. Ensure boot and everything is configured correctly
#### With disko:
Follow [this guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md) which roughly entails the following:
- Get `<disk-name>` with `lsblk`.
- Parition disk with ```sudo nix run github:nix-community/disko -- --mode zap_create_mount ./path/to/host/disko.nix --arg disks '[ "/dev/<disk-name>" ]'```.
- Move repo to newly partitioned drive via `mv nixos-configuration /mnt/etc/nixos`, or something along these lines.
- `cd` into the corresponding host folder (`/path/to/nixos/path/to/host/`) and run ```nixos-generate-config --no-filesystems --dir .```.
- Delete the generated configuration.nix file, as we will be using default.nix defined for the host.

5. Finally run `nixos-install --flake /path/to/nixos#<host>`
