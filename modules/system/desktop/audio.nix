{...}: {
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # PipeWire audio server
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # wireplumber is the default session manager since NixOS 23.05; no need to declare it.
  };
}
