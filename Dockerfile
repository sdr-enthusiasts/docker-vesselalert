# hadolint global ignore=DL3003,DL3008,DL3015,SC2034,SC2068
FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS build

ARG repo="sdr-enthusiasts/docker-vesselfeeder"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    --mount=type=bind,source=./,target=/ghrepo/  \
    apt-get update -y && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y\
        gcc && \
    mkdir -p /src && \
    cd /src && \
    cp -f /ghrepo/src/distance.c . && \
    gcc -static distance.c -o distance -lm -Ofast && \
    # Add Container Version:
    cd / && \
    branch="##BRANCH##" && \
    # Add Container Version
    if [[ "${branch:0:1}" == "#" ]]; then branch="main"; fi && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(curl -ssL "https://api.github.com/repos/$repo/commits/$branch" | awk '{if ($1=="\"sha\":") {print substr($2,2,7); exit}}')_$VERSION_BRANCH" > /.CONTAINER_VERSION

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ENV NOTIFY_EVERY=86400
ENV PATH="$PATH:/usr/share/vesselalert:/tools"
LABEL org.opencontainers.image.source="https://github.com/sdr-enthusiasts/docker-vesselalert"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
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
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-paho-mqtt) && \
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
    # Clean up
    echo Uninstalling $TEMP_PACKAGES && \
    apt-get remove -y -q ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
    apt-get clean -y -q && \
    rm -rf \
    /src/* \
    /var/cache/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /.dockerenv \
    /git

COPY rootfs/ /

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh
