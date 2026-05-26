# Claude Warmup

This repository runs a tiny Claude Code request on a schedule.

The goal is to touch Claude Code before you begin working, so your five-hour usage window starts at a time you choose instead of at the moment you first sit down. The workflow sends one small Haiku prompt and exits. It does not clone your projects, run tools, or keep a Claude session.

## What is included

The repository has one workflow:

```text
.github/workflows/claude-warmup.yml
```

It does three things:

1. Confirms that the `CLAUDE_OAUTH_TOKEN` GitHub secret exists.
2. Installs the latest Claude Code CLI on the GitHub runner.
3. Runs a tiny prompt with Haiku:

```bash
claude -p "Reply with exactly: ok" --model haiku --no-session-persistence
```

If Claude returns a normal response, the workflow succeeds. If Claude reports a usage or rate limit, the workflow also exits successfully because the request still reached Claude. If authentication fails, the workflow fails and tells you to refresh the token.

## Default schedule

The workflow currently runs at:

```text
0 21 * * 0-4
```

GitHub Actions schedules are written in UTC. That default means:

```text
6:00 AM Asia/Seoul, Monday-Friday
```

The UTC day is the previous evening, so the cron expression uses Sunday through Thursday.

## Create the Claude token

On your Mac, use a terminal where Claude Code is already installed:

```bash
claude setup-token
```

Claude will open an OAuth flow in the browser. When it finishes, it prints a token. Copy the full token. It usually starts with:

```text
sk-ant-oat01-
```

Keep this token private. Anyone with it may be able to use your Claude Code subscription.

## Add the token to GitHub

From this repository, you can add the secret with GitHub CLI:

```bash
gh secret set CLAUDE_OAUTH_TOKEN
```

Paste the token when prompted.

You can also add it in the GitHub web UI:

1. Open the repository on GitHub.
2. Go to `Settings`.
3. Go to `Secrets and variables`.
4. Choose `Actions`.
5. Click `New repository secret`.
6. Use this exact name:

```text
CLAUDE_OAUTH_TOKEN
```

7. Paste the token as the value.
8. Save the secret.

## Push and enable the workflow

Commit and push this repository to GitHub:

```bash
git add README.md .github/workflows/claude-warmup.yml
git commit -m "Add Claude warmup workflow"
git push
```

Then turn on GitHub Actions if needed:

1. Open the repository on GitHub.
2. Select the `Actions` tab.
3. If GitHub asks whether to enable workflows, enable them.
4. Open the `Claude Warmup` workflow.

GitHub scheduled workflows only run from the default branch, so make sure this file is pushed to the branch GitHub treats as default.

## Run a manual test

After the secret is set, trigger the workflow manually:

```bash
gh workflow run claude-warmup.yml
```

Then inspect the latest run:

```bash
gh run list --workflow claude-warmup.yml
gh run view --log
```

In the logs, look for:

```text
Claude warmup finished successfully.
```

or:

```text
Claude reported a usage limit.
```

Either one means the workflow reached Claude.

## Change the time

Edit the `cron` line in `.github/workflows/claude-warmup.yml`:

```yaml
- cron: "0 21 * * 0-4"
```

The first number is the minute. The second number is the hour in UTC.

Useful examples:

| Desired local time | Cron |
| --- | --- |
| 6:00 AM Asia/Seoul, weekdays | `0 21 * * 0-4` |
| 7:00 AM Asia/Seoul, weekdays | `0 22 * * 0-4` |
| 8:00 AM Asia/Seoul, weekdays | `0 23 * * 0-4` |
| 6:00 AM US Eastern during daylight time, weekdays | `0 10 * * 1-5` |
| 6:00 AM US Pacific during daylight time, weekdays | `0 13 * * 1-5` |

Pick a time that is a few hours before you usually begin using Claude Code. For example, if you normally start at 9:00 AM and often hit limits before lunch, a 6:00 AM warmup may make the reset land closer to late morning.

## Confirm it is working

The next time the scheduled workflow runs:

1. Open Claude Code locally after the warmup time.
2. Run `/usage`.
3. Check whether the reset time lines up with the workflow run.

If the reset time is not what you expected, adjust the cron time and test again.

## Troubleshooting

### The workflow says the secret is missing

Create a repository secret named exactly:

```text
CLAUDE_OAUTH_TOKEN
```

Secret names are case-sensitive in practice when referenced from workflows, so use the exact spelling.

### The token is invalid or expired

Generate a new token:

```bash
claude setup-token
```

Then update the GitHub secret:

```bash
gh secret set CLAUDE_OAUTH_TOKEN
```

### The schedule never runs

Check these things:

- The workflow file is on the repository default branch.
- GitHub Actions are enabled for the repository.
- The repository is not archived.
- The cron time is UTC, not local time.

### Manual runs work but scheduled runs feel late

GitHub scheduled workflows are not guaranteed to start at the exact minute. They can be delayed, especially at busy times. If the exact reset minute matters, choose a schedule with some buffer.

## Security notes

The OAuth token should only live in GitHub Actions secrets or another trusted secret store. Do not commit it to the repository, paste it into issues, or print it in workflow logs.

If you stop using this repository, delete the `CLAUDE_OAUTH_TOKEN` secret from GitHub.
