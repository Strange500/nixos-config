{
  pkgs,
  sops-nix,
  quadlet-nix,
  ...
}:
pkgs.testers.nixosTest {
  name = "vaultwarden-test";

  nodes = {
    server = {...}: {
      imports = [
        ../../settings.nix
        ../../modules/server/options.nix
        sops-nix.nixosModules.sops
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