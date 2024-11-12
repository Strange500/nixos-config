{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchFromGitHub {
    owner = "Keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "8993670e73d36f4e8edc70d13614fa05edc2575c";
    sha256 = "0pjf12x6420rnrbj7q059szfpswcy7y8srsij6dg513fkzj5fimq";
  };
  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
   '';
}
