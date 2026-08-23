{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.quadlet-nix.homeManagerModules.quadlet
  ];

  home = {
    username = "hermes";
    homeDirectory = "/home/hermes";
    stateVersion = "25.11";
    packages = [
      pkgs.git
      pkgs.gh
      pkgs.jq
    ];
  };

  # Git identity + gh CLI so the `hermes` agent can clone/commit over SSH.
  programs.git = {
    enable = true;
    userName = "hermes-agent";
    userEmail = "hermes-agent@qgroget.com";
  };

  programs.gh = {
    enable = true;
    gitProtocol = "ssh";
  };

  programs.home-manager.enable = true;

  # Rootless service sandbox: `home-manager switch` touches only /home/hermes,
  # never system units or prod.
  virtualisation.quadlet.containers.echo-server = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
    containerConfig = {
      image = "docker.io/mendhak/http-https-echo:31";
      publishPorts = ["127.0.0.1:8080:8080"];
      userns = "keep-id";
    };
  };
}