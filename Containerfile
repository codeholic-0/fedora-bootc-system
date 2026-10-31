FROM quay.io/fedora/fedora-bootc:44

RUN dnf -y install \
        # Plasma Desktop
        plasma-desktop \
        plasma-workspace \
        plasma-login-manager \
        plasma-nm \
        plasma-pa \
        konsole \
        kscreen \
        kate \
        spectacle \
        kinfocenter \
        okular \
        # Network, Bluetooth, Wifi
        NetworkManager \
        NetworkManager-wifi \
        NetworkManager-bluetooth \
        wireless-regdb \
        bluez-obexd \
        # Sound
        alsa-utils \
        alsa-ucm \
        alsa-sof-firmware \
        pipewire-utils \
        # Media
        gthumb \
        vlc \
        # Utilities
        dnf5-plugins \
        intel-gmmlib \
        bolt \
        libva-intel-media-driver \
        pciutils \
        smartmontools \
        thermald \
        fprintd \
        libfprint \
        kernel-modules-extra \
        btop \
        fastfetch \
        vim-enhanced \
        git \
        curl \
        util-linux-core \
        util-linux \
        glibc-locale-source \
        glibc-langpack-en \
        sudo \
        # Garbage removal
        && dnf remove -y plasma-welcome
# Media Codecs
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y --allowerasing ffmpeg
# Helium Browser
RUN dnf copr enable -y imput/helium && dnf install -y helium-bin
# Clean UP
RUN dnf clean all -y
# Nix Dir, will be bind mounted to /var/nix
RUN mkdir -p /nix
# Enable desktop, NW
RUN systemctl enable plasmalogin.service -f
RUN systemctl enable NetworkManager.service -f
