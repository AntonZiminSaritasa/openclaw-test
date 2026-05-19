#!/usr/bin/env python3
"""OpenClaw email workflow: Gmail (label:OpenClaw) -> Trello cards."""

import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

TRELLO_LIST_ID = "6a07f96eab21b6db18fffb33"
GMAIL_LABEL = "OpenClaw"
URGENT_RE = re.compile(r"URGENT|IMPORTANT", re.IGNORECASE)


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"{' '.join(cmd)} failed (exit {result.returncode}): "
            f"{result.stderr or result.stdout}"
        )
    return result.stdout


def fetch_emails():
    raw = run(["gog", "gmail", "search", f"is:unread label:{GMAIL_LABEL}", "--json"])
    data = json.loads(raw) if raw.strip() else []
    threads = data if isinstance(data, list) else data.get("threads", [])

    emails = []
    for t in threads:
        tid = t.get("id")
        if not tid:
            continue
        full = json.loads(run(["gog", "gmail", "get", tid, "--json"]))
        headers = full.get("headers") or {}
        emails.append({
            "id": tid,
            "subject": headers.get("subject") or t.get("subject") or "(No Subject)",
            "body": full.get("body") or (full.get("message") or {}).get("snippet") or "",
        })
    return emails


def trello_post(path, fields):
    api_key = os.environ["TRELLO_API_KEY"]
    token = os.environ["TRELLO_TOKEN"]
    url = f"https://api.trello.com/1/{path}?key={api_key}&token={token}"
    body = urllib.parse.urlencode(fields).encode()
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        raise RuntimeError(f"Trello {path} failed: HTTP {e.code}: {detail}") from None


def create_card(subject, body):
    return trello_post("cards", {
        "idList": TRELLO_LIST_ID,
        "name": subject,
        "desc": body[:4096],
    })


def set_high_priority(card_id):
    trello_post(f"cards/{card_id}/labels", {"name": "High", "color": "red"})


def mark_read(message_id):
    run(["gog", "gmail", "mark-read", message_id])


def main():
    for var in ("TRELLO_API_KEY", "TRELLO_TOKEN"):
        if not os.environ.get(var):
            sys.exit(f"Missing required env var: {var}")

    emails = fetch_emails()
    for email in emails:
        card = create_card(email["subject"], email["body"])
        if URGENT_RE.search(email["subject"] + " " + email["body"]):
            set_high_priority(card["id"])
        mark_read(email["id"])

    print(json.dumps({"processed": len(emails)}))


if __name__ == "__main__":
    main()
