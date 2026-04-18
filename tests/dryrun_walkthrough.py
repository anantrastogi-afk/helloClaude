"""End-to-end dry-run walkthrough of the jobsearch CLI.

Stubs the Anthropic SDK and outbound HTTP so we can exercise the full pipeline
(init → profile → jobs → apply → track → prep) without network/API access.

Run with:
    python tests/dryrun_walkthrough.py
"""

import json
import os
import shutil
import sqlite3
import sys
import types
from unittest.mock import patch

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)


# ---------- Canned LLM responses keyed by "stage" we set per call ----------

STAGE = {"current": None}

CANNED = {
    "profile": {
        "full_name": "Jane Doe",
        "headline": "Senior Software Engineer — distributed systems, 10+ yrs",
        "email": "jane@example.com",
        "phone": "+1-555-0100",
        "location": "San Francisco, CA",
        "summary": "Backend engineer with a decade of experience designing and "
                   "operating high-throughput distributed systems in Go and Python.",
        "skills": ["Go", "Python", "Kubernetes", "Kafka", "Postgres", "AWS",
                   "distributed systems", "system design", "observability"],
        "experience": [
            {
                "company": "Acme Cloud",
                "title": "Staff Software Engineer",
                "start": "2021-03",
                "end": "present",
                "location": "San Francisco, CA",
                "bullets": [
                    "Led rewrite of ingestion pipeline processing 2B events/day, cutting p99 latency 45%.",
                    "Mentored 6 engineers; drove tech-spec review culture across 3 teams."
                ]
            },
            {
                "company": "DataWorks",
                "title": "Senior Software Engineer",
                "start": "2016-06",
                "end": "2021-02",
                "location": "Remote",
                "bullets": [
                    "Designed multi-region replication for the metadata store (500M rows).",
                    "Owned on-call rotation; reduced SEV2 incidents by 30% over 18 months."
                ]
            }
        ],
        "education": [
            {"school": "UIUC", "degree": "B.S. Computer Science",
             "start": "2010", "end": "2014", "details": "GPA 3.8"}
        ],
        "links": [
            {"label": "GitHub", "url": "https://github.com/janedoe"},
            {"label": "LinkedIn", "url": "https://linkedin.com/in/janedoe"}
        ]
    },
    "linkedin_jobs": [
        {"title": "Staff Software Engineer, Platform", "company": "Stripe",
         "location": "San Francisco, CA (hybrid)", "salary": None,
         "url": "https://linkedin.com/jobs/view/stripe-staff-platform-0001",
         "snippet": "Own the core services platform. Go/Python, Kubernetes, SRE mindset."},
        {"title": "Principal Engineer, Data Infra", "company": "Snowflake",
         "location": "Remote (US)", "salary": "$320k-$420k",
         "url": "https://linkedin.com/jobs/view/snowflake-principal-0002",
         "snippet": "Scale the ingestion tier of the data cloud. Rust/C++ preferred."},
        {"title": "Senior Backend Engineer", "company": "Plaid",
         "location": "NYC", "salary": None,
         "url": "https://linkedin.com/jobs/view/plaid-senior-0003",
         "snippet": "Design financial APIs used by 8000+ apps. Python + Postgres."}
    ],
    "manual_job": {
        "title": "Senior Distributed Systems Engineer",
        "company": "Vercel",
        "location": "Remote",
        "salary": "$240k-$300k",
        "description": "Build the serverless edge platform. Strong Go + Kubernetes."
    },
    "score_stripe": {"score": 92, "rationale": "Direct match on platform/Go/K8s, senior scope.",
                     "missing_skills": []},
    "score_snowflake": {"score": 68, "rationale": "Data infra scale aligns; Rust/C++ gap.",
                        "missing_skills": ["Rust", "C++"]},
    "score_plaid": {"score": 78, "rationale": "Backend fit; location mismatch (NYC vs SF).",
                    "missing_skills": []},
    "score_vercel": {"score": 88, "rationale": "Go + K8s + distributed systems are core match.",
                     "missing_skills": []},
    "materials": {
        "resume_md": "# Jane Doe\nSenior SWE — distributed systems\n\n## Summary\n...(tailored)...\n",
        "cover_letter_md": "Dear Stripe Hiring Team,\n\n(tailored cover letter)...\n\nJane",
        "email_md": "Subject: Application — Staff Software Engineer, Platform\n\nHi team,\n\n(short email)...\n\nJane"
    },
    "classify_interview": {"classification": "interview_invite", "reason": "Recruiter proposes times next week."},
    "classify_rejection": {"classification": "rejection", "reason": "Explicit 'not moving forward' language."},
    "questions_md": "# Stripe — Staff Software Engineer Interview Prep\n\n## Behavioral\n1. ...\n",
    "stars_md":  "# STAR Stories\n\n## Acme Cloud — Staff Software Engineer\n### Led rewrite...\n- **S**: ...\n",
    "company_md": "# Stripe — briefing\n\n## What they do\nPayments infra...\n",
    "mock_turn_1": "Tell me about a time you reduced latency on a critical pipeline.",
}


# ---------- Stubs ----------

class _StubTextBlock:
    type = "text"
    def __init__(self, text): self.text = text


class _StubMsg:
    def __init__(self, text): self.content = [_StubTextBlock(text)]


def _stub_response_text() -> str:
    stage = STAGE["current"]
    if stage == "profile":
        return json.dumps(CANNED["profile"])
    if stage == "linkedin":
        return json.dumps(CANNED["linkedin_jobs"])
    if stage == "manual":
        return json.dumps(CANNED["manual_job"])
    if stage and stage.startswith("score_"):
        return json.dumps(CANNED[stage])
    if stage == "materials":
        return json.dumps(CANNED["materials"])
    if stage == "classify_interview":
        return json.dumps(CANNED["classify_interview"])
    if stage == "classify_rejection":
        return json.dumps(CANNED["classify_rejection"])
    if stage == "questions":
        return CANNED["questions_md"]
    if stage == "stars":
        return CANNED["stars_md"]
    if stage == "company":
        return CANNED["company_md"]
    raise AssertionError(f"No canned response for stage={stage!r}")


class _StubAnthropic:
    class messages:
        @staticmethod
        def create(**kwargs):
            return _StubMsg(_stub_response_text())

    def __init__(self, *a, **kw):
        pass


# ---------- Helpers ----------

def banner(msg: str) -> None:
    print(f"\n{'=' * 72}\n{msg}\n{'=' * 72}")


def dump_db(note: str) -> None:
    from jobsearch.util import DB_PATH
    conn = sqlite3.connect(DB_PATH)
    print(f"  [db/{note}]")
    for tbl in ("profile", "jobs", "applications", "emails", "prep_sessions"):
        n = conn.execute(f"SELECT COUNT(*) FROM {tbl}").fetchone()[0]
        print(f"    {tbl}: {n} row(s)")
    conn.close()


def reset_repo_state() -> None:
    """Wipe prior runs so the walkthrough is reproducible."""
    from jobsearch.util import DB_PATH, OUT_DIR, RESUME_PDF
    for p in (DB_PATH, DB_PATH + "-journal"):
        if os.path.exists(p):
            os.remove(p)
    if os.path.exists(OUT_DIR):
        shutil.rmtree(OUT_DIR)
    # Ensure a placeholder PDF exists — content doesn't matter, we stub the LLM.
    os.makedirs(os.path.dirname(RESUME_PDF), exist_ok=True)
    if not os.path.exists(RESUME_PDF):
        # Minimal valid-ish PDF header; the stub LLM ignores content.
        with open(RESUME_PDF, "wb") as f:
            f.write(b"%PDF-1.4\n%placeholder for dryrun\n%%EOF\n")


def run_walkthrough() -> None:
    # Monkey-patch the SDK factory used in the package.
    with patch("anthropic.Anthropic", _StubAnthropic):
        from jobsearch import apply as apply_mod
        from jobsearch import db as dbmod
        from jobsearch import jobs as jobs_mod
        from jobsearch import prep as prep_mod
        from jobsearch import profile as profile_mod
        from jobsearch import tracker as tracker_mod
        from jobsearch.sources import linkedin_email, manual

        # -- 0. reset + init
        banner("STEP 0  reset + init")
        reset_repo_state()
        dbmod.init_db()
        print("  DB + folders ready.")
        dump_db("after init")

        # -- 1. profile
        banner("STEP 1  profile (parse resume/input.pdf)")
        STAGE["current"] = "profile"
        p = profile_mod.build_profile()
        profile_mod.print_profile_summary(p)
        dump_db("after profile")

        # -- 2. ingest jobs (linkedin_email + manual)
        banner("STEP 2a  ingest LinkedIn job-alert emails")
        STAGE["current"] = "linkedin"
        li_ids = linkedin_email.ingest_from_text("<three canned LinkedIn email bodies>")
        print(f"  inserted job ids: {li_ids}")

        banner("STEP 2b  ingest one job via --text")
        STAGE["current"] = "manual"
        manual_id = manual.add(text="Pasted JD for Vercel role")
        print(f"  inserted manual job id: {manual_id}")

        # -- 3. score all unscored jobs
        banner("STEP 3  score matches")
        # Set the stage per-call by title ordering. Insert order is deterministic:
        # li[0]=Stripe, li[1]=Snowflake, li[2]=Plaid, manual=Vercel.
        score_sequence = iter(["score_stripe", "score_snowflake", "score_plaid", "score_vercel"])

        def _scoring_stage(*_a, **_kw):
            STAGE["current"] = next(score_sequence)
            return _StubMsg(_stub_response_text())

        with patch.object(_StubAnthropic.messages, "create", staticmethod(_scoring_stage)):
            n = jobs_mod.score_unscored()
        print(f"  scored: {n}")
        print("\n  Ranked list:")
        jobs_mod.print_list()

        # -- 4. close one job (say Snowflake — we rejected the Rust requirement)
        banner("STEP 4  close the low-fit job")
        snowflake_id = li_ids[1]
        jobs_mod.close_job(snowflake_id, reason="Rust/C++ requirement not a fit")
        print(f"  closed id={snowflake_id}")
        print("\n  After close:")
        jobs_mod.print_list()

        # -- 5. apply for Stripe (highest score)
        banner("STEP 5  apply for the top match")
        stripe_id = li_ids[0]
        STAGE["current"] = "materials"
        res = apply_mod.generate(stripe_id)
        for k, v in res.items():
            print(f"  {k}: {v}")
        for fn in ("resume.md", "cover_letter.md", "email_draft.md"):
            path = os.path.join(os.path.dirname(res["resume_path"]), fn)
            size = os.path.getsize(path)
            print(f"    {fn}: {size} bytes")
        dump_db("after apply")

        # -- 6. track: ingest a fake interview invite, then (on another app) a rejection
        banner("STEP 6a  tracker: build Gmail queries")
        queries = tracker_mod.build_gmail_queries()
        print(json.dumps(queries, indent=2))

        banner("STEP 6b  tracker: classify an interview invite for Stripe")
        STAGE["current"] = "classify_interview"
        stripe_app_id = res["application_id"]
        tracker_mod.ingest_messages(stripe_app_id, [
            {
                "gmail_message_id": "m-001",
                "thread_id": "t-001",
                "sender": "recruiter@stripe.com",
                "subject": "Re: Your application — Staff SWE, Platform",
                "received_at": "2026-04-18T10:00:00-08:00",
                "snippet": "Hi Jane — would love to set up a 30-min chat next week. Here are some times...",
            }
        ])
        dump_db("after interview_invite")
        with sqlite3.connect(os.path.join(REPO, "jobsearch.db")) as c:
            row = c.execute(
                "SELECT current_status FROM applications WHERE id=?",
                (stripe_app_id,),
            ).fetchone()
            print(f"  application {stripe_app_id} status → {row[0]!r}")

        # Apply for Plaid and then reject it.
        banner("STEP 6c  apply Plaid → classify rejection")
        plaid_id = li_ids[2]
        STAGE["current"] = "materials"
        plaid_res = apply_mod.generate(plaid_id)
        STAGE["current"] = "classify_rejection"
        tracker_mod.ingest_messages(plaid_res["application_id"], [
            {
                "gmail_message_id": "m-002",
                "thread_id": "t-002",
                "sender": "noreply@plaid.com",
                "subject": "Update on your application",
                "received_at": "2026-04-18T12:00:00-08:00",
                "snippet": "Thanks for your interest; we've decided not to move forward at this time.",
            }
        ])
        with sqlite3.connect(os.path.join(REPO, "jobsearch.db")) as c:
            row = c.execute(
                "SELECT current_status FROM applications WHERE id=?",
                (plaid_res["application_id"],),
            ).fetchone()
            print(f"  application {plaid_res['application_id']} (Plaid) status → {row[0]!r}")

        # -- 7. prep — questions + STAR stories (non-interactive)
        banner("STEP 7a  prep questions for Stripe")
        STAGE["current"] = "questions"
        q_path = prep_mod.questions(stripe_id)
        print(f"  wrote {q_path}  ({os.path.getsize(q_path)} bytes)")

        banner("STEP 7b  prep STAR stories")
        STAGE["current"] = "stars"
        s_path = prep_mod.stars(stripe_id)
        print(f"  wrote {s_path}  ({os.path.getsize(s_path)} bytes)")

        banner("STEP 7c  prep company brief")
        STAGE["current"] = "company"
        c_path = prep_mod.company(stripe_id)
        print(f"  wrote {c_path}  ({os.path.getsize(c_path)} bytes)")

        # -- 8. final status / dashboard
        banner("STEP 8  final dashboard")
        from jobsearch.cli import _cmd_status
        _ns = types.SimpleNamespace()
        _cmd_status(_ns)

        banner("DRY-RUN COMPLETE")


if __name__ == "__main__":
    run_walkthrough()
