[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/dinotty?utm_medium=integration&utm_source=button&utm_campaign=dinotty)

# Dinotty on Railway

One-click Railway template for [Dinotty](https://github.com/xichan96/dinotty) **0.31.1**, a multi-device terminal server for AI coding agents (Claude Code, Codex, opencode and others). Terminal sessions run on the server, survive disconnects and restore when you reopen the page on any phone, tablet or desktop browser. It also has a file browser and editor, git changes, web preview of dev servers, SSH/SFTP panes and a built-in MCP server.

## What this template deploys

| Service | Source | What it does |
|---|---|---|
| **Dinotty** | this repo (`Dockerfile`) | `dinotty-server` 0.31.1 from the official release package (sha256-pinned) on `node:24.22.3-bookworm-slim` (pinned by digest), so npm-based coding agents install with one command. Public HTTPS domain, health check on `/`. |

One volume is mounted at `/home/dinotty` (the terminal user's home): your projects (`~/workspace`), Dinotty's settings, login token, session snapshot and plugins, and any tools you install with `npm install -g` (they go to `~/.npm-global`). All of it survives restarts and redeploys.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `DINOTTY_TOKEN` | `${{secret(32)}}` | Login token for the web UI, the API and MCP. Generated on deploy; read it in the service's **Variables** tab. The container refuses to start if it's empty or shorter than 16 characters, so Dinotty's first-time setup page (where the first visitor would choose the token) never opens. Change it here and redeploy to rotate it; that also signs out every browser. |
| `PORT` | `8999` | Port Dinotty listens on; Railway's domain points at it. |

Nothing else is required. To give coding agents an API key without logging in inside the terminal, add it as a variable on the service (for example `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`): every new terminal sees the service's variables, except `DINOTTY_TOKEN` and Railway's own `RAILWAY_*` values.

## After deploying

1. Open the public URL and sign in with `DINOTTY_TOKEN`.
2. In a terminal, install the agent you use, for example `npm install -g @anthropic-ai/claude-code`, `npm install -g @openai/codex` or `npm install -g opencode-ai`, then run it inside `~/workspace` and log in as the agent asks.
3. Optional: add the Dinotty MCP server to an AI client (enable the Open API / MCP switches in Settings first):
   ```json
   { "mcpServers": { "dinotty": { "type": "http", "url": "https://YOUR-DOMAIN/mcp/message", "headers": { "Authorization": "Bearer YOUR-DINOTTY-TOKEN" } } } }
   ```

## Notes and limits

- **Security:** anyone with the token gets a shell on the service (user `dinotty`, with passwordless `sudo` inside the container). Keep the token secret. Web previews (`/preview/<port>/`), the API and MCP all need the token or a signed-in browser.
- **Persistence:** only `/home/dinotty` is kept. Packages installed with `sudo apt-get` are lost on redeploy; install tools with `npm install -g`, into `~/.local/bin`, or rebuild from a fork of this repo with them in the `Dockerfile`.
- **Memory:** Dinotty itself uses about 25 MB. Measured on Railway with a 0.5 GB limit: installing Claude Code peaked at about 270 MB, and the Claude Code TUI used about 160 MB, with no out-of-memory kill. Running several agents at once, or heavy builds, needs Hobby or higher with more RAM.
- **No Docker inside:** Railway has no privileged containers, so Docker-in-Docker and agent sandboxes that need Docker don't work. The optional Tauri desktop app isn't part of this template; it can connect to this server as a remote server.
- If the server process stops for any reason, the container exits non-zero so Railway restarts it (restart policy *On failure*).

## Updates

Railway notifies everyone who deployed this template when a change is merged to this repo's `main` branch (version bumps, fixes). Read [`CHANGELOG.md`](CHANGELOG.md) before applying: breaking changes are listed first. Your volume (projects, settings, installed tools) is kept across updates.

## Licence

Dinotty is MIT-licensed by its authors ([xichan96/dinotty](https://github.com/xichan96/dinotty)). This wrapper repo only contains the Dockerfile and start script.
