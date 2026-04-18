"""Generate tailored resume, cover letter, and recruiter email for one job."""

import json
import os

from . import db
from .llm import REASONING_MODEL, complete
from .util import APPLICATIONS_DIR, ensure_dirs, extract_json_block


MATERIALS_SYSTEM = """You produce job-application materials tailored to a single posting.

Return ONLY a JSON object with three keys:
{
  "resume_md":       "string - full tailored resume in markdown",
  "cover_letter_md": "string - short (3-4 paragraphs) cover letter in markdown",
  "email_md":        "string - short recruiter email for applying/following up, with subject on the first line"
}

Hard rules:
- NEVER fabricate experience, titles, dates, companies, education, or metrics.
- Reorder, re-weight, and rephrase the candidate's existing bullets to emphasize what the job asks for.
- Where the candidate's resume already has numbers, keep them. Do not invent new numbers.
- Use the job's keywords naturally where they match real experience.
- Resume should be ATS-friendly: clear section headers (Summary, Skills, Experience, Education), simple formatting.
- Cover letter: address the hiring team, state specific fit, cite 1-2 real accomplishments, close with call to action.
- Email: keep it under 120 words; first line is `Subject: ...`.
"""


def _job_dir(job_id: int) -> str:
    d = os.path.join(APPLICATIONS_DIR, str(job_id))
    os.makedirs(d, exist_ok=True)
    return d


def generate(job_id: int) -> dict:
    ensure_dirs()
    profile = db.get_profile()
    if not profile:
        raise RuntimeError("No profile in DB. Run `python -m jobsearch profile` first.")

    job = db.get_job(job_id)
    if not job:
        raise RuntimeError(f"No job with id={job_id}.")

    user = (
        "CANDIDATE PROFILE:\n"
        f"{json.dumps(profile, indent=2, default=str)}\n\n"
        "JOB:\n"
        f"Title: {job.get('title')}\n"
        f"Company: {job.get('company')}\n"
        f"Location: {job.get('location')}\n"
        f"Description:\n{job.get('description') or job.get('raw_snippet') or ''}\n"
    )

    response = complete(
        system=MATERIALS_SYSTEM,
        user=user,
        model=REASONING_MODEL,
        max_tokens=4096,
        temperature=0.3,
    )
    data = extract_json_block(response)
    if not isinstance(data, dict):
        raise RuntimeError("Model did not return JSON materials.")

    out_dir = _job_dir(job_id)
    resume_path = os.path.join(out_dir, "resume.md")
    cover_path = os.path.join(out_dir, "cover_letter.md")
    email_path = os.path.join(out_dir, "email_draft.md")

    with open(resume_path, "w") as f:
        f.write(data.get("resume_md", ""))
    with open(cover_path, "w") as f:
        f.write(data.get("cover_letter_md", ""))
    with open(email_path, "w") as f:
        f.write(data.get("email_md", ""))

    app_id = db.create_application(job_id, resume_path, cover_path, email_path)
    db.update_job(job_id, status="applied")

    return {
        "application_id": app_id,
        "resume_path": resume_path,
        "cover_letter_path": cover_path,
        "email_draft_path": email_path,
    }
