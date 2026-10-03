# Reusable helper to pin a registry image into the Nix store, so images are
# content-addressed (reproducible + cached in /nix/store) instead of floating
# `:latest` tags that never actually update on the host.
#
# How it works:
#   - `dockerTools.pullImage` runs `skopeo copy docker://<image>@<digest>` into
#     a docker-archive in /nix/store, verified by a fixed-output hash.
#   - The quadlet `.container` unit references it via the `docker-archive:`
#     transport (podman reads the archive directly, no `podman load` needed):
#         containerConfig.image = "docker-archive:${pinned}";
#   - To UPDATE: bump `imageDigest` (and the resulting `outputHash`) in a PR;
#     on the next `nixos-rebuild` the store path changes → quadlet recreates
#     the container on the new image.
#
# IMPORTANT (hash bootstrap): `outputHash` is the flat sha256 (nix base32) of
# the skopeo archive output. It cannot be computed by hand. We bootstrap each
# image with `lib.fakeSha256`: the FIRST `nix build` of the Server toplevel
# fails with `hash mismatch ... got sha256-<REAL>`, and we paste that value
# back here. After that the image is fetched from the (cached) registry and
# verified reproducibly forever.
{
  pkgs,
  lib,
}: {
  mkPinnedImage =
    {
      imageName,
      imageDigest,
      finalImageName ? imageName,
      finalImageTag ? "latest",
    }:
    pkgs.dockerTools.pullImage {
      inherit imageName imageDigest finalImageName finalImageTag;
      # Placeholder — replace with the flat sha256 revealed by the first build
      # (`hash mismatch ... got sha256-...`). See header note.
      sha256 = lib.fakeSha256;
    };
}