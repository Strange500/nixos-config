{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchFromGitHub {
    owner = "minMelody";
    repo = "sddm-sequoia";
    rev = "c88fba8290e631cda038dc47c15c8a74dd7a632f";
    sha256 = "0q7dapsipili067syk6whg0ih5jdixagjy6vvavaraql2h43yjjh";
  };
  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
   '';
}
