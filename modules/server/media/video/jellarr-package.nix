{
  lib,
  pkgs,
}:
# Jellarr is consumed as the official v0.1.0 release bundle instead of
# upstream's `nix/package.nix`: that derivation pins a `fetchPnpmDeps` hash that
# no longer matches current nixpkgs (pnpm version drift), which broke the build
# in CI. The artifact below is the same commit's `pnpm build` output — verified
# byte-identical to a local build of de530bc — pinned by sha256, so no lockfile
# or pnpm version can silently change it.
pkgs.stdenvNoCC.mkDerivation {
  pname = "jellarr";
  version = "0.1.0";

  src = pkgs.fetchurl {
    url = "https://github.com/venkyr77/jellarr/releases/download/v0.1.0/jellarr-v0.1.0.cjs";
    hash = "sha256-99EQ0bMhCe4NKt+LzQKnDcudFbaP7gQNxOw5it9Bltg=";
  };

  dontUnpack = true;

  nativeBuildInputs = [pkgs.makeWrapper];

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/jellarr $src
    mv $out/share/jellarr/jellarr-v0.1.0.cjs $out/share/jellarr/bundle.cjs
    makeWrapper ${lib.getExe pkgs.nodejs_24} $out/bin/jellarr \
      --add-flags $out/share/jellarr/bundle.cjs
    runHook postInstall
  '';

  meta = {
    description = "Declarative Jellyfin configuration engine (official release bundle)";
    homepage = "https://github.com/venkyr77/jellarr";
    license = lib.licenses.agpl3Only;
    mainProgram = "jellarr";
    platforms = lib.platforms.all;
    sourceProvenance = [lib.sourceTypes.binaryBytecode];
  };
}
