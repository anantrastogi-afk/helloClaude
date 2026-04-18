#!/usr/bin/env bash
# Installs a daily cron job to run the Gmail Summary Agent at 7:45 AM PST.
# Run once:  bash setup_schedule.sh

set -euo pipefail

PYTHON=$(which python3)
SCRIPT="$(cd "$(dirname "$0")" && pwd)/gmail_summary_agent.py"
LOG="$(cd "$(dirname "$0")" && pwd)/summaries/cron.log"

# Create summaries dir so the log path exists before first run.
mkdir -p "$(dirname "$LOG")"

CRON_LINE="45 15 * * * TZ=America/Los_Angeles $PYTHON $SCRIPT >> $LOG 2>&1"

# Add only if not already present.
if crontab -l 2>/dev/null | grep -qF "$SCRIPT"; then
    echo "Cron job already installed — no changes made."
else
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    echo "Cron job installed successfully."
    echo ""
    echo "Schedule : every day at 7:45 AM PST (15:45 UTC)"
    echo "Script   : $SCRIPT"
    echo "Log      : $LOG"
    echo "Summaries: $(dirname "$LOG")/"
fi

echo ""
echo "Current crontab:"
crontab -l
