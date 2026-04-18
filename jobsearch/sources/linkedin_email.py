"""Extract job listings from LinkedIn 'jobalerts-noreply' emails in Gmail.

This module expects to run inside Claude Code where the Gmail MCP is connected —
the same environment the existing gmail_summary_agent.py uses.

It does NOT call MCP tools directly (those are only available to the
Claude Code agent). Instead the agent invokes `ingest_from_text(bodies)` with
the concatenated email bodies it fetched via MCP. When run standalone
(no MCP), use `ingest_from_text` on manually-pasted content.
"""

from .. import db
from ..llm import CLASSIFY_MODEL, complete
from ..util import extract_json_block


EXTRACT_SYSTEM = """You extract job postings from LinkedIn "job alert" email bodies.

Return ONLY a JSON array. Each element:
{
  "title": "string",
  "company": "string",
  "location": "string | null",
  "salary": "string | null",
  "url": "string | null",
  "snippet": "string - the 1-2 line preview from the email"
}

Rules:
- Skip promotional filler, newsletter sections, and "you might also like" blocks unless they are clearly real postings.
- Deduplicate obvious duplicates.
- Preserve posted URLs exactly as they appear (they contain tracking tokens — leave them).
- If no jobs are present, return [].
"""


def ingest_from_text(email_bodies: str) -> list[int]:
    """Parse raw email bodies and insert new jobs. Returns list of inserted job ids."""
    response = complete(
        system=EXTRACT_SYSTEM,
        user=f"Emails:\n\n{email_bodies}",
        model=CLASSIFY_MODEL,
        max_tokens=4096,
        temperature=0,
    )
    data = extract_json_block(response)
    if not isinstance(data, list):
        return []

    inserted: list[int] = []
    for item in data:
        job = {
            "source": "linkedin_email",
            "source_url": item.get("url"),
            "title": item.get("title"),
            "company": item.get("company"),
            "location": item.get("location"),
            "salary": item.get("salary"),
            "posted_at": None,
            "description": item.get("snippet"),
            "raw_snippet": item.get("snippet"),
        }
        if not job["title"] or not job["company"]:
            continue
        job_id = db.insert_job(job)
        if job_id:
            inserted.append(job_id)
    return inserted
