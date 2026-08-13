FROM --platform=linux/amd64 ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG MAKE_JOBS=1
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND} \
    MAKE_JOBS=${MAKE_JOBS} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:${PATH} \
    PYTHONUNBUFFERED=1

RUN set -eux; \
    apt-get update; \
    apt-cache policy \
      git \
      build-essential \
      autoconf \
      cmake \
      libglu1-mesa-dev \
      libgtk-3-dev \
      libdbus-1-dev \
      libhidapi-dev \
      libwebkit2gtk-4.1-dev \
      texinfo \
      openscad \
      python3 \
      python3-pip \
      pkg-config \
      ca-certificates \
      | sed -n '1,220p'; \
    apt-get install -y --no-install-recommends \
      git \
      build-essential \
      autoconf \
      automake \
      cmake \
      libtool \
      locales \
      libglu1-mesa-dev \
      libgtk-3-dev \
      libdbus-1-dev \
      libhidapi-dev \
      libwebkit2gtk-4.1-dev \
      texinfo \
      openscad \
      python3 \
      python3-pip \
      pkg-config \
      ca-certificates; \
    locale-gen C.UTF-8 || true; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --branch version_2.9.5 --depth 1 --recursive https://github.com/prusa3d/PrusaSlicer.git

WORKDIR /src/PrusaSlicer
RUN set -eux; \
    sed -i 's#https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.bz2#https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.bz2#' deps/+MPFR/MPFR.cmake; \
    sed -i 's#https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2#https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.bz2#' deps/+GMP/GMP.cmake; \
    grep -nE 'mpfr-4.2.1|gmp-6.2.1' deps/+MPFR/MPFR.cmake deps/+GMP/GMP.cmake; \
    cd deps; \
    mkdir -p build; \
    cd build; \
    cmake .. -DDEP_WX_GTK3=ON; \
    make -j"${MAKE_JOBS}"; \
    cd /src/PrusaSlicer; \
    mkdir -p build; \
    cd build; \
    cmake .. -DSLIC3R_STATIC=1 -DSLIC3R_GTK=3 -DSLIC3R_PCH=OFF -DCMAKE_PREFIX_PATH=/src/PrusaSlicer/deps/build/destdir/usr/local; \
    make -j"${MAKE_JOBS}"; \
    install -m 0755 src/prusa-slicer /usr/local/bin/prusa-slicer

RUN set -eux; \
    prusa-slicer --version; \
    openscad --version; \
    prusa-slicer --help > /tmp/prusa-help.txt; \
    grep -E -q -- '--printer-profile|--print-profile|--material-profile' /tmp/prusa-help.txt

WORKDIR /workspace
CMD ["bash"]
