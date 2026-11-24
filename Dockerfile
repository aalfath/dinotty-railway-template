# Dinotty on Railway: multi-device terminal server for AI coding agents.
# Upstream publishes no container image, so we install the official
# dinotty-server release package (pinned by version and sha256) on a pinned
# Node base, so npm-based coding agents (Claude Code, Codex, opencode) install
# with one command.
FROM node:24.22.3-bookworm-slim@sha256:32e57b5784e8875d2cc0112dcaf13f9100f2d0d9446187808738e99aee29a5a2

ARG DINOTTY_VERSION=0.31.1
ARG DINOTTY_DEB_SHA256=7342f2d2d5c4fadd9312012c244dafd67404075f862b96d9238a8c3be2553d76

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client tini sudo procps less nano \
      ripgrep jq python3 unzip xz-utils locales; \
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen; locale-gen; \
    curl -fsSL -o /tmp/dinotty.deb \
      "https://github.com/xichan96/dinotty/releases/download/v${DINOTTY_VERSION}/dinotty-server_${DINOTTY_VERSION}-1_amd64.deb"; \
    echo "${DINOTTY_DEB_SHA256}  /tmp/dinotty.deb" | sha256sum -c -; \
    mkdir /tmp/deb; dpkg-deb -x /tmp/dinotty.deb /tmp/deb; \
    install -m 0755 /tmp/deb/usr/bin/dinotty-server /usr/local/bin/dinotty-server; \
    rm -r /tmp/deb /tmp/dinotty.deb /var/lib/apt/lists/*; \
    useradd -m -u 1001 -s /bin/bash dinotty; \
    echo 'dinotty ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dinotty; chmod 0440 /etc/sudoers.d/dinotty

COPY profile.sh /etc/profile.d/zz-dinotty.sh
COPY start.sh /usr/local/bin/start.sh
RUN chmod 0644 /etc/profile.d/zz-dinotty.sh && chmod 0755 /usr/local/bin/start.sh

ENV HOME=/home/dinotty \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    NPM_CONFIG_PREFIX=/home/dinotty/.npm-global \
    PATH=/home/dinotty/.local/bin:/home/dinotty/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DINOTTY_VERSION=0.31.1 \
    PORT=8999 \
    RUST_LOG=info

WORKDIR /home/dinotty
EXPOSE 8999

# tini reaps the shells' orphaned children and passes signals to the group.
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/start.sh"]
