{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.chromium = lib.mkIf config.qgroget.nixos.apps.basic {
    enable = true;
    package = pkgs.brave;
    extensions = [
      {id = "nkbihfbeogaeaoehlefnkodbefgpgknn";} # MetaMask
      {id = "ddkjiahejlhfcafbddmgiahcphecmpfh";} # Ublock Origin
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
    ];
  };
}
