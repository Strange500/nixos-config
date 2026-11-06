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
    imageDigest = "sha256:386c962ee6e260e3a5656b25df2ed056bcc9b6410e197d075f9547fd14c23bca";
    sha256 = "sha256-9ihzgxMANdJW4eVKw6C0BSr17JmQYGKOe03f3+TAejE=";
  };
  radarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/radarr";
    imageDigest = "sha256:ade5937813c6ae415b29db729386e53fea3ecf067a019849bafbe2d2a6ec02ba";
    sha256 = "sha256-reNcL3T7ixt8zibmdIwIGgjGxJ7aWnshEK7O+3IpR/s=";
  };
  bazarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/bazarr";
    imageDigest = "sha256:7ef0e58216900dbce30b123e0eb65f5cb30e36f126de9474acdd2022fb069c54";
    sha256 = "sha256-PBBA2CMOrNKDbjtRY/N+wAsRT0Bia++gc2DdC5nqthc=";
  };
  prowlarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/prowlarr";
    imageDigest = "sha256:431d7efebcef466e56adaa40a7a2fa2b0e85159a037b8bf465eaadbf0cf5bedf";
    sha256 = "sha256-OXIWARwrtAJqcw8wSP+2W8mWDsXgiDf7fiAwhztovoA=";
  };
  qui = pin.mkPinnedImage {
    imageName = "ghcr.io/autobrr/qui";
    imageDigest = "sha256:a5b2f5faf6388cce257137c88e4b189458fd799cf9119ed476c980e5a69341b2";
    sha256 = "sha256-OQuCyII9P8BIsx6uzJrbixhYCMksFd9qQy8OaS4e+k4=";
  };
  questarr = pin.mkPinnedImage {
    imageName = "ghcr.io/doezer/questarr";
    imageDigest = "sha256:8b6a6df437aa3983a4ccffe164f3f33f664646c48cde05d263434e9768598621";
    sha256 = "sha256-fASx0zSgpjQRVxQCI3YsQxRyWw0fXbN0uiuRUoY+zzo=";
  };

  # --- downloaders ---
  gluetun = pin.mkPinnedImage {
    imageName = "docker.io/qmcgaw/gluetun";
    imageDigest = "sha256:4af0c804003481e100180e1f8d4d5e9c48163fedc0f88d061881b615aef9d183";
    sha256 = "sha256-GCpNkNqPJ9zZ2WIQCTvRCUfntOpbUeRFa6oUsKubhHQ=";
  };
  qbittorrent = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/qbittorrent";
    imageDigest = "sha256:b522f9f4b769f8f36d49d22d5eb6a92e9aa18904c6a1830b1439df511ec21983";
    sha256 = "sha256-dHWpXghY7M6N71IpLNW06fHIADiYEtvGw3hjb38d2Fc=";
  };

  # --- hermes ---
  hermes = pin.mkPinnedImage {
    imageName = "docker.io/nousresearch/hermes-agent";
    # Follow NousResearch's rolling main channel while keeping each rebuild
    # reproducible through the pinned manifest digest and archive hash.
    imageDigest = "sha256:e39055b7c9c0a7655a84cdce601fe6bdcef2740e1b524744375424b66fed6495";
    sha256 = "sha256-KRZ+gV0RntLYUiG/hRxckoRtTLtovxa5cxvmywoxbHQ=";
    finalImageTag = "main";
  };

  # --- misc infra ---
  caddy = pin.mkPinnedImage {
    imageName = "docker.io/library/caddy";
    imageDigest = "sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f";
    sha256 = "sha256-9s0U+Lt1dF5BIOxs8Z4uvwowHaJGO7xWBSSQOXm3pfw=";
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