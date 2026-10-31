FROM quay.io/fedora/fedora-bootc:44

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
        plymouth\
        plymouth-theme-breeze \
        ark \
        sudo

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

# Media, Codecs
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y --allowerasing ffmpeg vlc gthumb

# Nix Dir, will be bind mounted to /var/nix
RUN mkdir -p /nix

# Plymouth Enable 
COPY plymouth.toml /usr/lib/bootc/kargs.d/50-plymouth.toml
RUN plymouth-set-default-theme breeze


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
        kfind \
        keepassxc

# Garbage removal
RUN dnf remove -y plasma-welcome

# Helium Browser
RUN dnf copr enable -y imput/helium && dnf install -y helium-bin

# Clean UP
RUN dnf clean all -y

# Enable desktop, NW
RUN systemctl enable plasmalogin.service -f
RUN systemctl enable NetworkManager.service -f
RUN systemctl enable firewalld.service -f
