{ config, pkgs, ... }:

{
  # GameMode: A daemon that optimizes system performance on demand
  # When a game starts, it automatically:
  # - Sets the CPU governor to 'performance'
  # - Increases I/O priority for the game process
  # - Disables screen savers
  # - Optimizes GPU performance (on supported drivers)
  programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope.enable = true;

  boot = {
    # Kernel parameters for better gaming responsiveness
    kernelParams = [
      # Disables 'split lock detection' which can cause significant performance
      # stuttering in certain games (especially older ones or via Wine/Proton).
      "split_lock_detect=off"
      
      # Set the kernel preemption model to 'full'. 
      # This makes the system more responsive under load by allowing 
      # the kernel to be interrupted more frequently to handle tasks.
      "preempt=full"
    ];

    kernel.sysctl = {
      # Increase the maximum number of memory maps a process can have.
      # This is essential for modern games (like those on Steam/Proton) 
      # to prevent crashes during heavy memory usage.
      "vm.max_map_count" = 2147483642;
      
      # Reduce the 'swappiness' to prefer keeping data in RAM rather than 
      # moving it to swap space (zram/disk), which is much slower.
      "vm.swappiness" = 10;
    };
  };
}
