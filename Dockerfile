FROM archlinux as build_env

RUN pacman --disable-download-timeout --noconfirm -Syyu
RUN pacman --disable-download-timeout --noconfirm --needed -S base-devel \
    fish llvm cmake lld git make gcc fmt nlohmann-json pugixml clang python sudo python-intelhex cli11 boost

ARG PACKMANEXTRAPACKAGES=""
RUN pacman --disable-download-timeout --noconfirm --needed -S base-devel $(echo "$PACKMANEXTRAPACKAGES")

RUN useradd trizenuser --create-home
RUN echo "trizenuser ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "/etc/sudoers.d/allow_nobody_to_pacman"
RUN su trizenuser -c "/bin/sh -c 'cd ~ && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si'"
# Import the PGP key that signs libudev0-shim (dep of jlink-software-and-documentation)
# so its AUR build passes makepkg's signature verification.
RUN su trizenuser -c "gpg --keyserver keyserver.ubuntu.com --recv-keys 8703B6700E7EE06D7A39B8D6EDAE37B02CEB490D"
RUN su trizenuser -c "/bin/sh -c 'trizen -S --noinfo --noconfirm inja jlink-software-and-documentation'"

ARG TRIZENEXTRAPACKAGES=""
RUN su trizenuser -c "/bin/sh -c 'trizen -S --noinfo --noconfirm $TRIZENEXTRAPACKAGES'"

RUN git config --global --add safe.directory /project

RUN mkdir /project
WORKDIR /project

FROM build_env as build
ENTRYPOINT /project/kvasir/docker_build.sh
