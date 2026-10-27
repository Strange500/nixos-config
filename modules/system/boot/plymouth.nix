{
  lib,
  config,
  ...
}: {
  boot = lib.mkIf config.qgroget.nixos.isDesktop {
    plymouth = {
      enable = config.qgroget.nixos.isDesktop;
      logo = config.logo.plymouth;
    };
    kernelParams = [
      "quiet"
      "splash"
      "plymouth.ignore-serial-consoles"
      "amdgpu.dc=1"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "plymouth.use-simpledrm"
    ];
    initrd.kernelModules = ["amdgpu"];
    # boot.initrd.systemd.enable / boot.initrd.verbose were REMOVED upstream
    # (scripted initrd is gone, systemd initrd is the only mode) and keeping
    # them fails eval with "no longer has any effect".
    consoleLogLevel = 3;
    loader.timeout = 1;
  };
}
