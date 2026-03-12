# Centralized keyboard layout data — single source of truth.
#
# This file is a pure data definition with no NixOS/HM module logic.
# It is imported by:
#   - modules/home/core/keymap.nix    (Neovim langmap, Qutebrowser key_mappings)
#   - modules/home/desktop/quickshell.nix (QuickShell KeyMap.qml)
#
# To add a new language:  add an entry under `layouts` below, rebuild.
#                          All consuming modules pick it up automatically.
{
  ru = {
    lower = {
      "й" = "q";
      "ц" = "w";
      "у" = "e";
      "к" = "r";
      "е" = "t";
      "н" = "y";
      "г" = "u";
      "ш" = "i";
      "щ" = "o";
      "з" = "p";
      "ф" = "a";
      "ы" = "s";
      "в" = "d";
      "а" = "f";
      "п" = "g";
      "р" = "h";
      "о" = "j";
      "л" = "k";
      "д" = "l";
      "я" = "z";
      "ч" = "x";
      "с" = "c";
      "м" = "v";
      "и" = "b";
      "т" = "n";
      "ь" = "m";
    };
    upper = {
      "Й" = "Q";
      "Ц" = "W";
      "У" = "E";
      "К" = "R";
      "Е" = "T";
      "Н" = "Y";
      "Г" = "U";
      "Ш" = "I";
      "Щ" = "O";
      "З" = "P";
      "Ф" = "A";
      "Ы" = "S";
      "В" = "D";
      "А" = "F";
      "П" = "G";
      "Р" = "H";
      "О" = "J";
      "Л" = "K";
      "Д" = "L";
      "Я" = "Z";
      "Ч" = "X";
      "С" = "C";
      "М" = "V";
      "И" = "B";
      "Т" = "N";
      "Ь" = "M";
    };
    punctuation = {
      lower = {
        "х" = "[";
        "ъ" = "]";
        "ж" = ";";
        "э" = "'";
        "б" = ",";
        "ю" = ".";
      };
      upper = {
        "Х" = "{";
        "Ъ" = "}";
        "Ж" = ":";
        "Э" = "\"";
        "Б" = "<";
        "Ю" = ">";
      };
    };
    # Qt key codes for Cyrillic characters used in QML key handlers.
    # Key = Latin physical key name, Value = Qt hex keycode for the Cyrillic char.
    # Add entries here when QuickShell components use new navigation keys.
    qtKeys = {
      "j" = "0x06CF"; # Cyrillic О (physical J)
      "k" = "0x06CC"; # Cyrillic Л (physical K)
    };
  };
}
