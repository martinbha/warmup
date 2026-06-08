#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${CLAUDE_WARMUP_ENV_FILE:-$REPO_DIR/.env}"
LOG_DIR="${CLAUDE_WARMUP_LOG_DIR:-$REPO_DIR/logs}"
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE"
  echo "Copy .env.example to .env and add your Claude OAuth token."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [ -z "${CLAUDE_OAUTH_TOKEN:-}" ]; then
  echo "CLAUDE_OAUTH_TOKEN is empty in $ENV_FILE"
  exit 1
fi

export CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_OAUTH_TOKEN"

mkdir -p "$HOME/.claude" "$LOG_DIR"
printf '%s\n' '{"hasCompletedOnboarding":true}' > "$HOME/.claude.json"

prompt="${CLAUDE_WARMUP_PROMPT:-Reply with exactly: ok}"
model="${CLAUDE_WARMUP_MODEL:-haiku}"
run_log="$LOG_DIR/claude-warmup-$(date -u +%Y%m%dT%H%M%SZ).log"

set +e
claude -p "$prompt" \
  --model "$model" \
  --no-session-persistence \
  >"$run_log" 2>&1
status=$?
set -e

cat "$run_log"

if [ "$status" -eq 0 ]; then
  echo "Claude warmup finished successfully."
  exit 0
fi

if grep -Eiq "expired|unauthorized|invalid token|authentication|auth failed|login required|not logged in" "$run_log"; then
  echo "The Claude OAuth token looks invalid or expired."
  echo "Run 'claude setup-token' again, update .env, and rerun this script."
  exit 1
fi

if grep -Eiq "rate.?limit|usage limit|too many requests" "$run_log"; then
  echo "Claude reported a usage limit. The request still reached Claude, so treating this as a completed warmup."
  exit 0
fi

echo "Claude warmup failed for an unexpected reason. See: $run_log"
exit "$status"
