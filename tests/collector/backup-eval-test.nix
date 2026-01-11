{
  lib,
  pkgs,
  ...
}: let
  config = lib.evalModules {
    modules = [
      ../../modules/server/options.nix
      ../../modules/server/collector.nix
      {
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
        qgroget.serviceModules.emptyBackupService = {
          enable = true;
          domain = "empty.example.com";
          dataDir = "/var/lib/empty";
          backupPaths = [];
        };
      }
    ];
  };
  backups = config.qgroget.backups;
  testService1 = backups.testService1 or throw "testService1 not found";

  # Test assertions
  testPaths = assert testService1.paths == ["/var/lib/test1" "/var/cache/test1"]; true;
  testUnits = assert testService1.systemdUnits == ["testService1.service"]; true;
  testPriority = assert testService1.priority == 100; true;

  testService2 = backups.testService2 or throw "testService2 not found";
  testPaths2 = assert testService2.paths == ["/var/lib/test2" "/var/cache/test2" "/tmp/test2"]; true;
  testDisabled = assert !(backups ? disabledService); true;
  testEmpty = assert !(backups ? emptyBackupService); true;
in
  pkgs.runCommand "backup-aggregation-test" {} "echo 'test passed' > $out"
