"""Unified CLI dispatcher. Run as: python -m jobsearch <command> [args]"""

import argparse
import json
import sys

from . import apply as apply_mod
from . import db, jobs, prep, profile, tracker
from .sources import manual as manual_src
from .sources import scraper as scraper_src
from .util import ensure_dirs, now_pst_str


def _cmd_init(_):
    ensure_dirs()
    db.init_db()
    print(f"Initialized database and folders at {now_pst_str()}.")
    print("Next step: drop your resume PDF at resume/input.pdf, then run `python -m jobsearch profile`.")


def _cmd_profile(_):
    p = profile.build_profile()
    print("Profile built:")
    profile.print_profile_summary(p)


def _cmd_jobs_pull(args):
    bodies = None
    if args.linkedin_file:
        with open(args.linkedin_file) as f:
            bodies = f.read()
    elif not sys.stdin.isatty():
        bodies = sys.stdin.read().strip() or None
    result = jobs.pull_all(linkedin_email_bodies=bodies)
    print(f"Inserted: {result['inserted']}  Scored: {result['scored']}")


def _cmd_jobs_add(args):
    job_id = manual_src.add(url=args.url, text=args.text)
    if job_id is None:
        print("Could not add job (duplicate URL or parse error).")
        return
    print(f"Added job id={job_id}. Run `python -m jobsearch jobs pull` to score it.")


def _cmd_jobs_scrape(args):
    job_id = scraper_src.scrape(args.url, confirm_tos=args.confirm_tos)
    print(f"Scraped job id={job_id}." if job_id else "Could not scrape (parse error or duplicate).")


def _cmd_jobs_list(args):
    jobs.print_list(status=args.status, min_score=args.min_score)


def _cmd_jobs_close(args):
    jobs.close_job(args.id, reason=args.reason)
    print(f"Closed job id={args.id}.")


def _cmd_apply(args):
    result = apply_mod.generate(args.id)
    print("Materials generated:")
    for k, v in result.items():
        print(f"  {k}: {v}")


def _cmd_track_queries(_):
    qs = tracker.build_gmail_queries()
    print(json.dumps(qs, indent=2))
    print(
        "\n# Next step: within Claude Code, run `search_threads` for each query "
        "above, then pipe results into `python -m jobsearch track ingest <application_id>`.",
        file=sys.stderr,
    )


def _cmd_track_ingest(args):
    data = sys.stdin.read().strip()
    if not data:
        print("Pipe a JSON array of messages on stdin.")
        sys.exit(1)
    messages = json.loads(data)
    if not isinstance(messages, list):
        print("Expected a JSON array.")
        sys.exit(1)
    results = tracker.ingest_messages(args.application_id, messages)
    for mid, label in results:
        print(f"  {mid}  →  {label}")


def _cmd_track_ghost(args):
    n = tracker.mark_ghosted(days=args.days)
    print(f"Flagged {n} application(s) as ghosted (no reply in {args.days}d).")


def _cmd_prep(args):
    match args.kind:
        case "questions":
            print("Wrote:", prep.questions(args.id))
        case "company":
            print("Wrote:", prep.company(args.id))
        case "stars":
            print("Wrote:", prep.stars(args.id))
        case "mock":
            print("Wrote:", prep.mock(args.id))


def _cmd_status(_):
    counts = db.status_counts()
    print("Jobs by status:")
    for k, v in sorted(counts.items()):
        print(f"  {k:<12}  {v}")
    print()
    apps = db.list_open_applications()
    if not apps:
        print("No open applications.")
        return
    print("Open applications:")
    print(f"{'APP':>4}  {'JOB':>4}  {'STATUS':<10}  {'APPLIED':<20}  TITLE @ COMPANY")
    print("-" * 100)
    for a in apps:
        applied = (a.get("applied_at") or "")[:19]
        print(
            f"{a['id']:>4}  {a['job_id']:>4}  {a['current_status']:<10}  {applied:<20}  "
            f"{(a['title'] or '')[:40]} @ {a['company'] or ''}"
        )


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="jobsearch", description="Job search & resume platform")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init", help="Create DB and folders").set_defaults(func=_cmd_init)
    sub.add_parser("profile", help="Parse resume/input.pdf → profile").set_defaults(func=_cmd_profile)
    sub.add_parser("status", help="Dashboard").set_defaults(func=_cmd_status)

    # jobs
    jobs_p = sub.add_parser("jobs", help="Job ingest / list / close")
    jobs_sub = jobs_p.add_subparsers(dest="jobs_cmd", required=True)

    pull = jobs_sub.add_parser("pull", help="Pull from sources + score")
    pull.add_argument("--linkedin-file", help="Path to a file containing LinkedIn job-alert email bodies.")
    pull.set_defaults(func=_cmd_jobs_pull)

    addp = jobs_sub.add_parser("add", help="Add a single job via URL or pasted text")
    addp.add_argument("--url")
    addp.add_argument("--text")
    addp.set_defaults(func=_cmd_jobs_add)

    scr = jobs_sub.add_parser("scrape", help="Scrape a public job page (requires --confirm-tos)")
    scr.add_argument("url")
    scr.add_argument("--confirm-tos", action="store_true")
    scr.set_defaults(func=_cmd_jobs_scrape)

    lst = jobs_sub.add_parser("list", help="List jobs")
    lst.add_argument("--status")
    lst.add_argument("--min-score", type=int)
    lst.set_defaults(func=_cmd_jobs_list)

    clo = jobs_sub.add_parser("close", help="Mark job not applicable")
    clo.add_argument("id", type=int)
    clo.add_argument("--reason")
    clo.set_defaults(func=_cmd_jobs_close)

    # apply
    appl = sub.add_parser("apply", help="Generate tailored materials for a job id")
    appl.add_argument("id", type=int)
    appl.set_defaults(func=_cmd_apply)

    # track
    trk = sub.add_parser("track", help="Recruiter email tracking")
    trk_sub = trk.add_subparsers(dest="track_cmd", required=True)
    trk_sub.add_parser("queries", help="Print Gmail queries for each open app").set_defaults(func=_cmd_track_queries)
    ing = trk_sub.add_parser("ingest", help="Classify messages piped on stdin for an application")
    ing.add_argument("application_id", type=int)
    ing.set_defaults(func=_cmd_track_ingest)
    ghost = trk_sub.add_parser("ghost", help="Mark silent apps as ghosted")
    ghost.add_argument("--days", type=int, default=14)
    ghost.set_defaults(func=_cmd_track_ghost)

    # prep
    prp = sub.add_parser("prep", help="Interview prep for a job id")
    prp.add_argument("id", type=int)
    prp.add_argument("kind", choices=["questions", "company", "mock", "stars"])
    prp.set_defaults(func=_cmd_prep)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
