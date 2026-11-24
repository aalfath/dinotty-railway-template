# Changelog

Breaking changes are listed first in each entry.

## 0.31.1 (2026-11-24)

- First version of the Railway template: Dinotty server 0.31.1 (release package, sha256 `7342f2d2…53d76`) on `node:24.22.3-bookworm-slim@sha256:32e57b57…a5a2`.
- Login token from `DINOTTY_TOKEN` (generated on deploy); the container refuses to start without it.
- Volume at `/home/dinotty`; npm global installs go to `~/.npm-global` so agent CLIs survive redeploys.
- Tokio worker threads capped to the service's CPUs; the container exits non-zero when the server stops so Railway restarts it.
