name: openclaw-email-workflow
args:
  trello_list_id:
    default: "6a07f96eab21b6db18fffb33"
  gmail_label:
    default: "OpenClaw"
env:
  TRELLO_KEY: $TRELLO_KEY
  TRELLO_TOKEN: $TRELLO_TOKEN
steps:
  - id: search
    command: gog gmail search 'is:unread label:$gmail_label' --json

  - id: process_emails
    command: |
      jq -c '.emails[]' | while read -r email; do
        msg_id=$(echo "$email" | jq -r '.message_id')
        subject=$(echo "$email" | jq -r '.subject')
        body=$(echo "$email" | jq -r '.body')

        card=$(curl -sS -X POST "https://api.trello.com/1/cards" \
          --data-urlencode "idList=$trello_list_id" \
          --data-urlencode "name=$subject" \
          --data-urlencode "desc=$body" \
          --data-urlencode "key=$TRELLO_KEY" \
          --data-urlencode "token=$TRELLO_TOKEN")
        card_id=$(echo "$card" | jq -r '.id')

        if echo "$subject $body" | grep -Eiq '(URGENT|IMPORTANT)'; then
          curl -sS -X POST "https://api.trello.com/1/cards/$card_id/labels" \
            --data-urlencode "name=High" \
            --data-urlencode "color=red" \
            --data-urlencode "key=$TRELLO_KEY" \
            --data-urlencode "token=$TRELLO_TOKEN" >/dev/null
        fi

        jq -nc --arg mid "$msg_id" --arg cid "$card_id" '{message_id: $mid, card_id: $cid}'
      done | jq -s '{processed: .}'
    stdin: $search.json

  - id: mark_read
    command: |
      jq -r '.processed[].message_id' | while read -r mid; do
        gog gmail mark-read "$mid"
      done
    stdin: $process_emails.json
    condition: $process_emails.success
