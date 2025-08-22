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
    initrd.systemd.enable = true;
    consoleLogLevel = 3;
    initrd.verbose = false;
    loader.timeout = 1;
  };
}
