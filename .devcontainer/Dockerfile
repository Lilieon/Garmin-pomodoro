# Connect IQ devcontainer — pattern borrowed from Tellion/Gaiapp
# Debian base required: the SDK Manager GUI needs glibc webkit2gtk-4.0 (no musl port).
FROM node:26.7

ENV TZ=Europe/Paris

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y git curl wget unzip jq nano sudo default-jre fontconfig \
     libgtk-3-0 iputils-ping libsecret-1-0 libgles2 \
     libwoff1 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 libgstreamer-gl1.0-0 \
     libenchant-2-2 libhyphen0 libmanette-0.2-0 libaom3 libyuv0 \
  && rm -rf /var/lib/apt/lists/*

# webkit2gtk-4.0 stack for the Garmin SDK Manager (GUI, needs Garmin login for device packs).
# Trixie only ships 4.1, so the 4.0 libs are side-loaded from bookworm into /opt/bw.
RUN mkdir -p /opt/bw \
  && cd /opt/bw \
  && for u in \
     "http://deb.debian.org/debian/pool/main/w/webkit2gtk/libwebkit2gtk-4.0-37_2.50.6-1~deb12u2_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/w/webkit2gtk/libjavascriptcoregtk-4.0-18_2.50.6-1~deb12u2_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/libs/libsoup2.4/libsoup-2.4-1_2.74.3-10.1_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3+deb12u1_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/liba/libavif/libavif15_0.11.1-1+deb12u1_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/f/flite/libflite1_2.2-7+b2_amd64.deb" \
     "http://archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_2.1.5-4ubuntu4_amd64.deb" \
     "http://deb.debian.org/debian/pool/main/d/dav1d/libdav1d6_1.0.0-2+deb12u1_amd64.deb" ; do \
       curl -fsSL -o "$(basename "$u")" "$u" && dpkg -x "$(basename "$u")" /opt/bw ; \
     done \
  && echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list.d/bookworm.list \
  && printf 'Package: *\nPin: release n=bookworm\nPin-Priority: 100\n' > /etc/apt/preferences.d/bookworm-pin \
  && apt-get update \
  && apt-get install -y -t bookworm libgav1-1 librav1e0 libsvtav1enc1 \
  && rm -rf /var/lib/apt/lists/* /opt/bw/*.deb \
  && ln -sfn /opt/bw/usr/lib/x86_64-linux-gnu/webkit2gtk-4.0 /usr/lib/x86_64-linux-gnu/webkit2gtk-4.0

# SDK Manager itself (GUI; run `sdkmanager` with DISPLAY set — needs one-time Garmin login
# to download device packs like fr955, which no longer ship inside SDK zips)
RUN mkdir -p /opt/sdk-manager \
  && curl -fsSL -o /tmp/mgr.zip "https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-linux.zip" \
  && unzip -qo /tmp/mgr.zip -d /opt/sdk-manager \
  && rm /tmp/mgr.zip \
  && printf '#!/bin/bash\nexec env LD_LIBRARY_PATH=/opt/bw/usr/lib/x86_64-linux-gnu:/opt/bw/usr/lib /opt/sdk-manager/bin/sdkmanager "$@"\n' > /usr/local/bin/sdkmanager \
  && chmod +x /usr/local/bin/sdkmanager

# Connect IQ SDK — newest version from Garmin's index (list is ascending, so sort + take last)
RUN CIQ_URL="https://developer.garmin.com/downloads/connect-iq/sdks/$(curl -sL https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json | jq -r 'sort_by(.version | split(".") | map(tonumber)) | last | .linux')" \
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
