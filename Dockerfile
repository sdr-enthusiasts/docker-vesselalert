FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS build

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    --mount=type=bind,source=./,target=/ghrepo/  \
    apt-get update -y && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y \
        git gcc && \
    mkdir -p /src && \
    cd /src && \
    cp -f /ghrepo/src/distance.c . && \
    gcc -static distance.c -o distance -lm -Ofast && \
    # Add Container Version:
    cd / && \
    branch="##BRANCH##" && \
    { [[ "${branch:0:1}" == "#" ]] && branch="main" || true; } && \
    git clone --depth=1 -b $branch https://github.com/sdr-enthusiasts/docker-vesselalert.git && \
    cd docker-vesselalert && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ENV MASTODON_NOTIFY_EVERY=86400
ENV MASTODON_MIN_DIST=0
ENV PATH="$PATH:/usr/share/vesselalert:/tools"
LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-vesselalert"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008,SC2086,SC2039,SC2068
RUN \
    --mount=type=bind,from=build,source=/,target=/build \
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(bc) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(curl) && \
    KEPT_PACKAGES+=(file) && \
    KEPT_PACKAGES+=(jpegoptim) && \
    KEPT_PACKAGES+=(pngquant) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # add files from the build container:
    mkdir -p /usr/share/vesselalert && \
    cp -f /build/src/distance /usr/share/vesselalert/distance && \
    cp -f /build/.CONTAINER_VERSION /.CONTAINER_VERSION && \
    # Do some other stuff
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    #
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
        apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
    apt-get clean -q -y && \
    #
    # set CONTAINER_VERSION:
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh
