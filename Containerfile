ARG FEDORA_VERSION=41

FROM fedora:${FEDORA_VERSION}

# noarch
RUN dnf5 install -y \
    meson \
    python3-mako \
    python3-ply \
    python3-pycparser \
    rust-paste-devel \
    rust-proc-macro2-devel \
    rust-quote-devel \
    cargo-rpm-macros \
    rust-syn+clone-impls-devel \
    rust-unicode-ident-devel \
    vulkan-headers \
    wayland-protocols-devel \
    xorg-x11-proto-devel \
    && dnf5 clean all

# x86_64
RUN dnf5 install -y \
    bindgen-cli \
    bison \
    cbindgen \
    clang-devel \
    elfutils-libelf-devel \
    expat-devel \
    flex \
    gcc \
    gettext \
    glslang \
    kernel-headers \
    libX11-devel \
    libXdamage-devel \
    libXext-devel \
    libXfixes-devel \
    libXrandr-devel \
    libXxf86vm-devel \
    libclc-devel \
    libdrm-devel \
    libglvnd-core-devel \
    libselinux-devel \
    libunwind-devel \
    libva-devel \
    libvdpau-devel \
    libxcb-devel \
    libxshmfence-devel \
    libzstd-devel \
    python3-devel \
    lm_sensors-devel \
    python3-pyyaml \
    valgrind-devel \
    spirv-llvm-translator-devel \
    spirv-tools-devel \
    vulkan-loader-devel \
    wayland-devel \
    zlib-ng-compat-devel

# x86
RUN dnf5 install -y \
    clang-devel.i686 \
    elfutils-libelf-devel.i686 \
    expat-devel.i686 \
    glslang.i686 \
    kernel-headers.i686 \
    libX11-devel.i686 \
    libXdamage-devel.i686 \
    libXext-devel.i686 \
    libXfixes-devel.i686 \
    libXrandr-devel.i686 \
    libXxf86vm-devel.i686 \
    libclc-devel.i686 \
    libdrm-devel.i686 \
    libglvnd-core-devel.i686 \
    libselinux-devel.i686 \
    libunwind-devel.i686 \
    libva-devel.i686 \
    libvdpau-devel.i686 \
    libxcb-devel.i686 \
    libxshmfence-devel.i686 \
    libzstd-devel.i686 \
    python3-devel.i686 \
    lm_sensors-devel.i686 \
    valgrind-devel.i686 \
    spirv-llvm-translator-devel.i686 \
    spirv-tools-devel.i686 \
    vulkan-loader-devel.i686 \
    wayland-devel.i686 \
    zlib-ng-compat-devel.i686 \
    pkgconf-pkg-config.i686

# these do not have an i686 version
# bindgen-cli.i686 \
# bison.i686 \
# cbindgen.i686 \
# flex.i686 \
# gcc.i686 \
# gettext.i686 \
# python3-pyyaml.i686 \

RUN dnf install -y ccache

ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID -o builder && \
    useradd -m -u $UID -g $GID -o -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

USER builder

ENV PATH="/usr/lib64/ccache/:$PATH"

WORKDIR /workspace