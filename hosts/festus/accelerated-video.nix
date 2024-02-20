{pkgs, ...}: {
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  environment.variables = {
    #   LIBVA_DRIVER_NAME = "i915";
    VDPAU_DRIVER = "va_gl";
  };
}
