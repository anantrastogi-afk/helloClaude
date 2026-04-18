"""Job orchestration: pull from sources, score matches, list, close."""

import json

from . import db
from .llm import REASONING_MODEL, complete
from .sources import adzuna
from .util import extract_json_block


SCORING_SYSTEM = """You rate how strongly a candidate profile matches a job posting.

Return ONLY JSON:
{
  "score": 0-100,
  "rationale": "2-3 sentence explanation",
  "missing_skills": ["string", ...]
}

Scoring guide:
- 90-100: Clear fit on title, seniority, core skills, and domain.
- 70-89: Strong fit with 1-2 gaps that are learnable.
- 50-69: Partial fit; meaningful gaps in skills or seniority.
- Below 50: Weak fit.

Be honest. A low score is useful signal.
"""


def score_job(profile: dict, job: dict) -> dict:
    user = (
        "CANDIDATE PROFILE (JSON):\n"
        f"{json.dumps({k: profile.get(k) for k in ('headline','summary','skills','experience','location')}, indent=2)}\n\n"
        "JOB POSTING:\n"
        f"Title: {job.get('title')}\n"
        f"Company: {job.get('company')}\n"
        f"Location: {job.get('location')}\n"
        f"Salary: {job.get('salary')}\n"
        f"Description:\n{job.get('description') or job.get('raw_snippet') or ''}\n"
    )
    response = complete(
        system=SCORING_SYSTEM,
        user=user,
        model=REASONING_MODEL,
        max_tokens=512,
        temperature=0,
    )
    data = extract_json_block(response)
    if not isinstance(data, dict):
        return {"score": 0, "rationale": "parse error", "missing_skills": []}
    return data


def score_unscored() -> int:
    profile = db.get_profile()
    if not profile:
        print("[jobs] No profile in DB. Run `python -m jobsearch profile` first.")
        return 0

    todo = db.unscored_jobs()
    n = 0
    for job in todo:
        result = score_job(profile, job)
        db.update_job(
            job["id"],
            match_score=int(result.get("score") or 0),
            match_rationale=result.get("rationale") or "",
        )
        n += 1
        print(f"  scored #{job['id']:>4}  {result.get('score'):>3}  {job.get('title')} @ {job.get('company')}")
    return n


def pull_all(linkedin_email_bodies: str | None = None) -> dict:
    """Run enabled sources. `linkedin_email_bodies` is optional raw text
    provided by the agent/caller (it holds the Gmail MCP credentials)."""
    profile = db.get_profile()
    counts = {"linkedin_email": 0, "adzuna": 0}

    if linkedin_email_bodies:
        from .sources import linkedin_email
        counts["linkedin_email"] = len(linkedin_email.ingest_from_text(linkedin_email_bodies))

    if profile and adzuna.enabled():
        counts["adzuna"] = len(adzuna.pull(profile))
    elif not adzuna.enabled():
        print("[jobs] adzuna skipped (set ADZUNA_APP_ID and ADZUNA_APP_KEY to enable).")

    scored = score_unscored()
    return {"inserted": counts, "scored": scored}


def close_job(job_id: int, reason: str | None = None) -> None:
    notes = f"closed: {reason}" if reason else "closed"
    db.update_job(job_id, status="closed")
    with db.connect() as conn:
        conn.execute(
            "UPDATE applications SET notes = COALESCE(notes || ' | ', '') || ? WHERE job_id=?",
            (notes, job_id),
        )


def print_list(status: str | None = None, min_score: int | None = None) -> None:
    rows = db.list_jobs(status=status, min_score=min_score)
    if not rows:
        print("(no jobs)")
        return
    print(f"{'ID':>4}  {'SCORE':>5}  {'STATUS':<12}  {'TITLE':<40}  {'COMPANY':<25}  LOCATION")
    print("-" * 120)
    for r in rows:
        score = r["match_score"] if r["match_score"] is not None else "-"
        print(
            f"{r['id']:>4}  {str(score):>5}  {r['status']:<12}  "
            f"{(r['title'] or '')[:40]:<40}  {(r['company'] or '')[:25]:<25}  "
            f"{(r['location'] or '')[:30]}"
        )
