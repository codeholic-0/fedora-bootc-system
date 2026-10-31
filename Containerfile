FROM quay.io/fedora/fedora-bootc:44

RUN dnf -y install \
        plasma-desktop \
        plasma-workspace \
        plasma-login-manager \
        plasma-nm \
        plasma-pa \
        NetworkManager \
        konsole \
        kscreen \
        kate \
        spectacle \
        kinfocenter \
        gthumb \
        okular \
        vlc \
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
        && dnf remove -y plasma-welcome

RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y --allowerasing ffmpeg
RUN dnf clean all -y
RUN mkdir -p /nix
RUN systemctl enable plasmalogin.service -f
RUN systemctl enable NetworkManager.service -f
