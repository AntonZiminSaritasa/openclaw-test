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
    skill: trello
    prompt: |
      For each email in the input JSON, create a Trello card in list $trello_list_id
      with the email subject as the title and the email body as the description.
      Return JSON mapping each email message_id to the created card id.
    stdin: $search.json

  - id: flag_priority
    skill: trello
    prompt: |
      For each (email, card) pair in the input JSON, if the email subject OR body
      contains the word "URGENT" or "IMPORTANT" (case-insensitive), set that
      Trello card's priority to High.
    stdin: $create_cards.json

  - id: mark_read
    command: gog gmail mark-read --from-json
    stdin: $search.json
    condition: $create_cards.success
