# Lobster workflow

A deterministic pipeline defined in [email-workflow.lobster](email-workflow.lobster) — a declarative workflow DSL where each step's `stdout` is piped to the next step's `stdin`.

## How it works

Five steps, executed in order:

1. `fetch_emails` — `gog gmail search 'is:unread label:OpenClaw' --json`
2. `fetch_email_bodies` — for each thread id, calls `gog gmail get <id> --json` and emits a normalized email list
3. `create_trello_cards` — `POST https://api.trello.com/1/cards` for each email; flags High priority if subject or body matches `URGENT|IMPORTANT`
4. `mark_high_priority` — for flagged cards, `POST /1/cards/<id>/labels` with `name=High, color=red`
5. `mark_emails_read` — `gog gmail mark-read <id>` for each processed email

Per-step result JSON is written under `/tmp/*.log` for debugging.

## Run it

One-off:

```sh
lobster run email-workflow.lobster
```

Required environment: `TRELLO_API_KEY`, `TRELLO_TOKEN`. Args `trello_list_id` and `gmail_label` have defaults but can be overridden.

## Schedule it

[setup.sh](setup.sh) registers a recurring job via `openclaw cron add` that runs the workflow every 5 minutes in an isolated session. Run once after cloning:

```sh
sh setup.sh
```

## Trade-offs

- **Pros:** Each step is observable and independently re-runnable; arguments are first-class; deterministic.
- **Cons:** Heavy step bodies (inline Node.js heredocs); requires both a Lobster runtime and Node.js; failure in any step aborts the pipeline.
