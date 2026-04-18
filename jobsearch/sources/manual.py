"""Manual single-job ingestion from pasted text or a URL."""

import httpx
from bs4 import BeautifulSoup

from .. import db
from ..llm import CLASSIFY_MODEL, complete
from ..util import extract_json_block


PARSE_SYSTEM = """You extract a single job posting into JSON.

Return ONLY a JSON object:
{
  "title": "string",
  "company": "string",
  "location": "string | null",
  "salary": "string | null",
  "description": "string - the full JD, trimmed of site chrome"
}

Rules:
- If the input is an HTML page, ignore nav/footer/ads/cookie banners.
- Keep the JD body verbatim; do not summarize or paraphrase.
"""


def _fetch_url(url: str) -> str:
    with httpx.Client(follow_redirects=True, timeout=20.0, headers={"User-Agent": "Mozilla/5.0"}) as c:
        r = c.get(url)
        r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    for tag in soup(["script", "style", "nav", "footer", "aside"]):
        tag.decompose()
    return soup.get_text("\n", strip=True)


def add(url: str | None = None, text: str | None = None) -> int | None:
    if not url and not text:
        raise ValueError("Provide --url or --text.")

    if url and not text:
        text = _fetch_url(url)

    assert text is not None
    response = complete(
        system=PARSE_SYSTEM,
        user=f"Input:\n\n{text[:30000]}",
        model=CLASSIFY_MODEL,
        max_tokens=4096,
        temperature=0,
    )
    data = extract_json_block(response)
    if not isinstance(data, dict):
        return None

    job = {
        "source": "manual",
        "source_url": url,
        "title": data.get("title"),
        "company": data.get("company"),
        "location": data.get("location"),
        "salary": data.get("salary"),
        "posted_at": None,
        "description": data.get("description"),
        "raw_snippet": (data.get("description") or "")[:500],
    }
    return db.insert_job(job)
