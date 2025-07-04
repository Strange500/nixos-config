{pkgs, ...}: {
  # Enable Plymouth boot splash
  boot.plymouth = {
    enable = true;
    logo = ./../../../home/logo.png;
  };

  boot.kernelParams = [
    "quiet"
    "splash"
    "plymouth.ignore-serial-consoles"
    "amdgpu.dc=1"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "plymouth.use-simpledrm"
  ];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.initrd.systemd.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.loader.timeout = 1;
}
