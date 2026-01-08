{pkgs, ...}:
pkgs.testers.nixosTest {
  name = "required-fields-validation-test";

  nodes.machine = {
    config,
    lib,
    ...
  }: {
    imports = [
      ../../modules/server/options.nix
    ];

    # Test case 1: Valid configuration - all required fields present
    qgroget.serviceModules.validService = {
      enable = true;
      domain = "valid.example.com";
      dataDir = "/var/lib/valid";
    };

    # Test case 2: Disabled service doesn't require fields to be valid
    qgroget.serviceModules.disabledService.enable = false;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    print("✓ Configuration evaluated successfully with valid required fields")
  '';
}
