FROM quay.io/fedora/fedora-bootc:44

# Utilities
RUN dnf -y install \
        pciutils \
        smartmontools \
        gvfs \
        thermald \
        fprintd \
        libfprint \
        kernel-modules-extra \
        btop \
        fastfetch \
        vim-enhanced \
        git \
        curl \
        wget \
        util-linux-core \
        util-linux \
        glibc-locale-source \
        glibc-langpack-en \
        7zip \
        zip \
        sudo

# Network, Bluetooth, Wifi
RUN dnf -y install \
        NetworkManager \
        NetworkManager-wifi

# Nix Dir, will be bind mounted to /var/nix
RUN mkdir -p /nix

# Clean UP
RUN dnf clean all -y

# Enable desktop, NW
RUN systemctl enable NetworkManager.service -f
