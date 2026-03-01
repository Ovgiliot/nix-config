{...}: {
  # Disable kexec (can bypass disk encryption at runtime) and enforce PTI.
  security.protectKernelImage = true;
  security.forcePageTableIsolation = true;

  # MAC confinement via AppArmor.
  security.apparmor.enable = true;

  # Kernel boot hardening parameters.
  boot.kernelParams = [
    "init_on_alloc=1" # zero memory on allocation (prevents info leaks)
    "slab_nomerge" # prevent slab cache merging (type confusion mitigation)
    "page_alloc.shuffle=1" # randomize page allocator free lists
    "vsyscall=none" # disable legacy vsyscall interface (attack surface)
    "debugfs=off" # hide kernel internals from /sys/kernel/debug
  ];

  boot.kernel.sysctl = {
    # Kernel hardening
    "kernel.dmesg_restrict" = 1; # restrict dmesg to root
    "kernel.kptr_restrict" = 2; # hide kernel pointer addresses
    "kernel.perf_event_paranoid" = 3; # restrict perf events to root
    "kernel.unprivileged_bpf_disabled" = 1; # restrict eBPF to root
    "net.core.bpf_jit_harden" = 2; # harden BPF JIT compiler
    "kernel.yama.ptrace_scope" = 1; # ptrace parent→child only (compatible with gdb/strace)
    "kernel.sysrq" = 0; # disable SysRq entirely

    # Network hardening
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.rp_filter" = 1; # reverse path filtering
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1; # SYN flood protection

    # Filesystem hardening
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
  };
}
