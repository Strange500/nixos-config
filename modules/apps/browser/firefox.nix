{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  serverConfig = inputs.self.nixosConfigurations.Server.config;
  serverDomain = serverConfig.qgroget.server.domain;
  services = serverConfig.qgroget.services;

  # Helper to generate URL
  mkUrl = service: "https://${
    if service.subdomain != ""
    then service.subdomain + "."
    else ""
  }${serverDomain}";

  # Group services
  publicServices = lib.filterAttrs (n: s: s.type == "public" && n != "dashy") services;
  privateServices = lib.filterAttrs (n: s: s.type == "private") services;

  # Specific overrides/additions
  overrides = {
  };

  # Build the dynamic bookmarks
  mkBookmark = name: service:
    if overrides ? ${name}
    then overrides.${name}
    else {
      name = lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
      url = mkUrl service;
    };

  homeBookmarks =
    (lib.mapAttrsToList mkBookmark publicServices)
    ++ [
      {
        name = "Home | QGRoget";
        url = "https://${serverDomain}/";
      }
      {
        name = "Admin";
        bookmarks = lib.mapAttrsToList mkBookmark privateServices;
      }
    ];

  allBookmarks = [
    {
      name = "Home";
      bookmarks = homeBookmarks;
    }
    {
      name = "Game";
      bookmarks = [
        {
          name = "Repacker";
          bookmarks = [
            {
              name = "FitGirl Repacks - The ONLY official site for FitGirl Repacks. Every single FG repack installer has a link inside, which leads here. Do not fall for fake and scam sites, which are using my name.";
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
          bookmarks = [
            {
              name = "STEAMRIP » Free Pre-installed Steam Games";
              url = "https://steamrip.com/";
            }
          ];
        }
        {name = "game watchlist";}
        {
          name = "Pirated Games Mega Thread";
          url = "https://rentry.org/pgames";
        }
        {
          name = "CS RIN - Steam Underground • Index page";
          url = "https://cs.rin.ru/forum/";
        }
        {
          name = "La cale | Cale de Piratage";
          url = "https://la-cale.space/";
        }
        {
          name = "C411";
          url = "https://c411.org/";
        }
      ];
    }
    {
      name = "AI";
      bookmarks = [
        {
          name = "ChatGPT";
          url = "https://chat.openai.com/";
        }
        {
          name = "Gemini";
          url = "https://gemini.google.com/";
        }
        {
          name = "Claude";
          url = "https://claude.ai/";
        }
        {
          name = "Grok";
          url = "https://x.ai/";
        }
        {
          name = "Stitch";
          url = "https://stitch.google.com/";
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
      name = "Home | SeaDex";
      url = "https://releases.moe/";
    }
    {
      name = "ENT IMT NORD EUROPE";
      url = "https://myservices.imt-nord-europe.fr/portail/";
    }
  ];

  # Helper to convert profile-style bookmarks (using 'bookmarks') to policy-style (using 'children')
  toPolicy = bks:
    map (b:
      if b ? bookmarks
      then {
        name = b.name;
        children = toPolicy b.bookmarks;
      }
      else b)
    bks;
in {
  sops.secrets."firefox/certFilePKCS12.p12" = lib.mkIf config.qgroget.nixos.apps.basic {
    format = "binary";
    sopsFile = ../../../secrets/client.p12;
  };
  programs.firefox = lib.mkIf config.qgroget.nixos.apps.basic {
    enable = true;
    configPath = ".mozilla/firefox";
    languagePacks = ["fr_FR"];
    policies = {
      DisableTelemetry = lib.mkForce true;
      DisableFirefoxStudies = lib.mkForce true;
      EnableTrackingProtection = {
        Value = lib.mkForce true;
        Locked = lib.mkForce true;
        Cryptomining = lib.mkForce true;
        Fingerprinting = lib.mkForce true;
      };
      BlockAboutConfig = lib.mkForce false;
      DefaultDownloadDirectory = lib.mkForce "\${home}/Downloads";
      # Password manager logic
      PasswordManagerEnabled = lib.mkForce false;
      OfferToSaveLogins = lib.mkForce false;
      # UI Cleanup
      DisablePocket = lib.mkForce true;
      NoDefaultBookmarks = lib.mkForce true;
      DisplayBookmarksToolbar = lib.mkForce "always";
      ManagedBookmarks = toPolicy allBookmarks;
    };
    profiles.${config.qgroget.user.username} = {
      isDefault = true;
      settings = {
        # specify profile-specific preferences here; check about:config for options
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.startup.homepage" = "https://${config.qgroget.server.domain}";
        "browser.newtabpage.pinned" = [
          {
            title = "QGRoget";
            url = "https://${config.qgroget.server.domain}";
          }
        ];

        # Performance & HW Acceleration
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "widget.dmabuf.force-enabled" = true;

        # Privacy
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "browser.send_pings" = false;
        "dom.event.clipboardevents.enabled" = false; # Prevent websites from interfering with copy/paste

        # UI Tweaks
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1; # Compact
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.aboutConfig.showWarning" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "general.smoothScroll" = true;
        "pdfjs.sidebarViewOnLoad" = 0;
        "browser.download.panel.shown" = true; # Show download panel when a download starts

        # Bitwarden friendly
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "extensions.pocket.enabled" = false;

        # New Tab cleanup
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.default.sites" = "";

        "extensions.autoDisableScopes" = 0;
      };
      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          metamask
          pywalfox
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
        settings = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = allBookmarks;
          }
        ];
      };
    };
  };
}
