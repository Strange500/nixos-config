#!/usr/bin/env bash
set -euo pipefail

# Deliberately narrow rootful Podman diagnostics for the Hermes service.
# No shell, arbitrary command, container creation, mutation, or file access.
case "${1-}" in
  ps)
    [[ $# -eq 1 ]] || exit 2
    exec podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    ;;
  inspect)
    [[ $# -eq 2 ]] || exit 2
    case "$2" in hermes|hermes-dashboard|honcho-api) ;; *) exit 2 ;; esac
    exec podman inspect "$2" --format 'name={{.Name}} network={{.HostConfig.NetworkMode}} ports={{json .NetworkSettings.Ports}} networks={{json .NetworkSettings.Networks}}'
    ;;
  logs)
    [[ $# -eq 3 ]] || exit 2
    case "$2" in hermes|hermes-dashboard|honcho-api) ;; *) exit 2 ;; esac
    [[ "$3" =~ ^[1-9][0-9]{0,2}$ ]] || exit 2
    (( 10#$3 <= 200 )) || exit 2
    exec podman logs --tail "$3" "$2"
    ;;
  *)
    exit 2
    ;;
esac
