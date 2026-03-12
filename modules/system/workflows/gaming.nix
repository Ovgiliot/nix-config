# Gaming workflow — Steam, Gamescope, GameMode, kernel tuning.
# Requires desktop (imports it as a dependency).
{pkgs, ...}: {
  imports = [../desktop];

  programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope.enable = true;

  boot = {
    # Zen kernel for better responsiveness — standard priority (100) overrides
    # server's mkDefault (1000) hardened kernel automatically.
    kernelPackages = pkgs.linuxPackages_zen;

    kernelParams = [
      # Disables 'split lock detection' which can cause significant performance
      # stuttering in certain games (especially older ones or via Wine/Proton).
      "split_lock_detect=off"

      # Full preemption for lower latency under load.
      "preempt=full"
    ];

    kernel.sysctl = {
      # Essential for modern games (Steam/Proton) to prevent crashes.
      "vm.max_map_count" = 2147483642;

      # With zram enabled, high swappiness is preferred: the kernel should
      # eagerly swap to the fast in-memory zram rather than holding everything
      # in RAM.
      "vm.swappiness" = 100;

      # Disable swap readahead clustering — zram decompresses page-by-page.
      "vm.page-cluster" = 0;
    };
  };

  # zram is required for the vm.swappiness = 100 tuning above.
  zramSwap.enable = true;
}
