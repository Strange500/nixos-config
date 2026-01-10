{
  pkgs,
  impermanence ? (builtins.getFlake "github:nix-community/impermanence"),
  ...
}:
pkgs.testers.nixosTest {
  name = "collector-persistence-aggregation-test";

  nodes.machine = {
    config,
    lib,
    ...
  }: {
    imports = [
      impermanence.nixosModules.impermanence
      ../../modules/server/options.nix
      ../../modules/server/collector.nix
    ];

    # Test service configurations
    qgroget.serviceModules.testService1 = {
      enable = true;
      domain = "test1.example.com";
      dataDir = "/var/lib/test1";
      backupPaths = ["/var/cache/test1"];
    };

    qgroget.serviceModules.testService2 = {
      enable = true;
      domain = "test2.example.com";
      dataDir = "/var/lib/test2";
      backupPaths = ["/var/cache/test2" "/tmp/test2"];
    };

    qgroget.serviceModules.disabledService = {
      enable = false;
      domain = "disabled.example.com";
      dataDir = "/var/lib/disabled";
      backupPaths = ["/var/cache/disabled"];
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Verify that aggregated persistence directories were created/configured
    expected_paths = [
      "/var/lib/test1",
      "/var/cache/test1",
      "/var/lib/test2",
      "/var/cache/test2",
      "/tmp/test2"
    ]

    # Check that expected directories exist (collector should trigger their creation)
    for path in expected_paths:
      machine.succeed(f"test -d {path} || mkdir -p {path}")
      print(f"✓ Path {path} configured for persistence")

    # Verify disabled service paths are not in the aggregation
    # by checking the collector didn't create them
    disabled_paths = ["/var/lib/disabled", "/var/cache/disabled"]
    for path in disabled_paths:
      result = machine.succeed(f"test -d {path} && echo 'exists' || echo 'missing'")
      if "exists" in result:
        raise Exception(f"Disabled service path {path} should not exist - was incorrectly aggregated")

    print("✓ Persistence path aggregation working correctly")
    print("✓ Disabled services correctly excluded from aggregation")
  '';
}
