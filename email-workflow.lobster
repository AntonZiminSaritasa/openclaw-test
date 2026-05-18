name: openclaw-email-workflow
description: Fetch OpenClaw emails, create Trello cards, mark high-priority, send Slack notifications

args:
  trello_list_id:
    default: "6a07f96eab21b6db18fffb33"
  gmail_label:
    default: "OpenClaw"

steps:
  - id: fetch_emails
    command: gog gmail search 'is:unread label:OpenClaw' --json

  - id: create_trello_cards
    command: |-
      cat > /tmp/process-emails.js << 'EOF'
      const fs = require('fs');
      const https = require('https');

      const data = JSON.parse(fs.readFileSync(0, 'utf8'));
      const emails = Array.isArray(data) ? data : [data];
      const listId = process.env.TRELLO_LIST_ID;
      const apiKey = process.env.TRELLO_API_KEY;
      const token = process.env.TRELLO_TOKEN;

      async function postRequest(url, body) {
        return new Promise((resolve, reject) => {
          const postData = new URLSearchParams(body).toString();
          const req = https.request(url, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Content-Length': Buffer.byteLength(postData)
            }
          }, (res) => {
            let responseData = '';
            res.on('data', chunk => responseData += chunk);
            res.on('end', () => {
              try {
                resolve(JSON.parse(responseData));
              } catch(e) {
                reject(new Error(`Failed to parse response: ${responseData}`));
              }
            });
          });
          req.on('error', reject);
          req.write(postData);
          req.end();
        });
      }

      async function processEmails() {
        const results = [];
        for (const email of emails) {
          const subject = email.subject || '(No Subject)';
          const body = email.snippet || email.body || '';
          const isHighPriority = /URGENT|IMPORTANT/i.test(subject + ' ' + body);

          try {
            const card = await postRequest(
              `https://api.trello.com/1/cards?key=${apiKey}&token=${token}`,
              {
                idList: listId,
                name: subject,
                desc: body.substring(0, 4096)
              }
            );

            results.push({
              emailId: email.id,
              subject: subject,
              highPriority: isHighPriority,
              cardId: card.id,
              cardUrl: card.url
            });
          } catch(err) {
            console.log(err);
            console.error(`Failed to create card for email: ${subject}`, err);
          }
        }
        console.log(JSON.stringify(results));
      }

      processEmails().catch(err => {
        console.error('Error:', err);
        process.exit(1);
      });
      EOF

      TRELLO_LIST_ID="6a07f96eab21b6db18fffb33" node /tmp/process-emails.js
    stdin: $fetch_emails.stdout

  - id: mark_high_priority
    command: |-
      cat > /tmp/set-priority.js << 'EOF'
      const fs = require('fs');
      const https = require('https');

      const results = JSON.parse(fs.readFileSync(0, 'utf8'));
      const apiKey = process.env.TRELLO_API_KEY;
      const token = process.env.TRELLO_TOKEN;
      const slackWebhook = process.env.SLACK_WEBHOOK_URL;

      async function putRequest(url, body) {
        return new Promise((resolve, reject) => {
          const postData = new URLSearchParams(body).toString();
          const req = https.request(url, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Content-Length': Buffer.byteLength(postData)
            }
          }, (res) => {
            let responseData = '';
            res.on('data', chunk => responseData += chunk);
            res.on('end', () => resolve(responseData));
          });
          req.on('error', reject);
          req.write(postData);
          req.end();
        });
      }

      async function processHighPriority() {
        const highPriorityCards = results.filter(r => r.highPriority);

        for (const card of highPriorityCards) {
          try {
            await putRequest(
              `https://api.trello.com/1/cards/${card.cardId}?key=${apiKey}&token=${token}`,
              { idLabels: 'priority-high' }
            );
          } catch(err) {
            console.error(`Failed to set priority for card: ${card.cardId}`, err);
          }
        }

        console.log(JSON.stringify({ processed: highPriorityCards.length, total: results.length }));
      }

      processHighPriority().catch(err => {
        console.error('Error:', err);
        process.exit(1);
      });
      EOF

      node /tmp/set-priority.js
    stdin: $create_trello_cards.stdout
    env:
      TRELLO_API_KEY: ${TRELLO_API_KEY}
      TRELLO_TOKEN: ${TRELLO_TOKEN}

  - id: mark_emails_read
    command: |-
      cat > /tmp/mark-read.js << 'EOF'
      const fs = require('fs');
      const { execSync } = require('child_process');

      const data = JSON.parse(fs.readFileSync(0, 'utf8'));
      const emails = Array.isArray(data) ? data : [data];

      if (emails.length === 0) {
        console.log(JSON.stringify({ markedRead: 0 }));
        process.exit(0);
      }

      // Mark all emails as read using gog
      const emailIds = emails.map(e => e.id || e.emailId).filter(id => id);
      if (emailIds.length === 0) {
        console.log(JSON.stringify({ markedRead: 0 }));
        process.exit(0);
      }

      try {
        // Use gog to mark as read
        for (const id of emailIds) {
          try {
            execSync(`gog gmail mark-read --message-id ${id}`, { stdio: 'ignore' });
          } catch(e) {
            console.error(`Failed to mark ${id} as read`);
          }
        }
        console.log(JSON.stringify({ markedRead: emailIds.length }));
      } catch(err) {
        console.error('Error marking emails as read:', err);
        process.exit(1);
      }
      EOF

      node /tmp/mark-read.js
    stdin: $fetch_emails.stdout
