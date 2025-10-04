{pkgs, ...}:
pkgs.writeShellApplication {
  name = "qgroget-steam-import";
  runtimeInputs = with pkgs; [
    steamtinkerlaunch
    steam-rom-manager
    xvfb-run
  ];
  text = ''
    if [ "$#" -ne 3 ]; then
      echo "Usage: $0 <game_name> <exe_path> <start_dir>"
      exit 1
    fi

    GAME_NAME="$1"
    EXE_PATH="$2"
    START_DIR="$3"

    xvfb-run steamtinkerlaunch ansg -an="$GAME_NAME" -ep="$EXE_PATH" -sd="$START_DIR" || true
    xvfb-run steam-rom-manager add
  '';
}
