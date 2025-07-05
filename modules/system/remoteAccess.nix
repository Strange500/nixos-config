{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.remote-access) {
    users.users.strange.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0BEci8hnaklKkXlnbagEMdf+/Ad7+USRH+ykQkYFdy strange@Clovis"
    ];
    services = {
      openssh = {
        enable = true;
        ports = [22];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = ["strange"];
          UseDns = true;
          PermitRootLogin = "no";
        };
      };
      fail2ban = {
        enable = true;
        maxretry = 3;
        bantime = "24h";
        bantime-increment = {
          enable = true;
          formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
          overalljails = true;
        };
      };
    };
  };
}
