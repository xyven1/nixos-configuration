{
  inputs,
  config,
  host,
  pkgs,
  ...
}: let
  key = builtins.elemAt (builtins.filter (k: k.type == "ed25519") config.services.openssh.hostKeys) 0;
in {
  imports = [inputs.sops-nix.nixosModules.sops];
  environment.systemPackages = [pkgs.sops];
  sops = {
    defaultSopsFile = "${inputs.self}/hosts/${host}/secrets.yaml";
    age.sshKeyPaths = [key.path];
  };
}
