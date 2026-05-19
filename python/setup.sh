#!/usr/bin/env sh
# Registers the OpenClaw Email Workflow Python script with Linux crontab.
# Run once after cloning: sh setup.sh
#
# Requires TRELLO_API_KEY and TRELLO_TOKEN in the environment of the cron job.
# Set them in a file the cron line sources, or export them in the user's shell
# profile that cron inherits.

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/email_workflow.py"
CRON_LINE="*/5 * * * * /usr/bin/env python3 $SCRIPT_PATH >> /var/log/openclaw-email-workflow.log 2>&1"

# Append the line if it isn't already in the user's crontab.
( crontab -l 2>/dev/null | grep -Fv "$SCRIPT_PATH"; echo "$CRON_LINE" ) | crontab -

echo "Installed cron job:"
echo "  $CRON_LINE"
