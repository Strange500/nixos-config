# Standalone evaluation against the repository's locked nixpkgs/Home Manager.
{
  pkgs,
  home-manager,
}: let
  lib = pkgs.lib;
  evaluate = settings:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../settings.nix
        ../modules/apps/opencode-hermes.nix
        {
          home.username = "fixture";
          home.homeDirectory = "/home/fixture";
          home.stateVersion = "25.11";
          qgroget.nixos.apps.dev.opencodeHermes = settings;
        }
      ];
    }).config;
  disabled = evaluate {};
  enabled = evaluate {
    enable = true;
    baseUrl = "https://api-test.example.invalid/p/test/v1";
    modelId = "staging";
  };
  devOff =
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../settings.nix
        ../modules/apps/opencode-hermes.nix
        {
          home.username = "fixture";
          home.homeDirectory = "/home/fixture";
          home.stateVersion = "25.11";
          qgroget.nixos.apps.dev.enable = false;
          qgroget.nixos.apps.dev.opencodeHermes.enable = true;
        }
      ];
    }).config;
  overridden = evaluate {
    enable = true;
    package = pkgs.hello;
  };
  named = c: builtins.filter (p: (p.pname or p.name) == "opencode-hermes") c.home.packages;
  wrapper = builtins.head (named enabled);
in
  assert named disabled == [];
  assert named devOff == [];
  assert builtins.length (named enabled) == 1;
  assert builtins.length (named overridden) == 1;
  assert enabled.qgroget.nixos.apps.dev.opencodeHermes.package.version == "1.19.5";
  assert enabled.home.sessionVariables.HERMES_API_BASE_URL == "https://api-test.example.invalid/p/test/v1";
  assert enabled.home.sessionVariables.HERMES_MODEL_ID == "staging";
  assert !(enabled.home.sessionVariables ? HERMES_API_KEY);
  assert !(disabled.home.sessionVariables ? HERMES_API_BASE_URL);
  assert builtins.all (a: a.assertion) enabled.assertions;
  assert builtins.all (a: a.assertion) disabled.assertions; {
    inherit wrapper;
    package = enabled.qgroget.nixos.apps.dev.opencodeHermes.package;
    evaluation = "disabled/enabled/dev-off/package-override/settings/assertions: OK";
  }
