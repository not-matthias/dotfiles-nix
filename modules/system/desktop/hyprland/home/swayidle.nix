{pkgs, ...}: let
  _1min = 60;

  # Timeouts for swayidle
  # - Timeout:      1 minute
  # - Lock:         4 minutes
  # - Screen Off:   5 minutes
  # - Suspend:      10 minutes
  notifyTimeout = 1 * _1min;
  lockTimeout = 4 * _1min;
  screenOffTimeout = 5 * _1min;
  suspendTimeout = 10 * _1min;

  displayCmd = status: "${pkgs.hyprland}/bin/hyprctl dispatch dpms ${status}";
  lockCmd = "${pkgs.swaylock}/bin/swaylock --daemonize";
in {
  # Media-aware idle inhibition service
  systemd.user.services.idle-inhibit = {
    Unit = {
      Description = "Idle inhibition for media playback";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.writeShellScript "idle-inhibit" ''
        #!/bin/bash

        # Function to check if audio is playing
        is_audio_playing() {
          # Check if any audio streams are running and not just monitoring
          ${pkgs.wireplumber}/bin/wpctl status | grep -A 20 "Audio" | grep -q "RUNNING"
        }

        # Function to check if video is playing via playerctl
        is_video_playing() {
          # Check if any media player is playing
          ${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q "Playing"
        }

        # Function to send idle inhibition signal to swayidle
        send_inhibit_signal() {
          ${pkgs.procps}/bin/pkill -STOP swayidle 2>/dev/null || true
        }

        # Function to resume swayidle
        resume_swayidle() {
          ${pkgs.procps}/bin/pkill -CONT swayidle 2>/dev/null || true
        }

        inhibit_active=false
        marker_file="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-inhibit-active"

        while true; do
          should_inhibit=false

          # Check various conditions for inhibiting idle
          if is_audio_playing || is_video_playing; then
            should_inhibit=true
          fi

          # Start inhibiting if we should and aren't already
          if [ "$should_inhibit" = true ] && [ "$inhibit_active" = false ]; then
            echo "$(date): Starting idle inhibition (media detected)"
            send_inhibit_signal
            inhibit_active=true
            # Create a marker file for waybar
            touch "$marker_file"
          fi

          # Stop inhibiting if we shouldn't and are currently
          if [ "$should_inhibit" = false ] && [ "$inhibit_active" = true ]; then
            echo "$(date): Stopping idle inhibition (no media detected)"
            resume_swayidle
            inhibit_active=false
            # Remove marker file
            rm -f "$marker_file"
          fi

          sleep 5
        done
      ''}";
      Restart = "always";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = notifyTimeout;
        command = "${pkgs.libnotify}/bin/notify-send 'Locking in 60 seconds' -w";
      }
      {
        timeout = lockTimeout;
        command = lockCmd;
      }
      {
        timeout = screenOffTimeout;
        command = displayCmd "off";
        resumeCommand = displayCmd "on";
      }
      {
        timeout = suspendTimeout;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = (displayCmd "off") + "; " + lockCmd;
      }
      {
        event = "after-resume";
        command = displayCmd "on";
      }
      {
        event = "lock";
        command = (displayCmd "off") + "; " + lockCmd;
      }
      {
        event = "unlock";
        command = displayCmd "on";
      }
    ];
  };
}
