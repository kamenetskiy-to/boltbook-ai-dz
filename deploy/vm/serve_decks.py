#!/usr/bin/env python3

from __future__ import annotations

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT_DIR = Path("/var/www/boltbook")
ASSET_DIR = ROOT_DIR / "deck-assets"
INDEX_FILE = ROOT_DIR / "index.html"
DECK_ENTRY = ASSET_DIR / "index.html"


class DeckHandler(SimpleHTTPRequestHandler):
    server_version = "BoltbookDeckServer/1.0"

    def do_GET(self) -> None:
        self._serve_request(head_only=False)

    def do_HEAD(self) -> None:
        self._serve_request(head_only=True)

    def _serve_request(self, *, head_only: bool) -> None:
        resolved = self._resolve_path()
        if resolved is None:
            self.send_error(404, "File not found")
            return

        self.path = f"/{resolved.relative_to(ROOT_DIR).as_posix()}"
        if resolved == DECK_ENTRY:
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(resolved.stat().st_size))
            self.end_headers()
            if not head_only:
                with resolved.open("rb") as handle:
                    self.copyfile(handle, self.wfile)
            return

        if head_only:
            self.command = "HEAD"
        return super().do_GET()

    def translate_path(self, path: str) -> str:
        requested = self._requested_path(path)
        if requested == "/":
            return str(INDEX_FILE)
        if requested == "/deck":
            return str(DECK_ENTRY)
        if requested.startswith("/deck-assets/"):
            relative = requested.removeprefix("/deck-assets/")
            return str((ASSET_DIR / relative).resolve())
        return str((ROOT_DIR / "__not_found__").resolve())

    def guess_type(self, path: str) -> str:
        if Path(path) == DECK_ENTRY:
            return "text/html; charset=utf-8"
        return super().guess_type(path)

    def log_message(self, format: str, *args) -> None:
        super().log_message(format, *args)

    def _resolve_path(self) -> Path | None:
        resolved = Path(self.translate_path(self.path))
        try:
            resolved.relative_to(ROOT_DIR)
        except ValueError:
            return None
        if not resolved.exists() or resolved.is_dir():
            return None
        return resolved

    @staticmethod
    def _requested_path(raw_path: str) -> str:
        return unquote(urlparse(raw_path).path)


def main() -> None:
    server = ThreadingHTTPServer(("0.0.0.0", 8080), DeckHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
