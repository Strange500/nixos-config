{
  pkgs,
  quadlet-nix,
  ...
}:
pkgs.testers.nixosTest {
  name = "vaultwarden-test";

  nodes = {
    server = {config, ...}: {
      imports = [
        ../../settings.nix
        ../../modules/server/options.nix
        quadlet-nix.nixosModules.quadlet
        ../lib/sops-mock.nix
        ../../modules/server/password-manager
      ];

      config = {
        # Container runtime for the quadlet-defined vaultwarden container.
        virtualisation.podman.enable = true;
        # In the VM, container images load from the docker-archive already in
        # the Nix store — no registry pull, no network needed.
        virtualisation.quadlet.enable = true;

        # The module only carries a `Z` tmpfiles rule for the vaultwarden data
        # dir, and `Z` restores SELinux contexts on an EXISTING path — it does
        # not create one. On prod the container dir comes from the
        # impermanence setup (environment.persistence."/persist".directories in
        # modules/server/settings.nix), which this test node does not import.
        # Without it the bind mount has no source and podman dies with
        # "statfs <containerDir>/vaultwarden: no such file or directory".
        systemd.tmpfiles.rules = [
          "d ${config.qgroget.server.containerDir} 0755 root root -"
          "d ${config.qgroget.server.containerDir}/vaultwarden 0700 vaultwarden password-manager -"
        ];
      };
    };
  };

  testScript = ''
    start_all()

    # sops-mock fed a plain-YAML fake secret file; the mounted config.json
    # must be the fake "{}" (not a decryption failure of prod credentials).
    server.wait_for_unit("vaultwarden.service")
    server.wait_for_open_port(4743)

    # `/alive` is vaultwarden's liveness probe; poll because the first boot
    # runs sqlite migrations before the HTTP layer is ready.
    server.wait_until_succeeds("curl -f http://127.0.0.1:4743/alive", timeout=120)

    print("All Vaultwarden tests passed!")
  '';
}