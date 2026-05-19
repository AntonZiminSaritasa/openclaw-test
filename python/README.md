# Python script

A single-file imperative implementation in [email_workflow.py](email_workflow.py). Standard-library only — no third-party dependencies.

## How it works

`main()` does, in order:

1. Verifies `TRELLO_API_KEY` and `TRELLO_TOKEN` are set.
2. `fetch_emails()` — `gog gmail search 'is:unread label:OpenClaw' --json`, then `gog gmail get <id> --json` for each thread.
3. For each email:
   - `create_card()` — `POST https://api.trello.com/1/cards` with subject as name and body (truncated to 4096 chars) as desc.
   - If subject or body matches `URGENT|IMPORTANT` (case-insensitive), `set_high_priority()` — `POST /1/cards/<card_id>/labels` with `name=High, color=red`.
   - `mark_read()` — `gog gmail mark-read <id>`.
4. Prints `{"processed": <count>}`.

## Run it

```sh
TRELLO_API_KEY=... TRELLO_TOKEN=... python3 email_workflow.py
```

Schedule it via your preferred runner (cron, systemd timer, `openclaw cron add`, etc.).

## Trade-offs

- **Pros:** Familiar imperative code; no extra runtime beyond Python 3 and `gog`; easy to read and debug; trivially unit-testable.
- **Cons:** Bring-your-own scheduler; any failure aborts the run with no per-email checkpointing — a partial failure can leave some emails marked read and others not.
