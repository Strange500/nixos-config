{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.qgroget.nixos.apps.dev.opencodeHermes;
  # Preserve the wrapper's relative examples/ lookup inside an immutable bundle.
  bundle = pkgs.runCommand "opencode-hermes-source" {} ''
    mkdir -p $out/scripts $out/examples/opencode
    cp ${../../scripts/opencode-remote.py} $out/scripts/opencode-remote.py
    cp ${../../examples/opencode/hermes.json} $out/examples/opencode/hermes.json
  '';
  launcher = pkgs.writeShellApplication {
    name = "opencode-hermes";
    runtimeInputs = [pkgs.python3];
    text = ''
      # Do not allow an ambient OPENCODE_BIN to replace the selected Nix package.
      export OPENCODE_BIN=${lib.escapeShellArg (lib.getExe cfg.package)}
      if [[ ! -v HERMES_API_BASE_URL ]]; then
        export HERMES_API_BASE_URL=${lib.escapeShellArg cfg.baseUrl}
      fi
      if [[ ! -v HERMES_MODEL_ID ]]; then
        export HERMES_MODEL_ID=${lib.escapeShellArg cfg.modelId}
      fi
      exec python3 ${bundle}/scripts/opencode-remote.py "$@"
    '';
  };
in {
  config = lib.mkIf (config.qgroget.nixos.apps.dev.enable && cfg.enable) {
    home.packages = [launcher];
    home.sessionVariables = {
      HERMES_API_BASE_URL = cfg.baseUrl;
      HERMES_MODEL_ID = cfg.modelId;
    };
    # HERMES_API_KEY is deliberately runtime-only, never an option/store value.
  };
}
