{
  lib,
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [fzf fastfetch delta neovide];

  programs.fastfetch = {
    enable = true;
    settings = {
      modules = [
        "title"
        "separator"
        "os"
        "host"
        {
          type = "kernel";
          format = "{release}";
        }
        "uptime"
        "packages"
        "shell"
        {
          type = "display";
          compactType = "original";
          key = "Resolution";
        }
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "terminal"
        {
          type = "terminalfont";
          format = "{/name}{-}{/}{name}{?size} {size}{?}";
        }
        "cpu"
        {
          type = "gpu";
          key = "GPU";
        }
        {
          type = "memory";
          format = "{} / {}";
        }
        "break"
        "colors"
      ];
    };
  };

  programs.atuin = {
    enable = true;
    settings = {
      style = "full";
      inline_height = 40;
      show_preview = true;
      enter_accept = true;
    };
  };

  # This isn't working with starship currently
  # programs.thefuck = {
  #   enable = true;
  #   enableInstantMode = true;
  # };

  programs.bat = {
    enable = true;
    config = {pager = "less -FR";};
  };

  programs.btop = {enable = true;};

  programs.git = {
    enable = true;

    userName = "Benjamin Roget";
    userEmail = "benjamin.rogetpro@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      credential.helper = "store";
      diff = {
        tool = "delta";
        colorMoved = "default";
      };
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictstyle = "diff3";
    };
  };

  programs.lazygit = {enable = true;};

  programs.eza = {
    enable = true;
    extraOptions = [
      "-a"
      "-l"
      "-h"
      "--color=always"
      "--icons=always"
      "--mounts"
      "--git"
      "--git-repos"
    ];
  };

  programs.yazi = {enable = true;};

  programs.zoxide = {enable = true;};

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {EDITOR = "lvim";};
    initContent = ''
      fastfetch
      function y() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
       yazi "$@" --cwd-file="$tmp"
      	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
       builtin cd -- "$cwd"
       fi
       rm -f -- "$tmp"
       }'';
    shellAliases = {
      y = "yazi";
      cat = "bat";
      lg = "lazygit";
      nano = "lvim";
      vim = "lvim";
      ls = "eza";
      update = "sudo nixos-rebuild switch --flake ~/nixos#$HOSTNAME";

      # Network tools reminders
      traceroute = "echo 'Use trip instead'";
      mtr = "echo 'Use trip instead'";
    };

    oh-my-zsh = {
      enable = true;
      plugins = ["z" "fzf" "git" "extract"];
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$os $directory $git_branch $git_status $fill $python $lua $nodejs $golang $haskell $rust $ruby $package $aws $docker_context $jobs $cmd_duration $line_break $character";

      os = {
        disabled = false;
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          NixOS = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:color_orange fg:color_fg0";
        style_root = "bg:color_orange fg:color_fg0";
        format = "[ $user ]($style)";
      };

      directory = {
        style = "bold fg:dark_blue";
        format = "[$path ]($style)";
        truncation_length = 3;
        truncation_symbol = ".../";

        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
        };
      };

      git_branch = {
        symbol = " ";
        style = "fg:green";
        format = "[on](white) [$symbol$branch ]($style)";
      };

      git_status = {
        style = "fg:green";
        format = "([$all_status$ahead_behind]($style) )";
      };

      fill = {symbol = " ";};

      nodejs = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = " ";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = " ";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        symbol = "";
        style = "blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      conda = {
        style = "bg:color_bg3";
        format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      jobs = {
        symbol = " ";
        style = "red";
        number_threshold = 1;
        format = "[$symbol]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1";
        format = "[[ $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break.disabled = false;

      cmd_duration = {
        min_time = 500;
        style = "fg:gray";
        format = "[$duration]($style)";
      };

      palettes.nord = {
        dark_blue = "#5E81AC";
        blue = "#81A1C1";
        teal = "#88C0D0";
        red = "#BF616A";
        orange = "#D08770";
        green = "#A3BE8C";
        yellow = "#EBCB8B";
        purple = "#B48EAD";
        gray = "#434C5E";
        black = "#2E3440";
        white = "#D8DEE9";
      };

      palettes.onedark = {
        dark_blue = "#61afef";
        blue = "#56b6c2";
        red = "#e06c75";
        green = "#98c379";
        purple = "#c678dd";
        cyan = "#56b6c2";
        orange = "#be5046";
        yellow = "#e5c07b";
        gray = "#828997";
        white = "#abb2bf";
        black = "#2c323c";
      };
    };
  };
}
