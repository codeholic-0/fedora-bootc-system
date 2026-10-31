FROM quay.io/fedora/fedora-bootc:44

# Plasma Desktop
RUN dnf -y install \
        plasma-desktop \
        plasma-workspace \
        plasma-login-manager \
        plasma-nm \
        plasma-pa \
        konsole \
        kscreen \
        kwrite \
        dolphin \
        spectacle \
        kinfocenter \
        okular \
        kde-gtk-config \
        filelight \
        kcalc \
        kdeconnectd \
        keepassxc

# Network, Bluetooth, Wifi
RUN dnf -y install \
        NetworkManager \
        NetworkManager-wifi \
        NetworkManager-bluetooth \
        wireless-regdb \
        bluez-obexd

# Firewall
RUN dnf -y install \
        firewalld \
        firewall-config \
        sealert \
        setroubleshoot

# Sound
RUN dnf -y install \
        alsa-utils \
        alsa-ucm \
        alsa-sof-firmware \
        pipewire-utils

# Utilities
RUN dnf -y install \
        dnf5-plugins \
        intel-gmmlib \
        bolt \
        libva-intel-media-driver \
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
        persepolis \
        util-linux-core \
        util-linux \
        glibc-locale-source \
        glibc-langpack-en \
        sudo \
# Garbage removal
RUN dnf remove -y plasma-welcome

# Media, Codecs
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y --allowerasing ffmpeg vlc gthumb

# Helium Browser
RUN dnf copr enable -y imput/helium && dnf install -y helium-bin

# Clean UP
RUN dnf clean all -y

# Nix Dir, will be bind mounted to /var/nix
RUN mkdir -p /nix

# Enable desktop, NW
RUN systemctl enable plasmalogin.service -f
RUN systemctl enable NetworkManager.service -f
RUN systemctl enable firewalld.service -f
