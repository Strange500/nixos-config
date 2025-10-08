{
  lib,
  rel,
  buildKodiAddon,
  fetchFromGitHub,
  addonUpdateScript,
}:
buildKodiAddon rec {
  pname = "bingie";
  namespace = "skin.titan.bingie.mod";
  version = "1197a8e421b2836a1c18ea7223b5b6a1f4f2d7ff";

  src = fetchFromGitHub {
    owner = "AchillesPunks";
    repo = namespace;
    rev = version;
    sha256 = "sha256-/io452HRsG315odrQjPtlSc74XV+k6JK++CP5ooa6wc=";
  };

  passthru = {
    updateScript = addonUpdateScript {
      attrPath = namespace;
    };
  };

  meta = with lib; {
    homepage = "https://forum.kodi.tv/showthread.php?tid=355993";
    description = "A Netflix-like skin for Kodi";
    license = licenses.gpl2Only;
    maintainers = teams.kodi.members;
  };
}
