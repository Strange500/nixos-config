{
  pkgs,
  config,
  hostname,
  ...
}: {
  programs.kodi = {
    enable = true;
    package = pkgs.kodi-gbm.withPackages (p: [
      p.inputstream-adaptive
      p.jellycon
      p.youtube
    ]);

    # settings = { videolibrary.showemptytvshows = "true"; }
    # ;

    addonSettings = {
      "plugin.video.jellycon" = {
        ipaddress = "true";
        protocol = "0";
        port = "8096";
        server_address = "https://jellyfin.${config.qgroget.server.domain}";
        verify_cert = "true";
        username = "la mom";
        save_user_to_settings = "true";
        allow_password_saving = "true";
        play_cinema_intros = "true";
        max_stream_bitrate = "24";
        allow_direct_file_play = "true";
        force_transcode_h265 = "false";
        force_transcode_mpeg2 = "false";
        force_transcode_msmpeg4v3 = "false";
        force_transcode_mpeg4 = "false";
        force_transcode_av1 = "false";
        direct_stream_sub_select = "0";
        force_max_stream_bitrate = "24";
        playback_max_width = "4096";
        playback_video_force_8 = "false";
        audio_codec = "ac3";
        audio_playback_bitrate = "256";
        audio_max_channels = "8";
        max_play_queue = "200";
        play_next_trigger_time = "0";
        promptPlayNextEpisodePercentage = "90";
        promptPlayNextEpisodePercentage_prompt = "true";
        promptDeleteEpisodePercentage = "100";
        promptDeleteMoviePercentage = "100";
        forceAutoResume = "true";
        jump_back_amount = "15";
        stopPlaybackOnScreensaver = "true";
        changeUserOnScreenSaver = "false";
        cacheImagesOnScreenSaver = "true";
        cacheImagesOnScreenSaver_interval = "0";
        addCounts = "false";
        addResumePercent = "false";
        addSubtitleAvailable = "false";
        hide_x_filtered_items_count = "true";
        include_overview = "true";
        include_media = "true";
        add_user_ratings = "true";
        include_people = "false";
        hide_unwatched_details = "false";
        episode_name_format = "{SeriesName} - {ItemName}";
        group_movies = "true";
        flatten_single_season = "true";
        show_all_episodes = "true";
        show_empty_folders = "false";
        hide_watched = "true";
        rewatch_days = "0";
        rewatch_combine = "false";
        moviePageSize = "0";
        show_x_filtered_items = "60";
        widget_select_action = "1";
        interface_mode = "0";
        websocket_enabled = "true";
        override_contextmenu = "true";
        background_interval = "20";
        new_content_check_interval = "0";
        simple_new_content_check = "true";
        random_movie_refresh_interval = "5";
        deviceName = "JellyCon - ${hostname}";
        http_timeout = "60";
        profile_count = "0";
        log_debug = "false";
        log_timing = "false";
        use_cache = "true";
        use_cached_widget_data = "false";
        showLoadProgress = "true";
        suppressErrors = "false";
        speed_test_data_size = "10";
        view-movies = "true";
        view-tvshows = "true";
        view-seasons = "true";
        view-episodes = "true";
        view-sets = "true";
        sort-Movies = "0";
        sort-BoxSets = "0";
        sort-Series = "0";
        sort-Seasons = "0";
        sort-Episodes = "0";
      };
    };
  };
}
