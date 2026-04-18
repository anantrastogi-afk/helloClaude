"""Parse resume/input.pdf into a structured profile stored in SQLite + profile.json."""

import base64
import json
import os

import anthropic

from . import db
from .llm import CLASSIFY_MODEL
from .util import PROFILE_JSON, RESUME_PDF, ensure_dirs


PROFILE_SYSTEM = """You extract structured candidate data from a resume.

Return ONLY a valid JSON object. No prose, no code fences.

Schema:
{
  "full_name": "string",
  "headline": "string - one-line professional summary (e.g. 'Senior SWE, 10+ yrs distributed systems')",
  "email": "string | null",
  "phone": "string | null",
  "location": "string | null",
  "summary": "string - 2-4 sentence overview",
  "skills": ["string", ...],
  "experience": [
    {
      "company": "string",
      "title": "string",
      "start": "YYYY-MM or YYYY",
      "end": "YYYY-MM | YYYY | 'present'",
      "location": "string | null",
      "bullets": ["string", ...]
    }
  ],
  "education": [
    {
      "school": "string",
      "degree": "string",
      "start": "YYYY | null",
      "end": "YYYY | null",
      "details": "string | null"
    }
  ],
  "links": [{"label": "string", "url": "string"}]
}

Rules:
- Preserve the candidate's phrasing for bullets; do not fabricate.
- If a field is missing, use null or an empty list — never invent.
"""


def _encode_pdf(path: str) -> str:
    with open(path, "rb") as f:
        return base64.standard_b64encode(f.read()).decode("ascii")


def build_profile(pdf_path: str = RESUME_PDF) -> dict:
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(
            f"No resume found at {pdf_path}. Drop your PDF there and re-run."
        )

    ensure_dirs()
    db.init_db()

    pdf_b64 = _encode_pdf(pdf_path)

    client = anthropic.Anthropic()
    msg = client.messages.create(
        model=CLASSIFY_MODEL,
        max_tokens=4096,
        temperature=0,
        system=PROFILE_SYSTEM,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "document",
                        "source": {
                            "type": "base64",
                            "media_type": "application/pdf",
                            "data": pdf_b64,
                        },
                    },
                    {
                        "type": "text",
                        "text": "Extract the profile from this resume as JSON.",
                    },
                ],
            }
        ],
    )
    text = "".join(b.text for b in msg.content if b.type == "text")

    from .util import extract_json_block

    profile = extract_json_block(text)
    if not isinstance(profile, dict):
        raise ValueError("Model did not return a JSON object for the profile.")

    db.upsert_profile(profile)

    with open(PROFILE_JSON, "w") as f:
        json.dump(profile, f, indent=2)

    return profile


def print_profile_summary(profile: dict) -> None:
    print(f"  Name:       {profile.get('full_name')}")
    print(f"  Headline:   {profile.get('headline')}")
    print(f"  Location:   {profile.get('location')}")
    print(f"  Email:      {profile.get('email')}")
    print(f"  Skills:     {len(profile.get('skills') or [])}")
    print(f"  Experience: {len(profile.get('experience') or [])} roles")
    print(f"  Education:  {len(profile.get('education') or [])} entries")
