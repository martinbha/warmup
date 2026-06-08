# Claude Warmup

This repository gives you two ways to run a tiny Claude Code request on a schedule:

1. **GitHub Actions**: GitHub runs the warmup for you.
2. **Ubuntu cron**: your own Ubuntu server runs the warmup from a local `.env` file.

Both paths do the same essential thing: send one small Claude Code prompt with Haiku and no session persistence.

```bash
claude -p "Reply with exactly: ok" --model haiku --no-session-persistence
```

The goal is to touch Claude Code before you begin working, so the usage window starts at a time you choose instead of at the moment you first sit down.

## Repository Layout

```text
.github/workflows/claude-warmup.yml
.env.example
docs/ubuntu-cron.md
scripts/claude-warmup.sh
```

Use the GitHub workflow if you want GitHub-hosted scheduling. Use the Ubuntu cron workflow if you want the warmup to run from a server you control.

## Option 1: GitHub Actions

The GitHub workflow is configured here:

```text
.github/workflows/claude-warmup.yml
```

It runs Monday through Friday at 7:00 AM Korea Standard Time:

```yaml
- cron: "0 22 * * 0-4"
```

GitHub schedules are UTC, so `22:00 UTC` Sunday through Thursday maps to `7:00 AM KST` Monday through Friday.

### GitHub Setup

Create a Claude OAuth token on a machine where Claude Code is installed:

```bash
claude setup-token
```

Copy the token. It usually begins with:

```text
sk-ant-oat01-
```

Add it as a GitHub Actions repository secret:

```bash
gh secret set CLAUDE_OAUTH_TOKEN
```

Or add it in GitHub under:

```text
Settings > Secrets and variables > Actions > New repository secret
```

Use this exact secret name:

```text
CLAUDE_OAUTH_TOKEN
```

### Test The Workflow

Push the workflow to GitHub, then trigger it manually:

```bash
gh workflow run claude-warmup.yml
```

Check the logs:

```bash
gh run list --workflow claude-warmup.yml
gh run view --log
```

A successful run should say:

```text
Claude warmup finished successfully.
```

If Claude reports a usage limit, the workflow treats that as a completed warmup because the request reached Claude.

## Option 2: Ubuntu Cron

The Ubuntu cron setup uses:

```text
scripts/claude-warmup.sh
.env.example
```

This path is useful when you want the warmup to run from a server instead of GitHub Actions. The server stores the Claude token in a local `.env` file.

Read the full Ubuntu guide here:

```text
docs/ubuntu-cron.md
```

The short version:

```bash
cp .env.example .env
nano .env
chmod 600 .env
chmod +x scripts/claude-warmup.sh
./scripts/claude-warmup.sh
```

Then add a cron entry:

```cron
TZ=Asia/Seoul
0 7 * * 1-5 /home/YOUR_USER/tools/warmup/scripts/claude-warmup.sh >> /home/YOUR_USER/tools/warmup/logs/cron.log 2>&1
```

Replace `YOUR_USER` with your Ubuntu username.

## .env Template

For Ubuntu cron, copy `.env.example` to `.env` and fill in the token:

```dotenv
CLAUDE_OAUTH_TOKEN=sk-ant-oat01-your-real-token-here
CLAUDE_WARMUP_PROMPT="Reply with exactly: ok"
CLAUDE_WARMUP_MODEL=haiku
```

The real `.env` file is ignored by Git.

## Verify Timing

After either scheduled path runs, open Claude Code and check:

```text
/usage
```

Compare the displayed reset time with the scheduled warmup time. If it does not line up the way you expect, adjust the schedule and test again.

## Security

Treat the Claude OAuth token like a password.

For GitHub Actions, store it only as a repository secret. For Ubuntu cron, store it only in `.env` and keep that file private:

```bash
chmod 600 .env
```

Do not commit `.env`, paste the token into logs, or share the token in chat.
