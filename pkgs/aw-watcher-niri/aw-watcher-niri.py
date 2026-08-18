"""ActivityWatch watcher for Niri window manager."""

import argparse
import datetime
import glob
import json
import logging
import os
import select
import signal
import socket
import sys
import time
import urllib.error
import urllib.request

logger = logging.getLogger("aw-watcher-niri")


def parse_args():
    parser = argparse.ArgumentParser(
        description="ActivityWatch watcher for Niri"
    )
    parser.add_argument(
        "--server",
        default=os.environ.get("AW_SERVER_URL", "http://127.0.0.1:5600"),
        help="ActivityWatch server URL (default: http://127.0.0.1:5600)",
    )
    parser.add_argument(
        "--pulsetime",
        type=float,
        default=10.0,
        help="Pulsetime in seconds (default: 10.0)",
    )
    parser.add_argument(
        "--poll-time",
        type=float,
        default=5.0,
        help="Refresh interval in seconds (default: 5.0)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose debug logging",
    )
    return parser.parse_args()


def find_niri_socket():
    sock = os.environ.get("NIRI_SOCKET")
    if sock and os.path.exists(sock):
        return sock
    runtime_dir = os.environ.get(
        "XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"
    )
    candidates = glob.glob(os.path.join(runtime_dir, "niri*.sock"))
    if candidates:
        return candidates[0]
    return None


class ActivityWatchClient:
    def __init__(self, server_url, hostname, pulsetime=10.0):
        self.server_url = server_url.rstrip("/")
        self.hostname = hostname
        self.pulsetime = pulsetime
        self.window_bucket = f"aw-watcher-window_{self.hostname}"
        self.workspace_bucket = f"aw-watcher-workspace-niri_{self.hostname}"
        self._created_buckets = set()

    def ensure_bucket(self, bucket_id, bucket_type):
        if bucket_id in self._created_buckets:
            return True
        url = f"{self.server_url}/api/0/buckets/{bucket_id}"
        payload = {
            "client": "aw-watcher-niri",
            "type": bucket_type,
            "hostname": self.hostname,
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                if resp.status in (200, 304):
                    self._created_buckets.add(bucket_id)
                    logger.debug("Ensured bucket %s", bucket_id)
                    return True
        except urllib.error.HTTPError as e:
            if e.code == 304:
                self._created_buckets.add(bucket_id)
                logger.debug("Bucket %s already exists (304)", bucket_id)
                return True
            logger.warning(
                "Failed to ensure bucket %s: HTTP %s", bucket_id, e.code
            )
            return False
        except (urllib.error.URLError, socket.timeout, ConnectionError) as e:
            logger.warning("Failed to ensure bucket %s: %s", bucket_id, e)
            return False
        return True

    def send_heartbeat(self, bucket_id, data):
        url = (
            f"{self.server_url}/api/0/buckets/{bucket_id}/heartbeat"
            f"?pulsetime={self.pulsetime}"
        )
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        payload = {
            "timestamp": now,
            "duration": 0.0,
            "data": data,
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                return resp.status == 200
        except (urllib.error.URLError, socket.timeout, ConnectionError) as e:
            logger.warning("Failed to send heartbeat to %s: %s", bucket_id, e)
            return False


class NiriWatcher:
    def __init__(self, aw_client, poll_time=5.0):
        self.aw_client = aw_client
        self.poll_time = poll_time
        self.windows = {}
        self.workspaces = {}
        self.running = True
        self.last_window_data = None
        self.last_workspace_data = None
        self.last_heartbeat_time = 0.0

    def stop(self, *_):
        logger.info("Stopping aw-watcher-niri...")
        self.running = False
        sys.exit(0)

    def get_focused_window(self):
        for win in self.windows.values():
            if win.get("is_focused"):
                return {
                    "app": win.get("app_id") or "unknown",
                    "title": win.get("title") or "unknown",
                }
        return {"app": "unknown", "title": "unknown"}

    def get_focused_workspace(self):
        focused_ws = None
        for ws in self.workspaces.values():
            if ws.get("is_focused"):
                focused_ws = ws
                break
        if not focused_ws:
            for ws in self.workspaces.values():
                if ws.get("is_active"):
                    focused_ws = ws
                    break

        if not focused_ws:
            return {
                "name": "unknown",
                "idx": 0,
                "output": "unknown",
                "app": "unknown",
                "title": "unknown",
                "window_count": 0,
            }

        idx = focused_ws.get("idx", 0)
        raw_name = focused_ws.get("name")
        display_name = f"{idx}: {raw_name}" if raw_name else str(idx)
        output = focused_ws.get("output") or "unknown"

        active_win_id = focused_ws.get("active_window_id")
        active_win = (
            self.windows.get(active_win_id) if active_win_id else None
        )
        if active_win:
            app = active_win.get("app_id") or "unknown"
            title = active_win.get("title") or "unknown"
        else:
            app = "none"
            title = "none"

        ws_id = focused_ws.get("id")
        win_count = sum(
            1 for w in self.windows.values() if w.get("workspace_id") == ws_id
        )

        return {
            "name": display_name,
            "idx": idx,
            "output": output,
            "app": app,
            "title": title,
            "window_count": win_count,
        }

    def handle_event(self, event):
        if "WorkspacesChanged" in event:
            self.workspaces = {
                ws["id"]: ws for ws in event["WorkspacesChanged"]["workspaces"]
            }
        elif "WorkspaceActivated" in event:
            act = event["WorkspaceActivated"]
            ws_id = act.get("id")
            if act.get("focused"):
                for ws in self.workspaces.values():
                    ws["is_focused"] = ws["id"] == ws_id
        elif "WorkspaceActiveWindowChanged" in event:
            act = event["WorkspaceActiveWindowChanged"]
            ws_id = act.get("workspace_id")
            win_id = act.get("active_window_id")
            if ws_id in self.workspaces:
                self.workspaces[ws_id]["active_window_id"] = win_id
        elif "WindowsChanged" in event:
            self.windows = {
                win["id"]: win for win in event["WindowsChanged"]["windows"]
            }
        elif "WindowOpenedOrChanged" in event:
            win = event["WindowOpenedOrChanged"]["window"]
            self.windows[win["id"]] = win
            if win.get("is_focused"):
                for w in self.windows.values():
                    if w["id"] != win["id"]:
                        w["is_focused"] = False
        elif "WindowClosed" in event:
            win_id = event["WindowClosed"]["id"]
            self.windows.pop(win_id, None)
        elif "WindowFocusChanged" in event:
            win_id = event["WindowFocusChanged"].get("id")
            for w in self.windows.values():
                w["is_focused"] = w["id"] == win_id

    def dispatch_heartbeats(self, force=False):
        now = time.time()
        cur_win = self.get_focused_window()
        cur_ws = self.get_focused_workspace()

        win_changed = cur_win != self.last_window_data
        ws_changed = cur_ws != self.last_workspace_data
        time_elapsed = (now - self.last_heartbeat_time) >= self.poll_time

        if force or win_changed or ws_changed or time_elapsed:
            self.aw_client.ensure_bucket(
                self.aw_client.window_bucket, "currentwindow"
            )
            self.aw_client.ensure_bucket(
                self.aw_client.workspace_bucket, "workspace"
            )
            self.aw_client.send_heartbeat(
                self.aw_client.window_bucket, cur_win
            )
            self.aw_client.send_heartbeat(
                self.aw_client.workspace_bucket, cur_ws
            )
            self.last_window_data = cur_win
            self.last_workspace_data = cur_ws
            self.last_heartbeat_time = now
            logger.debug(
                "Dispatched heartbeats: win=%s ws=%s", cur_win, cur_ws
            )

    def connect_and_stream(self, sock_path):
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(sock_path)
        sock.sendall(b'"EventStream"\n')
        logger.info("Connected to Niri IPC socket: %s", sock_path)

        buffer = ""
        while self.running:
            self.dispatch_heartbeats()
            readable, _, _ = select.select([sock], [], [], self.poll_time)
            if not readable:
                continue

            chunk = sock.recv(4096)
            if not chunk:
                logger.warning("Niri socket closed by remote")
                break

            buffer += chunk.decode("utf-8", errors="replace")
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line or line == '{"Ok":"Handled"}':
                    continue
                try:
                    event = json.loads(line)
                    self.handle_event(event)
                except json.JSONDecodeError as e:
                    logger.warning(
                        "Failed to decode Niri event line %r: %s", line, e
                    )
            self.dispatch_heartbeats()

        sock.close()

    def run(self):
        signal.signal(signal.SIGINT, self.stop)
        signal.signal(signal.SIGTERM, self.stop)

        while self.running:
            sock_path = find_niri_socket()
            if not sock_path:
                logger.warning("Niri socket not found; retrying in 2s...")
                time.sleep(2)
                continue

            try:
                self.connect_and_stream(sock_path)
            except (
                ConnectionRefusedError,
                FileNotFoundError,
                socket.error,
            ) as e:
                logger.warning("Niri socket error: %s; retrying in 2s...", e)
                time.sleep(2)


def main():
    args = parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    hostname = socket.gethostname()
    aw_client = ActivityWatchClient(
        server_url=args.server,
        hostname=hostname,
        pulsetime=args.pulsetime,
    )
    watcher = NiriWatcher(aw_client, poll_time=args.poll_time)
    watcher.run()


if __name__ == "__main__":
    main()
