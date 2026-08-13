FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:${PATH} \
    PYTHONUNBUFFERED=1 \
    LD_LIBRARY_PATH=/opt/bambu/squashfs-root/bin:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
    XDG_RUNTIME_DIR=/tmp/xdg-runtime

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      python3 \
      python3-pip \
      openscad \
      xvfb \
      qemu-user-static \
      libx11-6 \
      libxext6 \
      libxrender1 \
      libxi6 \
      libxfixes3 \
      libxrandr2 \
      libxkbcommon0 \
      libxkbcommon-x11-0 \
      libgtk-3-0t64 \
      libnotify4 \
      libnss3 \
      libasound2t64 \
      libglib2.0-0t64 \
      libdbus-1-3 \
      libfontconfig1 \
      libfreetype6 \
      libwebkit2gtk-4.1-0 \
      libgstreamer1.0-0 \
      libgstreamer-plugins-base1.0-0 \
      libgl1 \
      libglu1-mesa \
      libfuse2 \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/bambu
RUN set -eux; \
    curl -fsSL -o BambuStudio.AppImage https://github.com/bambulab/BambuStudio/releases/download/v02.08.01.55/BambuStudio_ubuntu24.04-v02.08.01.55-20260715113557.AppImage; \
    chmod +x BambuStudio.AppImage; \
    qemu-x86_64-static ./BambuStudio.AppImage --appimage-extract >/dev/null 2>&1 || true; \
    ln -sf /opt/bambu/squashfs-root/AppRun /usr/local/bin/bambu-studio

RUN set -eux; \
    mkdir -p "$XDG_RUNTIME_DIR"; \
    chmod 700 "$XDG_RUNTIME_DIR"; \
    openscad --version; \
    export LD_LIBRARY_PATH="/opt/bambu/squashfs-root/bin:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"; \
    xvfb-run -a /opt/bambu/squashfs-root/AppRun --help >/tmp/bambu-help.txt 2>&1 || true; \
    grep -E -q -- '--slice|--outputdir' /tmp/bambu-help.txt

WORKDIR /workspace
CMD ["bash"]
