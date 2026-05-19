# AGENTS.md

A declarative, agent-driven solution. Instead of writing imperative code, the workflow is described in natural language for an autonomous OpenClaw agent (see [AGENTS.md](AGENTS.md)). A small shell script registers it to run every 5 minutes (see [setup.sh](setup.sh)).

## How it works

- [AGENTS.md](AGENTS.md) defines the program for the agent: authority, trigger, execution steps, and guardrails ("What NOT to do").
- The agent calls `gog gmail search`, creates Trello cards via the agent's authorized tools, and marks emails read via `gog gmail mark-read`.
- [setup.sh](setup.sh) calls `openclaw cron add` once to schedule the agent.

## Run it

```sh
sh setup.sh
```

The agent then runs every 5 minutes in an isolated session.

## Trade-offs

- **Pros:** No code to maintain; behavior changes are documentation edits; the agent can recover from minor unexpected states (e.g. unfamiliar email structure) without a code patch.
- **Cons:** Behavior is non-deterministic — the same emails may be handled slightly differently across runs; requires an OpenClaw runtime with Gmail/Trello tool access; harder to unit test.
