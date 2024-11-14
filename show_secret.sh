# test if /home/strange/.config/sops/age/keys.txt exist


if [ -f /home/strange/.config/sops/age/keys.txt ]; then
    echo "/home/strange/.config/sops/age/keys.txt exist"
else
    echo "File not exist"
    exist 1
fi

nix-shell -p sops --run "sops secrets/secrets.yaml"