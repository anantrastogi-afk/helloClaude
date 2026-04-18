"""Sync recruiter email threads into the application tracker and classify them.

Like the LinkedIn email source, this module does not call Gmail MCP tools
directly — those are only reachable from the Claude Code agent. The agent is
expected to fetch recruiter messages for each open application (using
`search_threads` with query hints from `build_gmail_queries`) and hand them to
`ingest_messages(application_id, messages)`.
"""

from datetime import datetime, timedelta

from . import db
from .llm import CLASSIFY_MODEL, complete
from .util import PST, extract_json_block, now_pst_iso


CLASSIFY_SYSTEM = """You classify a recruiter email into exactly one of these labels:

- reply: generic acknowledgement / "we received your application"
- rejection: declined, "moving forward with other candidates", etc.
- interview_invite: scheduling a screen / interview / assessment
- offer: explicit offer extended
- recruiter_outreach: new proactive recruiter message unrelated to an applied role
- other: unrelated / automated / out-of-scope

Return ONLY JSON: {"classification": "<label>", "reason": "<1 sentence>"}
"""


STATUS_MAP = {
    "interview_invite": "interview",
    "rejection": "rejected",
    "offer": "offer",
    "reply": "reply",
}


def build_gmail_queries() -> list[dict]:
    """Return one query spec per open application, for the agent to feed into
    the Gmail MCP `search_threads` tool."""
    out: list[dict] = []
    for app in db.list_open_applications():
        applied = app.get("applied_at") or now_pst_iso()
        try:
            applied_dt = datetime.fromisoformat(applied)
        except ValueError:
            applied_dt = datetime.now(PST)
        since = (applied_dt - timedelta(days=1)).strftime("%Y/%m/%d")
        company = (app.get("company") or "").strip()
        title = (app.get("title") or "").strip()
        q = f'after:{since} ("{company}" OR "{title}")' if company or title else f"after:{since}"
        out.append({
            "application_id": app["id"],
            "job_id": app["job_id"],
            "company": company,
            "title": title,
            "query": q,
        })
    return out


def classify_message(message: dict) -> str:
    user = (
        f"From: {message.get('sender')}\n"
        f"Subject: {message.get('subject')}\n"
        f"Snippet:\n{message.get('snippet') or message.get('body') or ''}\n"
    )
    response = complete(
        system=CLASSIFY_SYSTEM,
        user=user,
        model=CLASSIFY_MODEL,
        max_tokens=200,
        temperature=0,
    )
    data = extract_json_block(response)
    if isinstance(data, dict):
        return str(data.get("classification") or "other")
    return "other"


def ingest_messages(application_id: int, messages: list[dict]) -> list[tuple[str, str]]:
    """Classify and store messages for one application.

    `messages` = [{gmail_message_id, thread_id, sender, subject, received_at, snippet}, ...]
    Returns list of (gmail_message_id, classification).
    """
    results: list[tuple[str, str]] = []
    best_status: str | None = None
    priority = ["offer", "interview", "rejected", "reply"]

    for m in messages:
        classification = classify_message(m)
        db.record_email(application_id, m, classification)
        results.append((m.get("gmail_message_id", ""), classification))

        mapped = STATUS_MAP.get(classification)
        if mapped and (best_status is None or priority.index(mapped) < priority.index(best_status)):
            best_status = mapped

    if best_status:
        db.set_application_status(application_id, best_status)

    return results


def mark_ghosted(days: int = 14) -> int:
    """Flag applications with no replies after N days as ghosted (informational)."""
    cutoff = (datetime.now(PST) - timedelta(days=days)).isoformat(timespec="seconds")
    with db.connect() as conn:
        cur = conn.execute(
            """
            UPDATE applications
            SET current_status='ghosted'
            WHERE current_status='applied'
              AND applied_at < ?
              AND id NOT IN (SELECT DISTINCT application_id FROM emails WHERE application_id IS NOT NULL)
            """,
            (cutoff,),
        )
        return cur.rowcount
