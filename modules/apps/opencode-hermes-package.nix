{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation {
  pname = "opencode-hermes-client";
  version = "1.19.5";
  # Baseline avoids an AVX2 requirement. Pin the CLI actually exercised by CI
  # instead of implicitly changing the client's request/SSE contract on updates.
  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-linux-x64-baseline/-/opencode-linux-x64-baseline-1.19.5.tgz";
    hash = "sha512-9kA+st3XXtCXMPx5f3Ld1u19uoHTO2u2Btt8a2cqhJ4GIqVbD1mXLevj3LHFEmtuQoFGk+UstGnl38sCqXj5sQ==";
  };
  nativeBuildInputs = [autoPatchelfHook];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode $out/bin/opencode
    runHook postInstall
  '';
  meta = {
    description = "Pinned OpenCode client for experimental Hermes API chat";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "opencode";
  };
}
