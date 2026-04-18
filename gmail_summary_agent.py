#!/usr/bin/env python3
"""
Gmail Daily Summary Agent
Fetches today's emails via Claude's Gmail MCP integration,
summarizes them with action items, and prints a daily digest.

Run: python gmail_summary_agent.py
Schedule daily via cron: 0 8 * * * /usr/bin/python3 /path/to/gmail_summary_agent.py
"""

import anthropic
from datetime import date


SYSTEM_PROMPT = """You are a personal email assistant. Given a list of today's emails,
produce a concise daily digest in this exact format:

## Daily Email Summary — {date}

### Action Required
- [Email subject] from [sender]: [1-sentence action needed]

### FYI / Needs Awareness
- [Email subject]: [1-sentence summary]

### Newsletters & Promotions (skip if not relevant)
- [source]: [topic in 5 words]

Keep it tight. Prioritize actionable items. Flag anything security-related immediately."""


def fetch_todays_emails(client: anthropic.Anthropic) -> list[dict]:
    """Use Claude with Gmail tool to fetch today's emails."""
    today = date.today()
    query = f"after:{today.strftime('%Y/%m/%d')} before:{today.strftime('%Y/%m/%d').replace(str(today.day), str(today.day + 1))}"

    # This is called by the Claude agent via MCP — in standalone use,
    # wire up the Gmail API credentials directly here.
    return []


def summarize_emails(emails_text: str) -> str:
    """Send email data to Claude for summarization."""
    client = anthropic.Anthropic()

    today_str = date.today().strftime("%B %d, %Y")
    prompt = SYSTEM_PROMPT.format(date=today_str)

    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system=prompt,
        messages=[
            {
                "role": "user",
                "content": f"Here are today's emails:\n\n{emails_text}",
            }
        ],
    )
    return message.content[0].text


def run_agent():
    """Main agent loop: fetch emails → summarize → print digest."""
    print(f"Gmail Summary Agent — {date.today().strftime('%B %d, %Y')}")
    print("=" * 60)

    # In production this would call the Gmail MCP / API.
    # When run inside Claude Code with Gmail MCP connected,
    # Claude handles the tool calls automatically.
    print("Fetching today's emails via Gmail MCP...")
    print("(Connect Gmail MCP and run inside Claude Code for live data)")
    print()

    # Sample emails_text for standalone testing:
    sample = """
    1. From: assistant@disclosures.io | Subject: 11510 Vista Place: Sandhya Paramel shared access to the property info packet
    2. From: no-reply@accounts.google.com | Subject: Security alert — new sign-in on Mac
    3. From: sspvolunteer@shirdisaiparivaar.org | Subject: [Reminder] Sunday April 19 at SSC Milpitas
    4. From: anant.rastogi@gmail.com (sent) | Subject: Inquiry: Loan Against Securities – Account Details & Eligibility
    5. From: kopilil713@gmail.com | Feedback on content — psychology + gaming combination
    6. From: newsletters-noreply@linkedin.com | Subject: Artificial Intelligence #323 — Stanford 2026 AI Index
    7. From: editors-noreply@linkedin.com | Subject: The workers sabotaging AI
    8. From: jobalerts-noreply@linkedin.com | Subject: Software Engineering Manager roles at Cisco, Ladders ($259K-$415K)
    9. From: newsletter@tesla.com | Subject: Spring Software Release Is Here
    10. From: Trip.com@newsletter.trip.com | Subject: Pack Your Bags, Catch the Bloom
    """

    summary = summarize_emails(sample)
    print(summary)


if __name__ == "__main__":
    run_agent()
