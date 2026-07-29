{
  config,
  pkgs,
  ...
}: {virtualisation.quadlet.pods.grimmory = {podConfig = {publishPorts = ["6060:6060"];};};}
