FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND} \
    PATH=/usr/local/bin:${PATH} \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    ninja-build \
    openscad \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    libarchive-dev \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libdouble-conversion-dev \
    libeigen3-dev \
    libfreetype6-dev \
    libglew-dev \
    libgl1-mesa-dev \
    libgmp-dev \
    libgtkmm-3.0-dev \
    liblzma-dev \
    libmpfr-dev \
    libssl-dev \
    libtbb-dev \
    libudev-dev \
    libwxgtk3.4-gtk3-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --branch version_2.9.5 --depth 1 --recursive https://github.com/prusa3d/PrusaSlicer.git

WORKDIR /src/PrusaSlicer
RUN mkdir -p build && cd build && cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build . --parallel "$(nproc)"
RUN cd /src/PrusaSlicer/build && cmake --install . --prefix /usr/local

RUN prusa-slicer --version && openscad --version && \
    prusa-slicer --help > /tmp/prusa-help.txt && \
    grep -E -q -- '--printer-profile|--print-profile|--material-profile' /tmp/prusa-help.txt

WORKDIR /workspace
CMD ["bash"]
