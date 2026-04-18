#!/usr/bin/env python3
"""
vmalert -> Discord webhook relay.

vmalert POSTs a JSON array of alerts to us. We transform each alert into a
Discord embed and forward a single payload (max 10 embeds per Discord API).
"""

import json
import logging
import os
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

DISCORD_URL = os.environ["DISCORD_WEBHOOK_URL"]
COLORS = {
    "critical": 15158332,  # red
    "warning": 16776960,  # yellow
    "info": 3447003,  # blue
}

logging.basicConfig(
    stream=sys.stderr,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("discord-relay")


def build_embed(alert: dict) -> dict:
    labels = alert.get("labels", {})
    anns = alert.get("annotations", {})
    severity = labels.get("severity", "info")

    title = anns.get("summary") or labels.get("alertname") or "Alert"
    # Discord rejects embeds with all-empty content fields. Ensure description
    # is never an empty string.
    description = (anns.get("description") or "").strip() or "—"

    return {
        "title": title[:256],  # Discord title max length
        "description": description[:4096],  # Discord description max length
        "color": COLORS.get(severity, COLORS["info"]),
    }


def send_to_discord(embeds: list) -> None:
    payload = json.dumps({"embeds": embeds[:10]}).encode()
    log.info("sending payload: %s", payload.decode())
    req = urllib.request.Request(
        DISCORD_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        log.info("discord accepted %d embeds (status=%d)", len(embeds), resp.status)


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            n = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(n)
            log.info("received %d bytes from %s", n, self.client_address[0])

            alerts = json.loads(raw)
            if not isinstance(alerts, list):
                log.warning("expected JSON array, got %s", type(alerts).__name__)
                self.send_response(400)
                self.end_headers()
                return

            embeds = [build_embed(a) for a in alerts]
            if embeds:
                try:
                    send_to_discord(embeds)
                except urllib.error.HTTPError as e:
                    body = e.read().decode(errors="replace")
                    log.error("discord %d: %s", e.code, body)
                except (urllib.error.URLError, TimeoutError) as e:
                    log.error("discord delivery failed: %s", e)

            self.send_response(200)
            self.end_headers()
        except Exception as e:
            log.exception("unhandled error: %s", e)
            self.send_response(500)
            self.end_headers()

    def log_message(self, fmt, *args):
        # Silence default access log; we do our own.
        pass


if __name__ == "__main__":
    log.info("starting discord relay on :8080")
    HTTPServer(("", 8080), Handler).serve_forever()
