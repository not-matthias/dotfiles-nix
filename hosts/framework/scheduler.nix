{
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    extraArgs = [
      "--primary-domain" # -m
      "performance"
      # Disable direct dispatch during synchronous wakeups.
      # Enabling this option can lead to a more uniform load distribution across available cores, potentially improving performance in certain scenarios. However, it may come at the cost of reduced efficiency for pipe-intensive workloads that benefit from tighter producer-consumer coupling.
      "--no-wake-sync" # -w
      # Enable CPU frequency control (only with schedutil governor).
      # With this option enabled the CPU frequency will be automatically scaled based on the load.
      "--cpufreq" # -f
      # Enable per-CPU tasks prioritization.
      # This allows to prioritize per-CPU tasks that usually tend to be de-prioritized (since they can't be migrated when their only usable CPU is busy). Enabling this option can introduce unfairness and potentially trigger stalls, but it can improve performance of server-type workloads (such as large parallel builds).
      "--local-pcpu" # -p
      # Enable kthreads prioritization (EXPERIMENTAL).
      # Enabling this can improve system performance, but it may also introduce noticeable interactivity issues or unfairness in scenarios with high kthread activity, such as heavy I/O or network traffic. Use it only when conducting specific experiments or if you have a clear understanding of its implications.
      "--local-kthreads" # -k
    ];
  };
}
