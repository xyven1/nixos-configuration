{
  nixpkgs.allowUnfreePackages = [
    "factorio-headless"
  ];
  services.factorio = {
    enable = true;
    openFirewall = true;
    admins = ["xyven1"];
    saveName = "blake-jrma14";
  };
}
