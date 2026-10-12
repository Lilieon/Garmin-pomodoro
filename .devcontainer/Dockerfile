# Connect IQ devcontainer — pattern borrowed from Tellion/Gaiapp
FROM node:26.7

ENV TZ=Europe/Paris

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y git curl wget unzip jq nano sudo default-jre fontconfig libgtk-3-0 iputils-ping \
  && rm -rf /var/lib/apt/lists/*

# Connect IQ SDK (Java tarball, no package manager) — latest version from Garmin's index
# if fr955 ever drops out of the latest SDK, pin: jq '[.[]|select(.version|startswith("7."))][0]'
RUN CIQ_URL="https://developer.garmin.com/downloads/connect-iq/sdks/$(curl -sL https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json | jq -r '.[0].linux')" \
  && curl -fsSL -o /tmp/ciq-sdk.zip "$CIQ_URL" \
  && unzip -q /tmp/ciq-sdk.zip -d /tmp/ciq-extract \
  && if [ -d /tmp/ciq-extract/bin ]; then mv /tmp/ciq-extract /opt/connectiq; else mv /tmp/ciq-extract/connectiq* /opt/connectiq; fi \
  && rm -rf /tmp/ciq-sdk.zip /tmp/ciq-extract \
  && chmod +x /opt/connectiq/bin/* 2>/dev/null || true

ENV CIQ_SDK=/opt/connectiq
ENV PATH="/opt/connectiq/bin:${PATH}"

# GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out > /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @kilocode/cli

RUN git config --system user.email "lilian.lemee@pm.me" \
  && git config --system user.name "Lilieon"

RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /home/node/.vscode-server/data/Machine \
             /home/node/.vscode-server/data/User/globalStorage/kilocode.kilo-code \
             /home/node/.local/state /home/node/.local/share /home/node/.config /home/node/.connectiq \
    && chown -R node:node /home/node

CMD [ "bash" ]
