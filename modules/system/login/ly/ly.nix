{
  inputs,
  pkgs,
  config,
  ...
}: {
  services.displayManager.ly = {
    enable = true;
    settings = {
      numlock = true;
      animation = "matrix";
    };
  };
}
# The color settings in Ly take a digit 0-8 corresponding to:
#define TB_DEFAULT 0x00
#define TB_BLACK   0x01
#define TB_RED     0x02
#define TB_GREEN   0x03
#define TB_YELLOW  0x04
#define TB_BLUE    0x05
#define TB_MAGENTA 0x06
#define TB_CYAN    0x07
#define TB_WHITE   0x08
# The default color varies, but usually it makes the background black and the foreground white.
# You can also combine these colors with the following style attributes using bitwise OR:
#define TB_BOLD      0x0100
#define TB_UNDERLINE 0x0200
#define TB_REVERSE   0x0400
#define TB_ITALIC    0x0800
#define TB_BLINK     0x1000
#define TB_HI_BLACK  0x2000
#define TB_BRIGHT    0x4000
#define TB_DIM       0x8000
# For example, to set the foreground color to red and bold, you would do 0x02 | 0x0100 = 0x0102.
# Note that you must pre-calculate the value because Ly doesn't parse bitwise OR operations in its config.
#
# Moreover, to set the VT color palette, you are encouraged to use another tool such as
# mkinitcpio-colors (https://github.com/evanpurkhiser/mkinitcpio-colors). Note that the color palette defined with
# mkinitcpio-colors takes 16 colors (0-15), only values 0-8 are valid with Ly and these values do not correspond
# exactly. For instance, in defining palettes with mkinitcpio-colors, the order is black, dark red, dark green, brown, dark
# blue, dark purple, dark cyan, light gray, dark gray, bright red, bright green, yellow, bright blue, bright purple, bright
# cyan, and white, indexed in that order 0 through 15. For example, the color defined for white (indexed at 15 in the mkinitcpio
# config) will be used by Ly for fg = 0x0008.
# The active animation
# none   -> Nothing
# doom   -> PSX DOOM fire
# matrix -> CMatrix
# animation = none
# # Stop the animation after some time
# # 0 -> Run forever
# # 1..2e12 -> Stop the animation after this many seconds
# animation_timeout_sec = 0
# # The character used to mask the password
# # If null, the password will be hidden
# # Note: you can use a # by escaping it like so: \#
# asterisk = *
# # The number of failed authentications before a special animation is played... ;)
# auth_fails = 10
# # Background color id
# bg = 0x0000
# # Change the state and language of the big clock
# # none -> Disabled (default)
# # en   -> English
# # fa   -> Farsi
# bigclock = none
# # Blank main box background
# # Setting to false will make it transparent
# blank_box = true
# # Border foreground color id
# border_fg = 0x0008
# # Title to show at the top of the main box
# # If set to null, none will be shown
# box_title = null
# # Brightness increase command
# brightness_down_cmd = $PREFIX_DIRECTORY/bin/brightnessctl -q s 10%-
# # Brightness decrease key
# brightness_down_key = F5
# # Brightness increase command
# brightness_up_cmd = $PREFIX_DIRECTORY/bin/brightnessctl -q s +10%
# # Brightness increase key
# brightness_up_key = F6
# # Erase password input on failure
# clear_password = false
# # Format string for clock in top right corner (see strftime specification). Example: %c
# # If null, the clock won't be shown
# clock = null
# # CMatrix animation foreground color id
# cmatrix_fg = 0x0003
# # Console path
# console_dev = /dev/console
# # Input box active by default on startup
# # Available inputs: info_line, session, login, password
# default_input = login
# # Error background color id
# error_bg = 0x0000
# # Error foreground color id
# # Default is red and bold: TB_RED | TB_BOLD
# error_fg = 0x0102
# # Foreground color id
# fg = 0x0008
# # Remove main box borders
# hide_borders = false
# # Remove power management command hints
# hide_key_hints = false
# # Initial text to show on the info line
# # If set to null, the info line defaults to the hostname
# initial_info_text = null
# # Input boxes length
# input_len = 34
# # Active language
# # Available languages are found in $CONFIG_DIRECTORY/ly/lang/
# lang = en
# # Load the saved desktop and username
# load = true
# # Command executed when logging in
# # If null, no command will be executed
# # Important: the code itself must end with `exec "$@"` in order to launch the session!
# # You can also set environment variables in there, they'll persist until logout
# login_cmd = null
# # Command executed when logging out
# # If null, no command will be executed
# # Important: the session will already be terminated when this command is executed, so
# # no need to add `exec "$@"` at the end
# logout_cmd = null
# # Main box horizontal margin
# margin_box_h = 2
# # Main box vertical margin
# margin_box_v = 1
# # Event timeout in milliseconds
# min_refresh_delta = 5
# # Set numlock on/off at startup
# numlock = false
# # Default path
# # If null, ly doesn't set a path
# path = /sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
# # Command executed when pressing restart_key
# restart_cmd = /sbin/shutdown -r now
# # Specifies the key used for restart (F1-F12)
# restart_key = F2
# # Save the current desktop and login as defaults
# save = true
# # Service name (set to ly to use the provided pam config file)
# service_name = ly
# # Session log file path
# # This will contain stdout and stderr of X11 and Wayland sessions
# # By default it's saved in the user's home directory
# # Note: this file won't be used in a shell session (due to the need of stdout and stderr)
# session_log = ly-session.log
# # Setup command
# setup_cmd = $CONFIG_DIRECTORY/ly/setup.sh
# # Command executed when pressing shutdown_key
# shutdown_cmd = /sbin/shutdown -a now
# # Specifies the key used for shutdown (F1-F12)
# shutdown_key = F1
# # Command executed when pressing sleep key (can be null)
# sleep_cmd = null
# # Specifies the key used for sleep (F1-F12)
# sleep_key = F3
# # Center the session name.
# text_in_center = false
# # TTY in use
# tty = $DEFAULT_TTY
# # Default vi mode
# # normal   -> normal mode
# # insert   -> insert mode
# vi_default_mode = normal
# # Enable vi keybindings
# vi_mode = false
# # Wayland desktop environments
# waylandsessions = $PREFIX_DIRECTORY/share/wayland-sessions
# # Xorg server command
# x_cmd = $PREFIX_DIRECTORY/bin/X
# # Xorg xauthority edition tool
# xauth_cmd = $PREFIX_DIRECTORY/bin/xauth
# # xinitrc
# # If null, the xinitrc session will be hidden
# xinitrc = ~/.xinitrc
# # Xorg desktop environments
# xsessions = $PREFIX_DIRECTORY/share/xsessions

