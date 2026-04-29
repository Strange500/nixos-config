{config, ...}: {
  sops = {
    age.keyFile = "${config.qgroget.secretAgeKeyPath}";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };
}
