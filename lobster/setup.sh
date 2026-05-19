#!/usr/bin/env sh
# Registers the Lobster Email Workflow cron job.
# Run once after cloning: sh setup.sh

openclaw cron add \
  --name "openclaw-email-lobster-workflow" \
  --every "5m" \
  --session isolated \
  --message "Run the Lobster Workflow email-workflow.lobster with default arguments"
