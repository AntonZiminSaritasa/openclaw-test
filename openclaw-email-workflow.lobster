name: OpenClaw Email Workflow
steps:
  - name: Fetch unread OpenClaw emails
    run: gog gmail search 'is:unread label:OpenClaw'

  - name: Create Trello card for each email
    run: |
      for email in $EMAILS; do
        gog trello card create \
          --list 6a07f96eab21b6db18fffb33 \
          --title "$(echo $email | jq -r '.subject')" \
          --description "$(echo $email | jq -r '.body')"
      done

  - name: Set High priority for urgent emails
    run: |
      for email in $EMAILS; do
        if echo "$email" | jq -r '.subject,.body' | grep -qi 'URGENT\|IMPORTANT'; then
          gog trello card update \
            --id "$(echo $email | jq -r '.trello_card_id')" \
            --priority High
        fi
      done

  - name: Mark processed emails as read
    run: |
      for email in $EMAILS; do
        gog gmail mark-read "$(echo $email | jq -r '.id')"
      done
