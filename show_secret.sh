# test if /home/strange/.config/sops/age/keys.txt exist

export SOPS_AGE_KEY_FILE="/var/lib/sops/age/keys.txt"

if [ -f $SOPS_AGE_KEY_FILE ]; then
    echo "$SOPS_AGE_KEY_FILE exist"
else
    echo "File not exist"
    exist 1
fi
nix-shell -p sops --run "sops secrets/secrets.yaml"
