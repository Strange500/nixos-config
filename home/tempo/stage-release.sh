#!/usr/bin/env bash
# Build on an authorized workstation; this script never connects to the server.
set -euo pipefail
umask 077
if [[ $# != 2 ]]; then
  echo "Usage: bash $0 /path/to/edt /private/output/releases" >&2
  exit 2
fi
if [[ $(node -p 'process.versions.node.split(".")[0]') != 24 ]]; then
  echo 'Use Node 24 (the production runtime) and its npm on PATH.' >&2
  exit 1
fi
revision=$(tr -d '\n' < "$(dirname "$0")/revision")
[[ $revision =~ ^[0-9a-f]{40}$ ]]
source=$(realpath "$1")
mkdir -p "$2"
output=$(realpath "$2")
[[ ! -e "$output/$revision" ]] || { echo 'Release already exists; refusing overwrite.' >&2; exit 1; }
stage=$(mktemp -d "$output/.tempo-stage.XXXXXXXX")
cleanup() { chmod -R u+w "$stage"; rm -rf "$stage"; }
trap cleanup EXIT
mkdir "$stage/source" "$stage/release"
# Archive the committed revision only: never copy working-tree secrets or data.
git -C "$source" archive "$revision" | tar -x -C "$stage/source"
(
  cd "$stage/source"
  npm ci --ignore-scripts
  npm test
  npm run build
  npm audit --omit=dev --audit-level=low
  npm prune --omit=dev --ignore-scripts
  cp -R server dist node_modules package.json "$stage/release/"
)
printf '%s\n' "$revision" > "$stage/release/REVISION"
(
  cd "$stage/release"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
  sha256sum --check --status SHA256SUMS
)
# Read-only release; the separate data directory is the only mutable app state.
chmod -R go-rwx,a-w "$stage/release"
# Moving a directory between parents needs owner write permission on it.
chmod u+w "$stage/release"
mv "$stage/release" "$output/$revision"
chmod u-w "$output/$revision"
printf 'Staged %s\n' "$output/$revision"
