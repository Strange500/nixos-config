{
  config,
  pkgs,
  ...
}: let
  # Configuration constants
  cfg = {
    uploadLocation = "/mnt/immich";
    port = 2283;
  };

  traefikConfig = {
    bufferLimits = 5000000000;
  };
in {
  services.traefik.dynamicConfigOptions = {
    http.middlewares.immich-limit = {
      buffering = {
        maxRequestBodyBytes = traefikConfig.bufferLimits;
        maxResponseBodyBytes = traefikConfig.bufferLimits;
        memResponseBodyBytes = traefikConfig.bufferLimits;
        memRequestBodyBytes = traefikConfig.bufferLimits;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/immich 0700 immich immich -"
    "d /var/lib/immich/assets 0700 immich immich -"
    "d /var/lib/immich/database 0700 immich immich -"
    "d /var/lib/immich/logs 0700 immich immich -"
    "Z /var/lib/immich 0700 immich immich -"
    "Z ${cfg.uploadLocation} 0700 immich immich -"
  ];

  users.users.immich.extraGroups = ["render" "video"];
  services = {
    immich = {
      enable = true;
      user = "immich";
      group = "immich";
      port = cfg.port;
      accelerationDevices = ["/dev/dri/renderD128"];
      mediaLocation = cfg.uploadLocation;
      database = {
        createDB = true;
        host = "/run/postgresql/"; # Socket path
        name = "immich"; #
        user = "immich"; # User to connect with
      };
      redis.enable = true;
      machine-learning.enable = true;
      settings = {
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
            "http://immich-machine-learning:3003"
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
          buttonText = "Login with OAuth";
          clientId = "ff";
          clientSecret = "ff";
          defaultStorageQuota = 50;
          enabled = true;
          issuerUrl = "https://auth.qgroget.com/application/o/immich/.well-known/openid-configuration";
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
          enabled = true;
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
    };
  };

  qgroget.services.immich = {
    name = "immich";
    url = "https//127.0.0.1:${toString cfg.port}";
    type = "public";
    middlewares = ["immich-limit"];
    journalctl = true;
    unitName = "immich-server.service";
  };

  # qgroget.backups.immich = {
  #   paths = [
  #     ""
  #   ];
  #   systemdUnits = [
  #     "immich-pod.service"
  #   ];
  # };
}
