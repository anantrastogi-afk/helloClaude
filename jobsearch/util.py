"""Shared constants and small helpers."""

import json
import os
from datetime import datetime, timezone, timedelta

PST = timezone(timedelta(hours=-8))

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(REPO_ROOT, "jobsearch.db")
RESUME_DIR = os.path.join(REPO_ROOT, "resume")
RESUME_PDF = os.path.join(RESUME_DIR, "input.pdf")
OUT_DIR = os.path.join(REPO_ROOT, "out")
APPLICATIONS_DIR = os.path.join(OUT_DIR, "applications")
PREP_DIR = os.path.join(OUT_DIR, "prep")
PROFILE_JSON = os.path.join(OUT_DIR, "profile.json")


def now_pst_iso() -> str:
    return datetime.now(PST).isoformat(timespec="seconds")


def now_pst_str() -> str:
    return datetime.now(PST).strftime("%B %d, %Y %I:%M %p PST")


def ensure_dirs() -> None:
    for d in (RESUME_DIR, OUT_DIR, APPLICATIONS_DIR, PREP_DIR):
        os.makedirs(d, exist_ok=True)


def extract_json_block(text: str) -> dict | list:
    """
    Pull the first JSON object/array from a Claude response.
    Handles responses wrapped in ```json fences or surrounded by prose.
    """
    text = text.strip()
    if text.startswith("```"):
        text = text.strip("`")
        if text.lower().startswith("json"):
            text = text[4:]
        text = text.strip()
        if text.endswith("```"):
            text = text[:-3].strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    start_obj = text.find("{")
    start_arr = text.find("[")
    candidates = [i for i in (start_obj, start_arr) if i != -1]
    if not candidates:
        raise ValueError(f"No JSON object/array found in response:\n{text[:400]}")
    start = min(candidates)
    opener = text[start]
    closer = "}" if opener == "{" else "]"
    depth = 0
    for i in range(start, len(text)):
        c = text[i]
        if c == opener:
            depth += 1
        elif c == closer:
            depth -= 1
            if depth == 0:
                return json.loads(text[start : i + 1])
    raise ValueError(f"Unbalanced JSON in response:\n{text[:400]}")
