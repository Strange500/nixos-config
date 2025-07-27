{config, ...}: {
  traefik.services = {
    adguard = {
      name = "adguard";
      url = "http://127.0.0.1:3000";
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ]; 

  services.adguardhome = {
    enable = true;
    #mutableSettings = false;
    settings = {
      dns = {
        upstream_dns = [
          "127.0.0.1:5335"
        ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false; 
        safe_search = {
          enabled = false; 
        };
        rewrites = [
          {
            domain = "*.${config.qgroget.server.domain}";
            answer = "192.168.0.34";
          }
        ];
      };
      # to not have to manually create {enabled = true; url = "";} for every filter
      filters =
        map (url: {
          enabled = true;
          url = url;
        }) [
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"
        ];
    };
  };

  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = ["127.0.0.1"];
        port = 5335;
        access-control = ["127.0.0.1 allow"];
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;

        hide-identity = true;
        hide-version = true;
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "9.9.9.9#dns.quad9.net"
            "149.112.112.112#dns.quad9.net"
          ];
          forward-tls-upstream = true; 
        }
      ];
    };
  };
}
