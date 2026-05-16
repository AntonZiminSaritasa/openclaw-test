name: openclaw-email-workflow
args:
  trello_list_id:
    default: "6a07f96eab21b6db18fffb33"
  gmail_label:
    default: "OpenClaw"
steps:
  - id: search
    command: gog gmail search 'is:unread label:$gmail_label' --json

  - id: create_cards
    command: gog trello create-cards --list-id $trello_list_id --title-field subject --description-field body --json
    stdin: $search.json

  - id: flag_priority
    command: gog trello set-priority --priority High --match-keywords 'URGENT,IMPORTANT' --case-insensitive --match-fields subject,body
    stdin: $create_cards.json

  - id: mark_read
    command: gog gmail mark-read --from-json
    stdin: $search.json
    condition: $create_cards.success
