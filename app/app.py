"""방명록 웹앱 (표준 라이브러리 + psycopg2).

DB 접속 정보 우선순위
1. DB_SECRET_ARN 이 있으면 Secrets Manager 에서 JSON(host, port, dbname, username, password)을 읽는다.
   EC2(Floci) 안에서는 AWS_ENDPOINT_URL 이 Floci 를 가리키도록 자동 주입된다.
2. 없으면 DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD 환경변수를 쓴다 (로컬 Docker 개발용).

엔드포인트
- GET  /        방명록 목록 + 작성 폼 (응답한 서버의 호스트명과 앱 버전 표시)
- POST /entries 글 작성
- GET  /health  {"status", "db", "host", "version"} — ALB 헬스체크용
"""

import html
import json
import os
import socket
import threading
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

import psycopg2

APP_VERSION = os.environ.get("APP_VERSION", "dev")
HOSTNAME = socket.gethostname()
PORT = int(os.environ.get("PORT", "8000"))

_db_config = None
_db_lock = threading.Lock()


def db_config():
    """DB 접속 정보를 한 번만 읽어 캐시한다."""
    global _db_config
    if _db_config is not None:
        return _db_config
    secret_arn = os.environ.get("DB_SECRET_ARN")
    if secret_arn:
        import boto3  # EC2 에서만 필요

        client = boto3.client("secretsmanager", region_name=os.environ.get("AWS_REGION", "us-east-1"))
        secret = json.loads(client.get_secret_value(SecretId=secret_arn)["SecretString"])
        _db_config = {
            "host": secret["host"],
            "port": int(secret["port"]),
            "dbname": secret["dbname"],
            "user": secret["username"],
            "password": secret["password"],
        }
    else:
        _db_config = {
            "host": os.environ.get("DB_HOST", "localhost"),
            "port": int(os.environ.get("DB_PORT", "5432")),
            "dbname": os.environ.get("DB_NAME", "guestbook"),
            "user": os.environ.get("DB_USER", "app"),
            "password": os.environ.get("DB_PASSWORD", ""),
        }
    return _db_config


@contextmanager
def cursor():
    """요청마다 연결을 열고 반드시 닫는다 (psycopg2 의 with conn 은 연결을 닫지 않음)."""
    conn = psycopg2.connect(connect_timeout=3, **db_config())
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            yield cur
    finally:
        conn.close()


def ensure_schema():
    with _db_lock, cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS entries (
                id         SERIAL PRIMARY KEY,
                name       TEXT NOT NULL,
                message    TEXT NOT NULL,
                host       TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )


def list_entries(limit=20):
    with cursor() as cur:
        cur.execute(
            "SELECT name, message, host, created_at FROM entries ORDER BY id DESC LIMIT %s",
            (limit,),
        )
        return cur.fetchall()


def add_entry(name, message):
    with cursor() as cur:
        cur.execute(
            "INSERT INTO entries (name, message, host) VALUES (%s, %s, %s)",
            (name[:50], message[:500], HOSTNAME),
        )


PAGE = """<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><title>Guestbook</title>
<style>
body{{font-family:system-ui,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;color:#222}}
.meta{{color:#666;font-size:.9rem}} li{{margin:.6rem 0}} input,textarea{{width:100%;margin:.2rem 0 .6rem}}
.err{{color:#b00}}
</style></head><body>
<h1>방명록</h1>
<p class="meta">응답 서버 <b>{host}</b> · 버전 <b>{version}</b></p>
<form method="post" action="/entries">
<input name="name" placeholder="이름" required maxlength="50">
<textarea name="message" placeholder="메시지" required maxlength="500"></textarea>
<button type="submit">남기기</button>
</form>
{body}
</body></html>"""


class Handler(BaseHTTPRequestHandler):
    server_version = "guestbook"

    def _send(self, status, body, content_type="text/html; charset=utf-8", headers=None):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Served-By", HOSTNAME)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/health":
            db = "ok"
            try:
                with cursor() as cur:
                    cur.execute("SELECT 1")
            except Exception as exc:  # noqa: BLE001 - 헬스체크는 원인만 보고
                db = f"error: {exc.__class__.__name__}"
            payload = {"status": "ok", "db": db, "host": HOSTNAME, "version": APP_VERSION}
            self._send(200, json.dumps(payload), "application/json")
            return

        if self.path != "/":
            self._send(404, "not found", "text/plain; charset=utf-8")
            return

        try:
            ensure_schema()
            rows = list_entries()
            items = "".join(
                f"<li><b>{html.escape(n)}</b>: {html.escape(m)}"
                f' <span class="meta">({html.escape(h)}, {c:%Y-%m-%d %H:%M})</span></li>'
                for n, m, h, c in rows
            )
            body = f"<ul>{items}</ul>" if items else "<p>아직 글이 없습니다.</p>"
        except Exception as exc:  # noqa: BLE001
            body = f'<p class="err">DB 연결 실패: {html.escape(exc.__class__.__name__)}</p>'
        self._send(200, PAGE.format(host=HOSTNAME, version=APP_VERSION, body=body))

    def do_POST(self):
        if self.path != "/entries":
            self._send(404, "not found", "text/plain; charset=utf-8")
            return
        length = int(self.headers.get("Content-Length", "0"))
        form = parse_qs(self.rfile.read(length).decode("utf-8"))
        name = form.get("name", [""])[0].strip()
        message = form.get("message", [""])[0].strip()
        if name and message:
            ensure_schema()
            add_entry(name, message)
        self._send(303, "", headers={"Location": "/"})

    def log_message(self, fmt, *args):
        print(f"[{HOSTNAME}] {self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"guestbook {APP_VERSION} listening on 0.0.0.0:{PORT} ({HOSTNAME})", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
