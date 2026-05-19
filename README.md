# openclaw-test

Three alternate solutions to the same problem: poll Gmail for unread messages labeled **OpenClaw**, create a Trello card for each, flag urgent ones as High priority, and mark the emails read.

| Approach | Directory | Style | Runtime |
| --- | --- | --- | --- |
| Agent instructions + cron | [agents/](agents/) | Declarative natural-language program for an autonomous agent | OpenClaw |
| Lobster workflow | [lobster/](lobster/) | Declarative step pipeline (stdout → stdin) | Lobster + Node.js |
| Python script | [python/](python/) | Imperative, single file, stdlib only | Python 3 |

All three produce the same external effect; they differ in determinism, dependencies, and how behavior is changed (edit prose vs. edit pipeline vs. edit code). See each directory's README for run instructions and trade-offs.
