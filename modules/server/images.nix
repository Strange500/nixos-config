# Central registry of container images, pinned content-addressed in the Nix
# store via dockerTools.pullImage (see ./container-images.nix for the mechanics).
#
# Modules reference them as:
#   image = "docker-archive:${images.<key>}";
#
# To UPDATE an image: bump `imageDigest` (and its resulting `sha256`) in a PR;
# on the next `nixos-rebuild` the store path changes and quadlet recreates the
# container on the new image. Digests are the manifest-list digest from
# `skopeo inspect docker://<img>:<tag>`; `sha256` is the flat hash of the
# skopeo docker-archive output (`nix hash file --type sha256 --sri`).
{ pkgs, lib }:
let
  pin = import ./container-images.nix { inherit pkgs lib; };
in {
  # --- arr stack (linuxserver / ghcr) ---
  sonarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/sonarr";
    imageDigest = "sha256:f247545d23ba8b233d6604575347e48a623fe6ad75dda02348bf81917f3b5c06";
    sha256 = "sha256-gAsW1bJZUxVxcg6pex9Iu1LqSI7LwVq+vP3xm8Yk+84=";
  };
  radarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/radarr";
    imageDigest = "sha256:7dfd049e79c00b16fbc29c3f5d96a9e7b9e73a23930b4c5b3c4541d60b366814";
    sha256 = "sha256-BxuMUpuOezxpTjbmb1yl9tph1RKKKFxfVEMbvG9YjWM=";
  };
  bazarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/bazarr";
    imageDigest = "sha256:8b30e81c4aec2991f469e78fae8afaa89ecc9b21a80e3897f50427216b55470c";
    sha256 = "sha256-fwvGtEruJ5Nuu3DGM9sewkTxZ9GCWkuV8kypkHCzqpM=";
  };
  prowlarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/prowlarr";
    imageDigest = "sha256:f2b26429893d4c4cb71941b7ee50b1bdecd9d5f9f9e02d5410615e9f4f7c8d95";
    sha256 = "sha256-vqu6mxmPTgTB1y6DrFfpMCszRlF46rtKpSeSEmhZtLM=";
  };
  qui = pin.mkPinnedImage {
    imageName = "ghcr.io/autobrr/qui";
    imageDigest = "sha256:1172ca40283330445d61189263a65a31ba703770a230b9e2a913f6e57bc2dd23";
    sha256 = "sha256-TSL54nnXTd4z/IIX/c5q7YXpaBQ1wzDrrm49tTXEQuQ=";
  };
  questarr = pin.mkPinnedImage {
    imageName = "ghcr.io/doezer/questarr";
    imageDigest = "sha256:6faaf75f484a20805309315dd9eb9f1550b039a668efb89c13fc028c72b45485";
    sha256 = "sha256-Z94XGDfCpgsZDa06pze4t3FxmyHjxjMcUzp0/fAOL2Y=";
  };

  # --- downloaders ---
  gluetun = pin.mkPinnedImage {
    imageName = "docker.io/qmcgaw/gluetun";
    imageDigest = "sha256:2733bb22b27e3efa7a9f2cef9057ec12791b8b225793fcd3dbfd0508404dfc25";
    sha256 = "sha256-Mr0hS6oMbRda0IhwCCdTBbB9tikjkKE/8hhXujaX7H4=";
  };
  qbittorrent = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/qbittorrent";
    imageDigest = "sha256:b522f9f4b769f8f36d49d22d5eb6a92e9aa18904c6a1830b1439df511ec21983";
    sha256 = "sha256-dHWpXghY7M6N71IpLNW06fHIADiYEtvGw3hjb38d2Fc=";
  };

  # --- hermes ---
  hermes = pin.mkPinnedImage {
    imageName = "docker.io/nousresearch/hermes-agent";
    imageDigest = "sha256:d4da4a40cd7a28aba983775d9fd31d94cbf153eeb0cb9e844d6d0f612b7c24db";
    sha256 = "sha256-cGQbkN3L2BruEKjPwIPcewRxTVPnC0HB6DWueFa5qss=";
  };

  # --- misc infra ---
  caddy = pin.mkPinnedImage {
    imageName = "docker.io/library/caddy";
    imageDigest = "sha256:881bbc60f9986d5ab8e7cfd6cf7e4ef3c9c0439fef2429d035d065577882f028";
    sha256 = "sha256-1d80xW7ArVmYwcYfZ5beQwSRTJUnuySqUEGLwyar4Ig=";
    finalImageTag = "alpine";
  };
  pgvector = pin.mkPinnedImage {
    imageName = "docker.io/pgvector/pgvector";
    imageDigest = "sha256:47af0b65960b14f1c6945aa4ccae37836c632e9a6fe0eea9160936e616e5b2e9";
    sha256 = "sha256-8AvJMk0Pu2OmeQdsCx2CHQX7VsAkEhbbqYLPnc6SASM=";
    finalImageTag = "pg15";
  };
  redis = pin.mkPinnedImage {
    imageName = "docker.io/library/redis";
    imageDigest = "sha256:164c759a0c342ee69d08fc99219382b0fd682181465c0df2e0e6911f4c85d73c";
    sha256 = "sha256-J+GIN6XDyPqUUJzK9w3hFi8H+7nvQ3gsAXQaziL/RJs=";
    finalImageTag = "8.2";
  };
  honcho = pin.mkPinnedImage {
    imageName = "ghcr.io/plastic-labs/honcho";
    imageDigest = "sha256:64254cab11a0690ca18db3ea9ee9bfc4e0a36ba95469adbb59f618744e773af9";
    sha256 = "sha256-LOnEWaSRG8owO/tnYtiFTjfBxzsQqyExfAVYZ6w/Gyo=";
  };
  couchdb = pin.mkPinnedImage {
    imageName = "docker.io/library/couchdb";
    imageDigest = "sha256:8cf5f8442585c346d2717ff0ad95605731d2f19f67b8367840baa8d3b24ebc31";
    sha256 = "sha256-UwUSwVcyeTFwxGtnUQzH1pJ6dxmb5+68iTy20SFQ3qg=";
  };
  postgres = pin.mkPinnedImage {
    imageName = "docker.io/library/postgres";
    imageDigest = "sha256:f7d23353e1b15400d22ebe31189f4d314b87a4c129cc400c8c2d8d4ca127bf81";
    sha256 = "sha256-vPh9z0HJPSyXK1idaQmpJ09I2Iij6+aTBDf5D7x9vMU=";
    finalImageTag = "15-alpine";
  };
  dashy = pin.mkPinnedImage {
    imageName = "docker.io/lissy93/dashy";
    imageDigest = "sha256:2b9be857a826a4b3dfe95f55ce61a467e63efec1a12ba9e25529f50bf658cfba";
    sha256 = "sha256-IVzqAed1tZEe5AyFdJGmQLU31wUsUnoiSPvT9KK7nlY=";
  };

  # --- vaultwarden ---
  vaultwarden = pin.mkPinnedImage {
    imageName = "docker.io/vaultwarden/server";
    imageDigest = "sha256:1587c45feaa479f1f5e8af3b00eded36bff77bcf1880cf8dbf0541706dd470e0";
    sha256 = "sha256-qlbNqkheenu3s17hboUk+WOvswscsxmoGqUj5HTgHbs=";
  };

  # --- media / books ---
  calibre = pin.mkPinnedImage {
    imageName = "docker.io/crocodilestick/calibre-web-automated";
    imageDigest = "sha256:5e00373854247750cc3e4479b492ae09293ff5e06ed10177f226634d97888679";
    sha256 = "sha256-ImYH1oPyqCw8oVXwDcd3aJRFYUWNEMWtUj4vdBXTi/0=";
  };
  mariadb = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/mariadb";
    imageDigest = "sha256:91de7f701bc7fc3a424b81beafca7a7c6c4c5b7c8be6afd2ae148698695c0b0c";
    sha256 = "sha256-zDYyFpYG/2KjYQu/rCVOwJItiS6ohlJvRzHBF/b9mxw=";
    finalImageTag = "11.4.8";
  };
  grimmory = pin.mkPinnedImage {
    imageName = "docker.io/grimmory/grimmory";
    imageDigest = "sha256:bf6fe21c6e247597f7869664a440b5a34242e2d2940575cae39c17bfaa66dc0b";
    sha256 = "sha256-Ppr6AwikLpojrNhZEVwyk+0woro0mljAm/ej79Ejrzw=";
  };
}