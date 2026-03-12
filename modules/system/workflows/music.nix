# Music production workflow — JACK audio, MIDI support, music apps.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  # JACK audio support via PipeWire.
  services.pipewire.jack.enable = true;

  # TODO: MIDI support, low-latency kernel tuning, realtime scheduling.

  home-manager.users.ethel.imports = [
    ../../home/workflows/music.nix
  ];
}
