{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      {id = "nkbihfbeogaeaoehlefnkodbefgpgknn";} # MetaMask
      {id = "ddkjiahejlhfcafbddmgiahcphecmpfh";} # Ublock Origin
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
    ];
  };
}
