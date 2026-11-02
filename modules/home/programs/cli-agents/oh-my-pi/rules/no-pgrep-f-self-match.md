---
name: no-pgrep-f-self-match
description: "Never wait on a process with `pgrep -f`, because it matches the shell or ssh command line running the loop"
condition: "\\bpgrep\\b[^|;&\\n]*\\s-[a-zA-Z]*f"
scope: "tool:bash"
---

<!-- Source: https://github.com/GuillaumeLagrange/dotfiles/commit/8261afc47616e81de33d9c1ac4ff0d0b94ec72ff -->

`pgrep -f <pattern>` matches against full command lines. That includes the `bash -c` or ssh remote command that contains the loop, because the pattern appears in it. A `while pgrep -f ...; do sleep; done` wait therefore finds itself and never exits, and a status check reports RUNNING forever.

Use one of these instead:
- Record the PID when you launch the process (`setsid nohup cmd > log 2>&1 < /dev/null & echo $! > /root/job.pid`), then wait with `while kill -0 "$(cat /root/job.pid)" 2>/dev/null; do sleep 5; done`.
- Match the exact process name with `pgrep -x <comm>` (for example `pgrep -x curl`), never `-f`.
- Wait for a completion marker the job writes, such as `until grep -q 'not rebooting' /root/install.log; do sleep 5; done`, and also check for a failure marker.

If you really need `-f`, make sure the pattern cannot appear in your own command line, for example with the `[i]nstall.sh` bracket trick.
