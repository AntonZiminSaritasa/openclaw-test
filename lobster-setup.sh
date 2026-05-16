#!/usr/bin/env sh
# Registers the OpenClaw Email Workflow cron job via Lobster.
# Run once after cloning: sh lobster-setup.sh

lobster cron add \
  --name "openclaw-email-workflow" \
  --every "5m" \
  --file openclaw-email-workflow.lobster
