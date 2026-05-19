#!/usr/bin/env sh
# Registers the OpenClaw Email Workflow cron job.
# Run once after cloning: sh setup.sh

openclaw cron add \
  --name "openclaw-email-agentic-workflow" \
  --every "5m" \
  --session isolated \
  --message "Run the OpenClaw Email Workflow program"
