{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };
  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
