"""Interview prep: question bank, company brief, mock interview, STAR stories."""

import json
import os

from . import db
from .llm import REASONING_MODEL, complete, complete_multiturn
from .util import PREP_DIR, ensure_dirs


QUESTIONS_SYSTEM = """You are an interview coach. Produce a tailored question bank
for a specific candidate applying to a specific role.

Output: markdown only, with these sections in this order:
# <Company> — <Title> Interview Prep

## Behavioral (8-10)
- numbered list, each with a one-line hint on what the interviewer is probing for.

## Role-specific technical (8-12)
- focused on the skills the JD calls out that intersect with the candidate's resume.

## System design / architecture (3-5)
- realistic scope for the seniority in the JD.

## Curveballs (3-5)
- questions the candidate is LEAST prepared for based on gaps vs. JD.

Keep each question crisp. No fluff, no preamble.
"""


COMPANY_SYSTEM = """You produce a concise interview briefing about a company and role.

Output markdown with these headers:
# <Company> — briefing
## What they do
## Products / business lines
## Recent news & strategic themes
## Culture & interview style (best guesses)
## Likely talking points for the candidate
## Smart questions to ask the interviewer

Acknowledge knowledge cutoff uncertainty where relevant. Keep it under ~500 words.
"""


STARS_SYSTEM = """You are a behavioral-interview coach. Convert each resume bullet into
a STAR story (Situation, Task, Action, Result). Use ONLY facts present in the
resume; do not invent metrics or scope. If a bullet lacks a number, write
"(add specific metric)" rather than fabricate.

Output markdown:
# STAR Stories
## <Company> — <Title>
### <one-line bullet>
- **S**: ...
- **T**: ...
- **A**: ...
- **R**: ...
"""


MOCK_SYSTEM = """You are an interviewer conducting a practice session for:
Job: {title} @ {company}
Candidate highlights: {headline}

Behavior:
- Ask ONE question at a time. Wait for the candidate's answer.
- After the candidate answers, give brief (4-6 sentence) feedback: structure (STAR),
  specificity, impact, what to improve.
- Then ask the next question. Mix behavioral, role-specific technical, and one
  system-design question over the session.
- If the candidate types "/end" or "/quit", produce a closing summary with 3
  strengths and 3 things to improve, and stop asking questions.
"""


def _job_prep_dir(job_id: int) -> str:
    d = os.path.join(PREP_DIR, str(job_id))
    os.makedirs(d, exist_ok=True)
    return d


def _load(job_id: int) -> tuple[dict, dict]:
    profile = db.get_profile()
    if not profile:
        raise RuntimeError("No profile in DB. Run `python -m jobsearch profile` first.")
    job = db.get_job(job_id)
    if not job:
        raise RuntimeError(f"No job with id={job_id}.")
    return profile, job


def questions(job_id: int) -> str:
    ensure_dirs()
    profile, job = _load(job_id)
    user = (
        "CANDIDATE (JSON):\n"
        f"{json.dumps({k: profile.get(k) for k in ('headline','summary','skills','experience')}, indent=2)}\n\n"
        f"JOB: {job.get('title')} @ {job.get('company')}\n"
        f"Description:\n{job.get('description') or job.get('raw_snippet') or ''}"
    )
    md = complete(system=QUESTIONS_SYSTEM, user=user, model=REASONING_MODEL, max_tokens=3000)
    path = os.path.join(_job_prep_dir(job_id), "questions.md")
    with open(path, "w") as f:
        f.write(md)
    db.record_prep_session(job_id, "questions", path)
    return path


def company(job_id: int) -> str:
    ensure_dirs()
    _, job = _load(job_id)
    user = (
        f"Company: {job.get('company')}\n"
        f"Role being interviewed for: {job.get('title')}\n"
        f"Location: {job.get('location')}\n\n"
        f"Job description excerpt:\n{(job.get('description') or '')[:2000]}"
    )
    md = complete(system=COMPANY_SYSTEM, user=user, model=REASONING_MODEL, max_tokens=2000)
    path = os.path.join(_job_prep_dir(job_id), "company.md")
    with open(path, "w") as f:
        f.write(md)
    db.record_prep_session(job_id, "company", path)
    return path


def stars(job_id: int) -> str:
    ensure_dirs()
    profile, _ = _load(job_id)
    user = (
        "CANDIDATE EXPERIENCE (JSON):\n"
        f"{json.dumps(profile.get('experience') or [], indent=2)}"
    )
    md = complete(system=STARS_SYSTEM, user=user, model=REASONING_MODEL, max_tokens=3500)
    path = os.path.join(_job_prep_dir(job_id), "star_stories.md")
    with open(path, "w") as f:
        f.write(md)
    db.record_prep_session(job_id, "stars", path)
    return path


def mock(job_id: int) -> str:
    ensure_dirs()
    profile, job = _load(job_id)
    system = MOCK_SYSTEM.format(
        title=job.get("title") or "",
        company=job.get("company") or "",
        headline=profile.get("headline") or "",
    )

    path = os.path.join(_job_prep_dir(job_id), "mock_transcript.md")
    transcript: list[str] = [
        f"# Mock interview — {job.get('title')} @ {job.get('company')}\n"
    ]
    history: list[dict] = [
        {"role": "user", "content": "Please begin. Ask the first question."}
    ]

    print(f"\nMock interview for {job.get('title')} @ {job.get('company')}")
    print("Type '/end' or '/quit' to finish.\n")

    try:
        while True:
            reply = complete_multiturn(system=system, history=history, max_tokens=700, temperature=0.5)
            print(f"\nInterviewer:\n{reply}\n")
            transcript.append(f"\n**Interviewer:** {reply}\n")
            history.append({"role": "assistant", "content": reply})

            user_in = input("You: ").strip()
            if not user_in:
                continue
            transcript.append(f"\n**You:** {user_in}\n")
            history.append({"role": "user", "content": user_in})

            if user_in.lower() in {"/end", "/quit"}:
                closing = complete_multiturn(system=system, history=history, max_tokens=600, temperature=0.3)
                print(f"\nInterviewer (closing):\n{closing}\n")
                transcript.append(f"\n**Interviewer (closing):** {closing}\n")
                break
    except (KeyboardInterrupt, EOFError):
        print("\n(mock interview interrupted)")

    with open(path, "w") as f:
        f.write("\n".join(transcript))
    db.record_prep_session(job_id, "mock", path)
    return path
