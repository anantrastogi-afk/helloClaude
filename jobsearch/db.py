"""SQLite schema, connection helper, and small CRUD utilities."""

import json
import sqlite3
from contextlib import contextmanager
from typing import Any, Iterable

from .util import DB_PATH, now_pst_iso


SCHEMA = """
CREATE TABLE IF NOT EXISTS profile (
  id INTEGER PRIMARY KEY CHECK (id=1),
  full_name TEXT,
  headline TEXT,
  email TEXT,
  phone TEXT,
  location TEXT,
  summary TEXT,
  skills_json TEXT,
  experience_json TEXT,
  education_json TEXT,
  links_json TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  source_url TEXT UNIQUE,
  title TEXT,
  company TEXT,
  location TEXT,
  salary TEXT,
  posted_at TEXT,
  description TEXT,
  raw_snippet TEXT,
  match_score INTEGER,
  match_rationale TEXT,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id INTEGER UNIQUE REFERENCES jobs(id) ON DELETE CASCADE,
  applied_at TEXT,
  resume_path TEXT,
  cover_letter_path TEXT,
  email_draft_path TEXT,
  current_status TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS emails (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  application_id INTEGER REFERENCES applications(id) ON DELETE CASCADE,
  gmail_message_id TEXT UNIQUE,
  thread_id TEXT,
  sender TEXT,
  subject TEXT,
  received_at TEXT,
  snippet TEXT,
  classification TEXT
);

CREATE TABLE IF NOT EXISTS prep_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
  kind TEXT,
  output_path TEXT,
  created_at TEXT
);
"""


@contextmanager
def connect():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with connect() as conn:
        conn.executescript(SCHEMA)


def upsert_profile(fields: dict[str, Any]) -> None:
    payload = {
        "id": 1,
        "full_name": fields.get("full_name"),
        "headline": fields.get("headline"),
        "email": fields.get("email"),
        "phone": fields.get("phone"),
        "location": fields.get("location"),
        "summary": fields.get("summary"),
        "skills_json": json.dumps(fields.get("skills") or []),
        "experience_json": json.dumps(fields.get("experience") or []),
        "education_json": json.dumps(fields.get("education") or []),
        "links_json": json.dumps(fields.get("links") or []),
        "updated_at": now_pst_iso(),
    }
    with connect() as conn:
        conn.execute(
            """
            INSERT INTO profile (id, full_name, headline, email, phone, location, summary,
                                 skills_json, experience_json, education_json, links_json, updated_at)
            VALUES (:id, :full_name, :headline, :email, :phone, :location, :summary,
                    :skills_json, :experience_json, :education_json, :links_json, :updated_at)
            ON CONFLICT(id) DO UPDATE SET
              full_name=excluded.full_name,
              headline=excluded.headline,
              email=excluded.email,
              phone=excluded.phone,
              location=excluded.location,
              summary=excluded.summary,
              skills_json=excluded.skills_json,
              experience_json=excluded.experience_json,
              education_json=excluded.education_json,
              links_json=excluded.links_json,
              updated_at=excluded.updated_at
            """,
            payload,
        )


def get_profile() -> dict | None:
    with connect() as conn:
        row = conn.execute("SELECT * FROM profile WHERE id=1").fetchone()
    if not row:
        return None
    p = dict(row)
    for src, dst in (("skills_json", "skills"), ("experience_json", "experience"),
                     ("education_json", "education"), ("links_json", "links")):
        p[dst] = json.loads(p.pop(src) or "[]")
    return p


def insert_job(job: dict) -> int | None:
    """Insert a job; return rowid or None if duplicate source_url."""
    with connect() as conn:
        try:
            cur = conn.execute(
                """
                INSERT INTO jobs (source, source_url, title, company, location, salary,
                                  posted_at, description, raw_snippet, status, created_at)
                VALUES (:source, :source_url, :title, :company, :location, :salary,
                        :posted_at, :description, :raw_snippet, 'new', :created_at)
                """,
                {
                    "source": job.get("source"),
                    "source_url": job.get("source_url"),
                    "title": job.get("title"),
                    "company": job.get("company"),
                    "location": job.get("location"),
                    "salary": job.get("salary"),
                    "posted_at": job.get("posted_at"),
                    "description": job.get("description"),
                    "raw_snippet": job.get("raw_snippet"),
                    "created_at": now_pst_iso(),
                },
            )
            return cur.lastrowid
        except sqlite3.IntegrityError:
            return None


def update_job(job_id: int, **fields) -> None:
    if not fields:
        return
    keys = ", ".join(f"{k}=:{k}" for k in fields)
    fields["id"] = job_id
    with connect() as conn:
        conn.execute(f"UPDATE jobs SET {keys} WHERE id=:id", fields)


def get_job(job_id: int) -> dict | None:
    with connect() as conn:
        row = conn.execute("SELECT * FROM jobs WHERE id=?", (job_id,)).fetchone()
    return dict(row) if row else None


def list_jobs(status: str | None = None, min_score: int | None = None) -> list[dict]:
    sql = "SELECT * FROM jobs WHERE 1=1"
    args: list[Any] = []
    if status:
        sql += " AND status=?"
        args.append(status)
    if min_score is not None:
        sql += " AND COALESCE(match_score, -1) >= ?"
        args.append(min_score)
    sql += " ORDER BY COALESCE(match_score, -1) DESC, created_at DESC"
    with connect() as conn:
        return [dict(r) for r in conn.execute(sql, args).fetchall()]


def unscored_jobs() -> list[dict]:
    with connect() as conn:
        rows = conn.execute("SELECT * FROM jobs WHERE match_score IS NULL").fetchall()
    return [dict(r) for r in rows]


def create_application(job_id: int, resume_path: str, cover_letter_path: str,
                       email_draft_path: str) -> int:
    with connect() as conn:
        cur = conn.execute(
            """
            INSERT INTO applications (job_id, applied_at, resume_path, cover_letter_path,
                                      email_draft_path, current_status)
            VALUES (?, ?, ?, ?, ?, 'applied')
            ON CONFLICT(job_id) DO UPDATE SET
              applied_at=excluded.applied_at,
              resume_path=excluded.resume_path,
              cover_letter_path=excluded.cover_letter_path,
              email_draft_path=excluded.email_draft_path,
              current_status='applied'
            """,
            (job_id, now_pst_iso(), resume_path, cover_letter_path, email_draft_path),
        )
        row = conn.execute("SELECT id FROM applications WHERE job_id=?", (job_id,)).fetchone()
    return row["id"]


def list_open_applications() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT a.*, j.title, j.company, j.location
            FROM applications a
            JOIN jobs j ON j.id = a.job_id
            WHERE a.current_status NOT IN ('rejected', 'offer')
            ORDER BY a.applied_at DESC
            """
        ).fetchall()
    return [dict(r) for r in rows]


def record_email(application_id: int, message: dict, classification: str) -> None:
    with connect() as conn:
        conn.execute(
            """
            INSERT OR IGNORE INTO emails
              (application_id, gmail_message_id, thread_id, sender, subject,
               received_at, snippet, classification)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                application_id,
                message.get("gmail_message_id"),
                message.get("thread_id"),
                message.get("sender"),
                message.get("subject"),
                message.get("received_at"),
                message.get("snippet"),
                classification,
            ),
        )


def set_application_status(application_id: int, status: str) -> None:
    with connect() as conn:
        conn.execute(
            "UPDATE applications SET current_status=? WHERE id=?",
            (status, application_id),
        )
        row = conn.execute("SELECT job_id FROM applications WHERE id=?", (application_id,)).fetchone()
        if row:
            conn.execute("UPDATE jobs SET status=? WHERE id=?", (status, row["job_id"]))


def record_prep_session(job_id: int, kind: str, output_path: str) -> None:
    with connect() as conn:
        conn.execute(
            "INSERT INTO prep_sessions (job_id, kind, output_path, created_at) VALUES (?, ?, ?, ?)",
            (job_id, kind, output_path, now_pst_iso()),
        )


def status_counts() -> dict[str, int]:
    with connect() as conn:
        rows = conn.execute(
            "SELECT status, COUNT(*) AS n FROM jobs GROUP BY status"
        ).fetchall()
    return {r["status"]: r["n"] for r in rows}
