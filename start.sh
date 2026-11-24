#!/bin/bash
# Start Dinotty on Railway.
# - refuses to start without an access token (otherwise Dinotty opens a
#   first-time setup page that lets the first visitor pick the token);
# - keeps everything under /home/dinotty, which is the Railway volume;
# - caps threads to the service's CPUs (Railway shows the host's 32+ CPUs);
# - exits non-zero whenever the server stops, so Railway restarts it.
set -euo pipefail

HOME_DIR=/home/dinotty
CFG_DIR="$HOME_DIR/.config/dinotty"

TOKEN="${DINOTTY_TOKEN:-}"
TOKEN="$(printf '%s' "$TOKEN" | tr -d '[:space:]')"
if [ "${#TOKEN}" -lt 16 ]; then
  echo "start.sh: DINOTTY_TOKEN is missing or shorter than 16 characters; refusing to start an open terminal." >&2
  exit 1
fi

# Railway mounts the volume owned by root: hand it to the dinotty user once.
mkdir -p "$HOME_DIR"
if [ "$(stat -c %u "$HOME_DIR")" != "1001" ] || [ ! -f "$HOME_DIR/.dinotty-volume-ready" ]; then
  [ -f "$HOME_DIR/.bashrc" ] || cp -n /etc/skel/.bashrc /etc/skel/.profile /etc/skel/.bash_logout "$HOME_DIR"/ 2>/dev/null || true
  chown -R 1001:1001 "$HOME_DIR"
  touch "$HOME_DIR/.dinotty-volume-ready"
  chown 1001:1001 "$HOME_DIR/.dinotty-volume-ready"
fi
install -d -o 1001 -g 1001 -m 0700 "$HOME_DIR/.config" "$CFG_DIR"
install -d -o 1001 -g 1001 "$HOME_DIR/workspace" "$HOME_DIR/.npm-global" "$HOME_DIR/.local/bin"

# The Railway variable is the source of truth for the login token.
umask 077
printf '%s' "$TOKEN" > "$CFG_DIR/token"
chown 1001:1001 "$CFG_DIR/token"
chmod 0600 "$CFG_DIR/token"
umask 022

# CPU count from the cgroup (Railway exposes the host's CPUs to the process).
CPUS=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != "max" ] && [ -n "${period:-}" ]; then
    CPUS=$(( (quota + period - 1) / period ))
  else
    CPUS=$(nproc)
  fi
fi
[ "$CPUS" -lt 1 ] && CPUS=1
[ "$CPUS" -gt 4 ] && CPUS=4

PORT="${PORT:-8999}"
echo "start.sh: Dinotty ${DINOTTY_VERSION:-0.31.1} on port $PORT, ${CPUS} worker thread(s)"

# Don't hand the token or Railway's own variables to the shells it opens.
unset DINOTTY_TOKEN TOKEN
for v in $(compgen -e | grep -E '^RAILWAY_' || true); do unset "$v"; done

set +e
setpriv --reuid=1001 --regid=1001 --init-groups --inh-caps=-all \
  env -u PORT HOME="$HOME_DIR" USER=dinotty LOGNAME=dinotty \
      TOKIO_WORKER_THREADS="$CPUS" MALLOC_ARENA_MAX=2 \
  dinotty-server --port "$PORT"
rc=$?
set -e
echo "start.sh: dinotty-server stopped (exit $rc)" >&2
[ "$rc" -eq 0 ] && rc=1
exit "$rc"
