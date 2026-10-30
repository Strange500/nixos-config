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
    imageDigest = "sha256:48e36b608b461273b9dae857725cd0561a127f2c694b687318f6d0c5ce63e5c9";
    sha256 = "sha256-dpSR9aBxp6Dh7Ajaz0NRqQv25L9olSMhN0/bDVwFyPk=";
  };
  radarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/radarr";
    imageDigest = "sha256:084b3b2ab1d0ef930660727259546a241f2bdf67c9ed085d54bf1486a6887c9b";
    sha256 = "sha256-hPCAsaaz6XcKw3IVN4dSjh+sLh86xTaJdg9ECRCCWYE=";
  };
  bazarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/bazarr";
    imageDigest = "sha256:9a625883f054e722795affe5e3ca71057e6ed817ecdf99f4a99624346fcc509c";
    sha256 = "sha256-kDtxtl9wIbVJkqKS6RbOBU3DvHUvI3InK22+RZFwAb4=";
  };
  prowlarr = pin.mkPinnedImage {
    imageName = "ghcr.io/linuxserver/prowlarr";
    imageDigest = "sha256:04be30163fbaf48d6aeee7b5893c9f6614ffbad6d853971df0d6dcdf01c7f104";
    sha256 = "sha256-cjdp/rUb01uSLu3UdRYaAQmAul33AxWYD3osQl4mJeg=";
  };
  qui = pin.mkPinnedImage {
    imageName = "ghcr.io/autobrr/qui";
    imageDigest = "sha256:c83ce0370ab372c931ccb3f0ddd0eb1bc850026ce9eafc13ce94443f6f2a2cd3";
    sha256 = "sha256-EC1w2UpQwbPpwzLIjUyAy0sSuL4Re0pEk6K4iXg4PnI=";
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
    imageDigest = "sha256:9774f4f39a9bb8c2f68ce728ed5e99ddbad282163be56764afacf88ed952b784";
    sha256 = "sha256-vfEGKLCecIVKAlzwXJ3UeYJRScBPPSZ8Q3TETTyo6wk=";
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