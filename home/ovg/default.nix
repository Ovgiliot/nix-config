{ config, pkgs, inputs, ... }:

{
  imports = [
    ./web-apps.nix
  ];

  # Home Manager information
  home.username = "ovg";
  home.homeDirectory = "/home/ovg";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # XDG configuration
  xdg.enable = true;
  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam -cef-disable-gpu -system-composer %U";
    terminal = false;
    icon = "steam";
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  # User packages - GUI applications and development tools
  home.packages = with pkgs; [
    # Environment packages
    xwayland-satellite # For X11 app support in niri
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    waybar
    wofi
    mako
    wl-clipboard
    grim
    slurp
    gemini-cli
    jq
    kanata # For homerow mods
    brightnessctl # For screen brightness control
    swayidle # For idle management (screen dimming, locking)
    swaylock # Screen locker

    # GUI applications
    playerctl # Required for media key bindings in Niri
    bitwarden-desktop
    obsidian
    thunar
    ghostty
    linux-wallpaperengine
    protontricks

    (pkgs.writeShellScriptBin "wifi-menu" ''
      wifi_list=$(nmcli -t -f "SSID,SECURITY,BARS,ACTIVE" device wifi list | sed 's/\\:/--/g')
      formatted_list=$(echo "$wifi_list" | awk -F: '{
          ssid=$1; security=$2; bars=$3; active=$4;
          gsub(/--/, ":", ssid);
          if (ssid == "") next;
          if (active == "yes") printf "CONNECTED: %s (%s) %s\n", ssid, security, bars
          else printf "%s (%s) %s\n", ssid, security, bars
      }' | sort -u)
      chosen=$(echo "$formatted_list" | wofi -dmenu -p "Wi-Fi Networks" -i)
      if [ -n "$chosen" ]; then
          if [[ "$chosen" == CONNECTED:* ]]; then
              ssid=$(echo "$chosen" | sed 's/CONNECTED: //; s/ (.*//')
              nmcli connection down id "$ssid"
          else
              ssid=$(echo "$chosen" | sed 's/ (.*//')
              if nmcli connection show id "$ssid" >/dev/null 2>&1; then
                  nmcli connection up id "$ssid"
              else
                  security=$(echo "$chosen" | sed 's/.*(\(.*\)).*/\1/')
                  if [[ "$security" == "--" || "$security" == "" ]]; then
                      nmcli device wifi connect "$ssid"
                  else
                      password=$(wofi -dmenu -p "Password for $ssid" -P)
                      if [ -n "$password" ]; then
                          nmcli device wifi connect "$ssid" password "$password"
                      fi
                  fi
              fi
          fi
      fi
    '')

    (pkgs.writeShellScriptBin "bluetooth-menu" ''
      power_on=$(bluetoothctl show | grep "Powered: yes" | wc -l)
      if [ "$power_on" -eq 0 ]; then
        action=$(echo -e "Power On\nExit" | wofi -dmenu -p "Bluetooth is Power Off" -i)
        if [ "$action" == "Power On" ]; then
          bluetoothctl power on
        else
          exit
        fi
      fi

      devices=$(bluetoothctl devices | cut -d ' ' -f 2-)
      device_list=""
      while read -r line; do
        mac=$(echo "$line" | cut -d ' ' -f 1)
        name=$(echo "$line" | cut -d ' ' -f 2-)
        info=$(bluetoothctl info "$mac")
        connected=$(echo "$info" | grep "Connected: yes" | wc -l)
        if [ "$connected" -eq 1 ]; then
          device_list+="CONNECTED: $name ($mac)\n"
        else
          device_list+="$name ($mac)\n"
        fi
      done <<< "$devices"

      device_list+="Scan for devices\nPower Off"

      chosen=$(echo -e "$device_list" | wofi -dmenu -p "Bluetooth Devices" -i)

      if [ -n "$chosen" ]; then
        if [ "$chosen" == "Scan for devices" ]; then
          notify-send "Bluetooth" "Scanning for 15 seconds..."
          bluetoothctl scan on &
          sleep 15
          bluetoothctl scan off
          bluetooth-menu
        elif [ "$chosen" == "Power Off" ]; then
          bluetoothctl power off
        else
          mac=$(echo "$chosen" | sed 's/.*(\(.*\))/\1/')
          if [[ "$chosen" == CONNECTED:* ]]; then
            bluetoothctl disconnect "$mac"
          else
            bluetoothctl connect "$mac" || (bluetoothctl pair "$mac" && bluetoothctl connect "$mac")
          fi
        fi
      fi
    '')
  ];

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ovgiliot";
        email = "ovgiliot@gmail.com";
      };
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Shell configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      clean-nix = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      clean-nix = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d";
    };
  };

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };

  # XDG Config Sources
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."nvim".source = ./nvim;
  xdg.configFile."kanata/kanata.kbd".source = ./kanata.kbd;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."ghostty/shaders".source = ./ghostty/shaders;
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  services.network-manager-applet.enable = true;
}
