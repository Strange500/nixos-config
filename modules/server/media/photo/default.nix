{
  config,
  lib,
  ...
}: let
  cfg = {
    uploadLocation = "/mnt/data/immich";
    port = 2283;
  };

  traefikConfig = {
    bufferLimits = 5000000000;
  };

  immichConfig = {
    backup = {
      database = {
        cronExpression = "0 02 * * *";
        enabled = true;
        keepLastAmount = 14;
      };
    };

    ffmpeg = {
      accel = "disabled";
      accelDecode = false;
      acceptedAudioCodecs = [
        "aac"
        "mp3"
        "libopus"
        "pcm_s16le"
      ];
      acceptedContainers = [
        "mov"
        "ogg"
        "webm"
      ];
      acceptedVideoCodecs = [
        "h264"
      ];
      bframes = -1;
      cqMode = "auto";
      crf = 23;
      gopSize = 0;
      maxBitrate = "0";
      preferredHwDevice = "auto";
      preset = "ultrafast";
      refs = 0;
      targetAudioCodec = "aac";
      targetResolution = "720";
      targetVideoCodec = "h264";
      temporalAQ = false;
      threads = 0;
      tonemap = "hable";
      transcode = "required";
      twoPass = false;
    };

    image = {
      colorspace = "p3";
      extractEmbedded = false;
      fullsize = {
        enabled = false;
        format = "jpeg";
        quality = 80;
      };
      preview = {
        format = "jpeg";
        quality = 80;
        size = 1440;
      };
      thumbnail = {
        format = "webp";
        quality = 80;
        size = 250;
      };
    };

    job = {
      backgroundTask = {
        concurrency = 5;
      };
      faceDetection = {
        concurrency = 2;
      };
      library = {
        concurrency = 5;
      };
      metadataExtraction = {
        concurrency = 5;
      };
      migration = {
        concurrency = 5;
      };
      notifications = {
        concurrency = 5;
      };
      search = {
        concurrency = 5;
      };
      sidecar = {
        concurrency = 5;
      };
      smartSearch = {
        concurrency = 2;
      };
      thumbnailGeneration = {
        concurrency = 3;
      };
      videoConversion = {
        concurrency = 1;
      };
    };

    library = {
      scan = {
        cronExpression = "0 0 * * *";
        enabled = true;
      };
      watch = {
        enabled = false;
      };
    };

    logging = {
      enabled = true;
      level = "log";
    };

    machineLearning = {
      clip = {
        enabled = true;
        modelName = "ViT-B-32__openai";
      };
      duplicateDetection = {
        enabled = true;
        maxDistance = 0.01;
      };
      enabled = true;
      facialRecognition = {
        enabled = true;
        maxDistance = 0.5;
        minFaces = 3;
        minScore = 0.7;
        modelName = "buffalo_l";
      };
      urls = [
        "http://127.0.0.1:3003"
      ];
    };

    map = {
      darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
      enabled = true;
      lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
    };

    metadata = {
      faces = {
        import = false;
      };
    };

    newVersionCheck = {
      enabled = true;
    };

    nightlyTasks = {
      clusterNewFaces = true;
      databaseCleanup = true;
      generateMemories = true;
      missingThumbnails = true;
      startTime = "00:00";
      syncQuotaUsage = true;
    };

    notifications = {
      smtp = {
        enabled = false;
        from = "";
        replyTo = "";
        transport = {
          host = "";
          ignoreCert = false;
          password = "";
          port = 587;
          username = "";
        };
      };
    };

    oauth = {
      autoLaunch = true;
      autoRegister = true;
      buttonText = "Login with Authelia";
      clientId = "-ROJj~WXyt3RFIl2s4sCKE3zv45wKOiopJ8wwYiCawYJZ8BNEqnDZQzgZxJ4_5jMstT2bfRU";
      clientSecret = "__SECRET__";
      defaultStorageQuota = 50;
      enabled = true;
      issuerUrl = "https://auth.${config.qgroget.server.domain}/.well-known/openid-configuration";
      mobileOverrideEnabled = true;
      mobileRedirectUri = "https://immich.qgroget.com/api/oauth/mobile-redirect";
      profileSigningAlgorithm = "none";
      roleClaim = "immich_role";
      scope = "openid email profile";
      signingAlgorithm = "RS256";
      storageLabelClaim = "preferred_username";
      storageQuotaClaim = "immich_quota";
      timeout = 30000;
      tokenEndpointAuthMethod = "client_secret_post";
    };

    passwordLogin = {
      enabled = false;
    };

    reverseGeocoding = {
      enabled = true;
    };

    server = {
      externalDomain = "";
      loginPageMessage = "";
      publicUsers = true;
    };

    storageTemplate = {
      enabled = false;
      hashVerificationEnabled = true;
      template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
    };

    templates = {
      email = {
        albumInviteTemplate = "";
        albumUpdateTemplate = "";
        welcomeTemplate = "";
      };
    };

    theme = {
      customCss = "";
    };

    trash = {
      days = 30;
      enabled = true;
    };

    user = {
      deleteDelay = 7;
    };
  };
in {
  qgroget.services.immich.traefikDynamicConfig = {
    http.middlewares.immich-limit = {
      buffering = {
        maxRequestBodyBytes = traefikConfig.bufferLimits;
        maxResponseBodyBytes = traefikConfig.bufferLimits;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "Z ${cfg.uploadLocation} 0700 immich immich -"
    "Z ${config.qgroget.server.containerDir}/immich-pg/data 0700 immich-pg immich -"
  ];

  qgroget.services.immich = {
    name = "immich";
    url = "http://[::1]:${toString cfg.port}";
    type = "public";
    middlewares = ["immich-limit"];
    journalctl = true;
    unitName = "immich-server.service";
  };

  users.users.immich.extraGroups = ["render" "video"];

  services.immich = {
    enable = true;
    port = cfg.port;
    mediaLocation = cfg.uploadLocation;
    machine-learning.enable = true;
    accelerationDevices = ["/dev/dri/renderD128"];
    database = {
      createDB = false;
      enable = false;
      host = "localhost";
      port = 5433;
      user = "immich";
      name = "immich";
    };
    secretsFile = "${config.sops.secrets."server/immich/env".path}";
    # IMPORTANT: Don't emit a config.json into /nix/store; we'll write it at runtime.
    settings = null;

    # Point Immich at our runtime JSON.
    environment = {
      IMMICH_CONFIG_FILE = "/run/immich/immich.json";
    };
  };

  users.users.immich-pg = {
    isSystemUser = true;
    description = "User for running Immich Postgres";
    uid = 985;
    home = "/nonexistent";
    createHome = false;
    group = "immich";
  };
  users.groups.immich = {
    gid = 985;
  };

  virtualisation.quadlet = {
    containers = {
      immich-pg = {
        autoStart = true;
        containerConfig = {
          name = "immich-pg";
          user = "${toString config.users.users.immich-pg.uid}:${toString config.users.groups.immich.gid}";
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
          publishPorts = [
            "5433:5432"
          ];
          volumes = [
            "${config.qgroget.server.containerDir}/immich-pg/data:/var/lib/postgresql/data:rw"
          ];
          environmentFiles = [
            "${config.sops.secrets."server/immich/env".path}"
          ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          Before = ["immich-server.service"];
        };
      };
    };
  };

  sops.secrets = {
    "server/immich/oidc-client-secret" = {
      owner = "root";
      mode = "0400";
    };
    "server/immich/env" = {
    };
  };

  #    Inject it into the immich-server service as a systemd credential and
  #    render the full config file in preStart, splicing the secret in on-the-fly.
  systemd.services."immich-server" = {
    serviceConfig.LoadCredential = lib.mkAfter [
      "oidc_secret:${config.sops.secrets."server/immich/oidc-client-secret".path}"
    ];

    preStart = lib.mkAfter ''
      set -eu
      cred="$CREDENTIALS_DIRECTORY/oidc_secret"
      if [ ! -s "$cred" ]; then
        echo "[immich] Missing OIDC secret at $cred" >&2
        exit 1
      fi

      secret="$(cat "$cred")"

      install -d -m0750 -o ${config.services.immich.user} -g ${config.services.immich.group} /run/immich

      # Render the entire Immich configuration as JSON (single source of truth)
      cat > /run/immich/immich.json <<'JSON'
      ${builtins.toJSON immichConfig}
      JSON

      sed -i "s#__SECRET__#''${secret}#g" /run/immich/immich.json
      chown ${config.services.immich.user}:${config.services.immich.group} /run/immich/immich.json
      chmod 0400 /run/immich/immich.json
    '';
  };

  services.authelia.instances.qgroget.settings = {
    identity_providers.oidc = {
      clients = [
        {
          client_id = "-ROJj~WXyt3RFIl2s4sCKE3zv45wKOiopJ8wwYiCawYJZ8BNEqnDZQzgZxJ4_5jMstT2bfRU";
          client_name = "immich";
          client_secret = "$pbkdf2-sha512$310000$68J8cdUIgTQdQx8v6owFtg$yoTMLBrY3tOm7ULtH2G5.EcbFUIuDjsIKY9QgWljkLHA3GIjZVjIPcVYXj2TvAlVXA8htFbtijEWYO5fy0EnJQ";
          public = false;
          consent_mode = "auto";
          pre_configured_consent_duration = "1 week";
          authorization_policy = "immich";
          require_pkce = false;
          pkce_challenge_method = "";
          redirect_uris = [
            "https://immich.${config.qgroget.server.domain}/auth/login"
            "https://immich.${config.qgroget.server.domain}/user-settings"
            "app.immich:///oauth-callback"
            "app.immich:/"
            "https://immich.${config.qgroget.server.domain}/api/oauth/mobile-redirect"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [
            "code"
          ];
          grant_types = [
            "authorization_code"
          ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
      cors.allowed_origins = [
        "https://immich.${config.qgroget.server.domain}"
      ];
      authorization_policies = {
        immich = {
          default_policy = "deny";
          rules = [
            {
              policy = "two_factor";
              subject = [
                "group:immich"
              ];
            }
          ];
        };
      };
    };
  };
}
