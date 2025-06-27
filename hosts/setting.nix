{ config, hostname, ... }:
{
  imports = [
    ./${hostname}/settings.nix
  ];
}