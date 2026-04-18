"""Adzuna free job-board API.

Set env vars ADZUNA_APP_ID and ADZUNA_APP_KEY to enable. Register at
https://developer.adzuna.com/ for a free key. If env vars are missing this
source is skipped silently.
"""

import os

import httpx

from .. import db


BASE = "https://api.adzuna.com/v1/api/jobs"


def enabled() -> bool:
    return bool(os.environ.get("ADZUNA_APP_ID") and os.environ.get("ADZUNA_APP_KEY"))


def pull(profile: dict, country: str = "us", max_results: int = 25) -> list[int]:
    if not enabled():
        return []

    app_id = os.environ["ADZUNA_APP_ID"]
    app_key = os.environ["ADZUNA_APP_KEY"]

    headline = profile.get("headline") or ""
    top_titles = [
        exp.get("title")
        for exp in (profile.get("experience") or [])[:3]
        if exp.get("title")
    ]
    what = " ".join([headline, *top_titles]).strip() or "software engineer"
    where = profile.get("location") or ""

    params = {
        "app_id": app_id,
        "app_key": app_key,
        "results_per_page": max_results,
        "what": what[:200],
        "where": where,
        "content-type": "application/json",
    }

    with httpx.Client(timeout=20.0) as c:
        r = c.get(f"{BASE}/{country}/search/1", params=params)
        r.raise_for_status()
        payload = r.json()

    inserted: list[int] = []
    for item in payload.get("results", []):
        job = {
            "source": "adzuna",
            "source_url": item.get("redirect_url"),
            "title": item.get("title"),
            "company": (item.get("company") or {}).get("display_name"),
            "location": (item.get("location") or {}).get("display_name"),
            "salary": _format_salary(item),
            "posted_at": item.get("created"),
            "description": item.get("description"),
            "raw_snippet": (item.get("description") or "")[:500],
        }
        if not job["title"] or not job["source_url"]:
            continue
        job_id = db.insert_job(job)
        if job_id:
            inserted.append(job_id)
    return inserted


def _format_salary(item: dict) -> str | None:
    lo = item.get("salary_min")
    hi = item.get("salary_max")
    if not lo and not hi:
        return None
    currency = item.get("salary_currency") or "USD"
    if lo and hi:
        return f"{currency} {int(lo):,} - {int(hi):,}"
    return f"{currency} {int(lo or hi):,}"
