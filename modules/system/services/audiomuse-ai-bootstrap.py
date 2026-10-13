"""Apply Nix-managed settings through AudioMuse's persistence helpers."""

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, "/app")

import config
from app_auth import USER_ROLE_ADMIN, upsert_admin_user, verify_additional_user
from database import close_db, init_db
from flask_app import app
from tasks.mediaserver import registry
from tasks.setup_manager import setup_manager

settings = json.loads(Path(sys.argv[1]).read_text())
secret_keys = ("API_TOKEN", "JWT_SECRET")

with app.app_context():
    init_db()
    values = {
        key: setup_manager.cast_value(getattr(config, key), value)
        for key, value in settings.items()
        if key not in config.MEDIASERVER_CONFIG_KEYS
        and key not in config.SETUP_BOOTSTRAP_EXCLUDED_KEYS
    }
    values.update({key: os.environ[key] for key in secret_keys})
    setup_manager.save_config_values(values)
    registry.save_default_server_settings(
        "navidrome",
        {
            "url": settings["NAVIDROME_URL"],
            "user": settings["NAVIDROME_USER"],
            "password": os.environ["NAVIDROME_PASSWORD"],
            "api_key": "",
        },
        settings["MUSIC_LIBRARIES"],
    )
    server = registry.get_default_server()
    registry.update_server(server["server_id"], name="Navidrome")
    username = settings["AUDIOMUSE_USER"]
    password = os.environ["AUDIOMUSE_PASSWORD"]
    if verify_additional_user(username, password) != USER_ROLE_ADMIN:
        ok, error = upsert_admin_user(username, password)
        if not ok:
            raise RuntimeError(error)
    close_db()

print("Applied Nix-managed AudioMuse settings and Navidrome connection.")
