{...}: {
  imports = [
    ../system/desktop.nix
    ../system/desktop-packages.nix
    ../system/audio/audio.nix
    ../system/bluetooth/bluetooth.nix
    ../system/login/login.nix
    ../system/boot/plymouth.nix
  ];
}
