{ config, ... }:

{
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # PipeWire audio server
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true; # Explicitly enable wireplumber
  };
}
