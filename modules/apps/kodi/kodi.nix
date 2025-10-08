{pkgs, ...}: {
  programs.kodi = {
    enable = true;

    package = pkgs.kodi-gbm.withPackages (exts: [
      exts.jellycon
      exts.inputstream-adaptive
      pkgs.bingie
    ]);
  };
}
