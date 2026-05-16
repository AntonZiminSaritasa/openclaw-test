#!/usr/bin/env sh
# Registers the Lobster Email Workflow cron job.
# Run once after cloning: sh lobster-setup.sh

lobster cron add \
  --name "lobster-email-workflow" \
  --every "5m" \
  --session isolated \
  --message "Run the Lobster Email Workflow program"
