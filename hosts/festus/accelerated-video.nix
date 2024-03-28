{pkgs, ...}: {
  hardware.opengl = {
    enable = true;
    # package = pkgs.unstable.mesa.drivers;
    extraPackages = with pkgs; [
      intel-media-driver
      # libvdpau-va-gl
    ];
  };
  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
    # VDPAU_DRIVER = "va_gl";
  };
}
