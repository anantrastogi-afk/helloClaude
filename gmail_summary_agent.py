#!/usr/bin/env python3
"""
Gmail Daily Summary Agent
Fetches today's emails via Claude's Gmail MCP integration,
summarizes them with action items, and saves a dated Markdown file.

Run manually:  python gmail_summary_agent.py
Cron schedule: 45 15 * * * (7:45 AM PST / 15:45 UTC)
Summaries are saved to: summaries/YYYY-MM-DD.md
"""

import anthropic
import os
from datetime import date, datetime, timezone, timedelta


SUMMARIES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "summaries")

PST = timezone(timedelta(hours=-8))

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


def summarize_emails(emails_text: str) -> str:
    """Send email data to Claude for summarization."""
    client = anthropic.Anthropic()

    today_str = datetime.now(PST).strftime("%B %d, %Y")
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


def save_summary(summary: str) -> str:
    """Write summary to summaries/YYYY-MM-DD.md and return the file path."""
    os.makedirs(SUMMARIES_DIR, exist_ok=True)
    today_str = datetime.now(PST).strftime("%Y-%m-%d")
    filepath = os.path.join(SUMMARIES_DIR, f"{today_str}.md")
    with open(filepath, "w") as f:
        f.write(summary)
        f.write(f"\n\n---\n_Generated at {datetime.now(PST).strftime('%I:%M %p PST on %B %d, %Y')}_\n")
    return filepath


def run_agent(emails_text: str | None = None):
    """
    Main agent entry point.

    Pass `emails_text` directly (e.g. from MCP output) or leave None to use
    the built-in sample for standalone testing.
    """
    now_pst = datetime.now(PST)
    print(f"Gmail Summary Agent — {now_pst.strftime('%B %d, %Y %I:%M %p PST')}")
    print("=" * 60)

    if emails_text is None:
        # Populated by the Gmail MCP search when run inside Claude Code.
        # Replace this block with live MCP output in production.
        emails_text = """
1.  From: assistant@disclosures.io
    Subject: 11510 Vista Place: Sandhya Paramel shared access to the property info packet
    Time: 9:23 PM
    Snippet: Sandhya Paramel shared a Property Info Packet with you for 11510 Vista Place Dublin, CA. Click Review Now to open.

2.  From: no-reply@accounts.google.com
    Subject: Security alert — new sign-in on Mac
    Time: 9:16 PM
    Snippet: A new sign-in to your Google Account was detected on a Mac device.

3.  From: no-reply@accounts.google.com
    Subject: Security alert — Claude for Gmail access granted
    Time: 9:16 PM
    Snippet: You allowed Claude for Gmail access to some of your Google Account data.

4.  From: no-reply@accounts.google.com
    Subject: Security alert — Claude for Google Calendar access granted
    Time: 9:16 PM
    Snippet: You allowed Claude for Google Calendar access to some of your Google Account data.

5.  From: sspvolunteer@shirdisaiparivaar.org
    Subject: [Reminder] Friendly Reminder for Sunday April 19, 2026 at SSC Milpitas, CA
    Time: 6:44 PM
    Snippet: Bay Alarm is active during non-operating hours. Brivo access will not work. All volunteers must leave before non-operating hours.

6.  From: anant.rastogi@gmail.com (SENT)
    Subject: Inquiry: Loan Against Securities – Account Details & Eligibility
    Time: 7:22 PM
    To: prachi.chittora@citi.com
    Snippet: Hi Prachi, I am a Citi Gold member interested in exploring Loan Against Securities (LAS). Awaiting reply.

7.  From: kopilil713@gmail.com
    Subject: Content feedback
    Time: 6:00 PM
    Snippet: Content ekdum solid hai — psychology aur gaming ka combination rare hai. Agar sources add karo credibility badhegi.

8.  From: newsletters-noreply@linkedin.com
    Subject: Artificial Intelligence #323
    Time: 7:53 PM
    Snippet: Stanford 2026 AI Index Report; monkey selfie copyright.

9.  From: editors-noreply@linkedin.com
    Subject: The workers sabotaging AI
    Time: 7:34 PM
    Snippet: 60% of C-suite plan to lay off employees who don't adopt AI at work.

10. From: jobalerts-noreply@linkedin.com
    Subject: "software engineering manager" — Cisco Technical Leader and more
    Time: 7:37 PM
    Snippet: Application window closing soon for Cisco Software Engineering Technical Leader.

11. From: jobalerts-noreply@linkedin.com
    Subject: "software engineering manager" — Ladders Senior Eng Manager ($259K-$415K)
    Time: 5:37 PM

12. From: newsletter@tesla.com
    Subject: Our Spring Software Release Is Here
    Time: 6:31 PM
    Snippet: Unlock the newest features in your Tesla.

13. From: Trip.com@newsletter.trip.com
    Subject: Pack Your Bags, Catch the Bloom
    Time: 8:55 PM
    Snippet: Peak bloom season — Hampton Court Palace Tulip Festival.

14. From: notification@facebookmail.com
    Subject: The Fitness Geek: "5-Minute Lymphatic..."
    Time: 7:58 PM

15. From: reply@ss.email.nextdoor.com
    Subject: @ 10:10pm tonight, I saw the young man who scammed...
    Time: 7:56 PM
    Snippet: Community update on a scammer sighting.
"""

    print("Summarizing emails...\n")
    summary = summarize_emails(emails_text)
    print(summary)

    filepath = save_summary(summary)
    print(f"\nSummary saved → {filepath}")
    return summary


if __name__ == "__main__":
    run_agent()
