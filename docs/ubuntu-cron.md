# Ubuntu Cron Workflow

This guide explains how to run the same Claude warmup behavior from an Ubuntu server instead of GitHub Actions.

The server loads your Claude OAuth token from a local `.env` file, runs one small Haiku prompt through the Claude Code CLI, writes a log, and exits.

## Files Used

```text
.env.example
scripts/claude-warmup.sh
```

`.env.example` is the template for your private `.env` file. `scripts/claude-warmup.sh` is the command cron runs.

The real `.env` file is ignored by Git so the token does not get committed.

## How The Script Works

The cron job runs this script:

```bash
scripts/claude-warmup.sh
```

The script:

1. Loads `.env`.
2. Exports `CLAUDE_CODE_OAUTH_TOKEN` for the Claude Code CLI.
3. Creates Claude's minimal onboarding marker file.
4. Sends a tiny prompt using Haiku.
5. Stores the command output under `logs/`.
6. Treats ordinary usage-limit responses as a completed warmup because the request reached Claude.

The Claude command is:

```bash
claude -p "$CLAUDE_WARMUP_PROMPT" --model "$CLAUDE_WARMUP_MODEL" --no-session-persistence
```

## Ubuntu Server Setup

SSH into the Ubuntu server that will run the cron job.

Update packages and install Node.js and npm if they are not already installed:

```bash
sudo apt update
sudo apt install -y nodejs npm
```

Install Claude Code globally:

```bash
sudo npm install -g @anthropic-ai/claude-code@latest
```

Confirm the command is available:

```bash
which claude
claude --version
```

Clone or copy this repository onto the server. A common location is:

```bash
mkdir -p ~/tools
git clone <your-repo-url> ~/tools/warmup
cd ~/tools/warmup
```

Make sure the script is executable:

```bash
chmod +x scripts/claude-warmup.sh
```

## Create The Claude Token

On a machine where you can complete the browser login, run:

```bash
claude setup-token
```

Claude Code will open an OAuth flow and print a token when finished. Copy the full token. It usually begins with:

```text
sk-ant-oat01-
```

Treat this token like a password.

## Create The .env File

On the Ubuntu server:

```bash
cd ~/tools/warmup
cp .env.example .env
nano .env
```

Replace the placeholder token:

```dotenv
CLAUDE_OAUTH_TOKEN=sk-ant-oat01-your-real-token-here
CLAUDE_WARMUP_PROMPT="Reply with exactly: ok"
CLAUDE_WARMUP_MODEL=haiku
```

Lock down the file permissions:

```bash
chmod 600 .env
```

The script maps `CLAUDE_OAUTH_TOKEN` from `.env` to `CLAUDE_CODE_OAUTH_TOKEN`, which is the environment variable expected by Claude Code.

## Manual Test

Before installing the cron job, run the warmup by hand:

```bash
cd ~/tools/warmup
./scripts/claude-warmup.sh
```

A successful run should print a small Claude response and:

```text
Claude warmup finished successfully.
```

If Claude reports a usage limit, the script may print:

```text
Claude reported a usage limit. The request still reached Claude, so treating this as a completed warmup.
```

That is also considered successful for this use case.

Logs are written to:

```text
logs/
```

## Install The Cron Job

Edit the current user's crontab:

```bash
crontab -e
```

To run the warmup Monday through Friday at 7:00 AM Korea Standard Time, add:

```cron
TZ=Asia/Seoul
0 7 * * 1-5 /home/YOUR_USER/tools/warmup/scripts/claude-warmup.sh >> /home/YOUR_USER/tools/warmup/logs/cron.log 2>&1
```

Replace `YOUR_USER` with your Ubuntu username.

Using `TZ=Asia/Seoul` keeps the schedule readable. The server can be configured for UTC or any other timezone; this cron entry still means 7:00 AM KST.

If you prefer UTC directly, 7:00 AM KST is 10:00 PM UTC on the previous day:

```cron
0 22 * * 0-4 /home/YOUR_USER/tools/warmup/scripts/claude-warmup.sh >> /home/YOUR_USER/tools/warmup/logs/cron.log 2>&1
```

Use one of those two cron styles, not both.

## Verify The Cron Schedule

List the installed crontab:

```bash
crontab -l
```

Check that the script path is absolute and matches where you cloned the repository.

You can also check cron logs on Ubuntu:

```bash
grep CRON /var/log/syslog | tail -50
```

After the scheduled time passes, check this repository's logs:

```bash
cd ~/tools/warmup
ls -lah logs
tail -100 logs/cron.log
```

## Confirm Claude Usage Timing

After the cron job runs, open Claude Code locally and check usage:

```text
/usage
```

Compare the reset time with the cron run time. If the window is anchored the way you expect, the reset should line up with the scheduled warmup.

## Changing The Time

With the KST-style crontab:

```cron
TZ=Asia/Seoul
0 7 * * 1-5 ...
```

Change the first two fields:

```text
minute hour
```

Examples:

| Desired KST time | Cron line start |
| --- | --- |
| 6:00 AM weekdays | `0 6 * * 1-5` |
| 7:00 AM weekdays | `0 7 * * 1-5` |
| 8:30 AM weekdays | `30 8 * * 1-5` |

Cron does not need the previous-day UTC conversion when `TZ=Asia/Seoul` is set in the crontab.

## Troubleshooting

### `Missing env file`

Create `.env` from the example:

```bash
cp .env.example .env
```

Then add your real token.

### `CLAUDE_OAUTH_TOKEN is empty`

Open `.env` and make sure the token line has a value:

```dotenv
CLAUDE_OAUTH_TOKEN=sk-ant-oat01-your-real-token-here
```

Do not wrap the token in quotes unless your shell requires it.

### `claude: command not found`

Find Claude's full path:

```bash
which claude
```

If cron still cannot find it, add `PATH` near the top of your crontab:

```cron
PATH=/usr/local/bin:/usr/bin:/bin
```

Or call Claude by absolute path inside `scripts/claude-warmup.sh`.

### Token Expired Or Invalid

Generate a new token:

```bash
claude setup-token
```

Then update `.env`.

### Cron Runs But No Logs Appear

Make sure the log directory exists:

```bash
mkdir -p ~/tools/warmup/logs
```

Also confirm that the cron path uses the correct username and repository location.

## Security Notes

Keep `.env` private:

```bash
chmod 600 .env
```

Do not commit `.env`, paste the token into logs, or share the token in chat. If you stop using the server, delete the `.env` file or revoke the token by generating a replacement.
