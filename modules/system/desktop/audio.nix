{
  pkgs,
  lib,
  ...
}: {
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # PipeWire audio server
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # JACK support is added by the music workflow when needed.
    # wireplumber is the default session manager since NixOS 23.05; no need to declare it.
  };

  # Expose GStreamer plugin path so pre-built apps (and any app using
  # GStreamer outside of nix wrappers) can discover audio sinks.
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
  ];
}
