{
  config,
  pkgs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.root.hashedPassword = "$6$13gz85QezPcMpTXb$jalGiNan9u2PYc3jP4zgUYoZqNcu.811AqfVNadcNQhH4kn9uWC0FxO7UPArX5Apm49lhDbQ5elFeBRS76.s.1";

  users.users.${config.qgroget.user.username} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    uid = 1000;
    home = "/home/${config.qgroget.user.username}";
    description = "${config.qgroget.user.username}";
    hashedPassword = "$6$tN1HR03Pv6LQFA.w$1byWSM0wWLFn6nQkYebqYLrPzYNf2eyqmGDvTqI8OET9M3y74in7lVGr1KJOHZQys6wWh.ggaRafH6fyrgPmm.";
    linger = true;
    autoSubUidGidRange = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "docker"
      "nix-users"
      "libvirtd"
      "kvm"
      "media"
    ];
  };

  environment.etc."gitconfig".text = ''
    [safe]
      directory = /home/${config.qgroget.user.username}/nixos
  '';
}
