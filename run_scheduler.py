#!/usr/bin/env python3
"""
Always-on Python scheduler — alternative to cron.
Runs the Gmail Summary Agent every day at 7:45 AM PST.

Usage:
    pip install schedule
    python run_scheduler.py          # runs forever (use nohup / screen / systemd)
    python run_scheduler.py --now    # run once immediately then exit
"""

import argparse
import logging
import time
from datetime import datetime, timezone, timedelta

import schedule

from gmail_summary_agent import run_agent

PST = timezone(timedelta(hours=-8))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


def job():
    log.info("Starting daily Gmail summary...")
    try:
        run_agent()
        log.info("Summary complete.")
    except Exception as exc:
        log.error("Agent failed: %s", exc, exc_info=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--now", action="store_true", help="Run once immediately and exit")
    args = parser.parse_args()

    if args.now:
        job()
        return

    # schedule at 07:45 PST — schedule library uses local time, so we
    # convert 07:45 PST to the server's local time at startup.
    target_pst = datetime.now(PST).replace(hour=7, minute=45, second=0, microsecond=0)
    local_time_str = target_pst.astimezone().strftime("%H:%M")

    schedule.every().day.at(local_time_str).do(job)
    log.info("Scheduler started — daily run at 07:45 PST (local: %s). Ctrl-C to stop.", local_time_str)

    while True:
        schedule.run_pending()
        time.sleep(30)


if __name__ == "__main__":
    main()
