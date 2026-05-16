## Program: OpenClaw Email Workflow

**Authority:** Read Gmail labels, create Trello cards, set Trello card priority, send Slack messages

**Trigger:** Every 5 minutes via cron (see `setup.sh`)

**Approval gate:** None — fully automated

**Escalation:** Stop and report if any external API (Gmail, Trello, Slack) returns an error; do not retry silently

### Execution steps

1. Search Gmail for unread emails with the label **OpenClaw** using:
   ```
   gog gmail search 'is:unread label:OpenClaw'
   ```
2. For each email:
   1. Create a new Trello card in list `6a07f96eab21b6db18fffb33`:
      - Title: email subject
      - Description: email body
   2. Check whether the email body contains the word **URGENT** or **IMPORTANT** (case-insensitive)
   3. If either keyword is present:
      - Set the Trello card priority to **High**
      - Send a Slack message to the configured channel:
        - Include the email subject
        - State that the message is high-priority
3. Mark each processed email as read in Gmail using:
   ```
   gog gmail mark-read <MESSAGE_ID>
   ```
   so it is not matched by the search query on the next run

### What NOT to do

- Do not delete or archive emails in Gmail
- Do not send a Slack message for emails that do not contain URGENT or IMPORTANT
- Do not create a Trello card more than once for the same email
- Do not skip the Gmail read-marking step — skipping it causes duplicate processing
