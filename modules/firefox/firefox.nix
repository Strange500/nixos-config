{ pkgs, inputs, lib, config, ... }: {
  programs.firefox = {
    enable = true;
    languagePacks = [ "fr_FR" ];
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      BlockAboutConfig = false;
      DefaultDownloadDirectory = "\${home}/Downloads";
    };
    profiles.strange = {
      settings =
        { # specify profile-specific preferences here; check about:config for options
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.startup.homepage" = "https://nixos.org";
          "browser.newtabpage.pinned" = [{
            title = "NixOS";
            url = "https://nixos.org";
          }];
        };
      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          metamask
        ];
        settings."uBlock0@raymondhill.net".settings = {
          selectedFilterLists = [
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-unbreak"
            "ublock-quick-fixes"
          ];
        };
      };
      bookmarks = {
        force = true;
        settings = [{
          toolbar = true;
          bookmarks = [
            {
              name = "Home";
              bookmarks = [
                {
                  name = "Photos - Immich";
                  url = "https://immich.qgroget.com/photos";
                }
                {
                  name = "Connexion - Jellyseerr";
                  url = "https://jellyseerr.qgroget.com/login";
                }
                {
                  name = "Jellyfin";
                  url =
                    "https://jellyfin.qgroget.com/web/#/login.html?serverid=68fb5b2c9433451fa16eb7e29139e7f2&url=%2Fhome.html";
                }
                {
                  name = "Vaults | Vaultwarden Web";
                  url = "https://vaultwarden.qgroget.com/#/vault";
                }
                {
                  name = "Home | QGRoget";
                  url = "https://list.qgroget.com/";
                }
                {
                  name = "Open WebUI";
                  url = "https://ai.qgroget.com/";
                }
                {
                  name = "Navidrome";
                  url =
                    "https://navidrome.qgroget.com/app/#/album/recentlyAdded?sort=recently_added&order=DESC&filter={}";
                }
                {
                  name = "Admin";
                  bookmarks = [
                    {
                      name = "Series - Bazarr";
                      url = "https://bazarr.local.qgroget.com/series";
                    }
                    {
                      name = "Nicotine";
                      url = "https://nicotine.local.qgroget.com/";
                    }
                    {
                      name = "Pi-hole - piholeunbound";
                      url = "https://pihole.local.qgroget.com/admin/";
                    }
                    {
                      name = "Radarr";
                      url = "https://radarr-anime.local.qgroget.com/";
                    }
                    {
                      name = "Indexers - Prowlarr";
                      url = "https://prowlarr.local.qgroget.com/";
                    }
                    {
                      name = "Radarr";
                      url = "https://radarr.local.qgroget.com/";
                    }
                    {
                      name = "Sonarr";
                      url = "https://sonarr-serie.local.qgroget.com/";
                    }
                    {
                      name = "Sonarr";
                      url = "https://sonarr.local.qgroget.com/";
                    }
                    {
                      name = "server/Login";
                      url = "https://unraid.local.qgroget.com/login";
                    }
                  ];
                }
              ];
            }
            {
              name = "Crypto";
              bookmarks = [
                {
                  name = "Stack";
                  bookmarks = [{
                    name = "Stake with Lido | Lido";
                    url = "https://stake.lido.fi/";
                  }];
                }
                {
                  name = "Swap";
                  bookmarks = [
                    {
                      name =
                        "dApp 1inch - DeFi / DEX aggregator on Ethereum, Binance Smart Chain, Optimism, Polygon, Arbitrum";
                      url = "https://app.1inch.io/#/1/simple/swap/1:ETH";
                    }
                    {
                      name = "ParaSwap - Solving Liquidity for DeFi";
                      url =
                        "https://app.paraswap.xyz/#/swap/0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE/1/SELL?version=6.2&network=ethereum";
                    }
                    {
                      name =
                        "SimpleSwap | Cryptocurrency Exchange | Easy way to swap BTC to ETH, XRP, LTC, EOS, XLM";
                      url = "https://simpleswap.io/";
                    }
                    {
                      name = "Aave - Open Source Liquidity Protocol";
                      url = "https://app.aave.com/";
                    }
                    {
                      name = "Velora - Intents-based Trading Protocol";
                      url = "https://www.velora.xyz/";
                    }
                  ];
                }
                {
                  name = "DCA";
                  bookmarks = [{
                    name = "Balmy — Your Decentralized Home Banking";
                    url = "https://app.balmy.xyz/";
                  }];
                }
                {
                  name = "Impot";
                  bookmarks = [{
                    name = "Waltio";
                    url = "https://tax.waltio.com/dashboard";
                  }];
                }
              ];
            }
            {
              name = "Game";
              bookmarks = [
                {
                  name = "Repacker";
                  bookmarks = [
                    {
                      name =
                        "FitGirl Repacks - The ONLY official site for FitGirl Repacks. Every single FG repack installer has a link inside, which leads here. Do not fall for fake and scam sites, which are using my name.";
                      url = "https://fitgirl-repacks.site/";
                    }
                    {
                      name = "DODI Repacks";
                      url = "https://dodi-repacks.site/";
                    }
                  ];
                }
                {
                  name = "DDL";
                  bookmarks = [{
                    name = "STEAMRIP » Free Pre-installed Steam Games";
                    url = "https://steamrip.com/";
                  }];
                }
                { name = "game watchlist"; }
                {
                  name = "Pirated Games Mega Thread";
                  url = "https://rentry.org/pgames";
                }
                {
                  name = "CS RIN - Steam Underground • Index page";
                  url = "https://cs.rin.ru/forum/";
                }
                {
                  name =
                    "Téléchargement Gratuit | Jean-Luc Mélenchon France Élection présidentielle française, 2017 Europe 1 Humour, france, menton, oreille png | PNGEgg";
                  url = "https://www.pngegg.com/fr/png-kripb/download";
                }
                {
                  name = "YggTorrent - 1er Tracker BitTorrent Francophone";
                  url = "https://www.yggtorrent.top/auth/login";
                }
                {
                  name = "[JySzE] Naruto Shippuden - 104 [v2.5] :: Nyaa";
                  url = "https://nyaa.si/view/1693349";
                }
              ];
            }
            {
              name = "NixOS";
              bookmarks = [
                {
                  name = "Home Manager - Option Search";
                  url = "https://home-manager-options.extranix.com/";
                }
                {
                  name = "NixOS Search - Packages";
                  url = "https://search.nixos.org/packages";
                }
              ];
            }
            {
              name = "Syncthing";
              url = "http://127.0.0.1:8384";
            }
            {
              name = "Home | SeaDex";
              url = "https://releases.moe/";
            }
            {
              name = "LeetCode 75 - Study Plan - LeetCode";
              url = "https://leetcode.com/studyplan/leetcode-75/";
            }
            {
              name = "Claude";
              url = "https://claude.ai/login?returnTo=%2F%3F";
            }
            {
              name = "Partage - Mines-Télécom";
              url = "https://partage.imt.fr/index.php/s/58M4RH2qbJ2SZHi";
            }
            {
              name = "Inscription administrative";
              url =
                "https://e-services.imt-nord-europe.fr/inscription-administrative/index.php?key=lWlnbGo=&itv=0#";
            }
          ];
        }];
      };
      settings = { "extensions.autoDisableScopes" = 0; };
    };
  };
}
