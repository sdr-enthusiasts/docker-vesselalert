FROM debian:bullseye-slim AS build

RUN set -x && \
    apt-get update -y && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y \
        git gcc && \
    cd / && \
    git clone --depth=1 --single-branch https://github.com/sdr-enthusiasts/docker-vesselalert.git && \
    cd /docker-vesselalert/src && \
    gcc -static distance.c -o distance -lm -Ofast

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ENV MASTODON_NOTIFY_EVERY=86400
ENV MASTODON_MIN_DIST=0
ENV PATH="$PATH:/usr/share/vesselalert:/tools"
LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-vesselalert"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
#
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(bc) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(curl) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # Do some other stuff
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    #
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
        apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -y && \
    #
    # set CONTAINER_VERSION:
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

COPY --from=build /docker-vesselalert/src/distance /usr/share/vesselalert/distance

# Add Container Version
RUN set -x && \
pushd /tmp && \
    git clone --depth=1 https://github.com/sdr-enthusiasts/docker-vesselalert.git && \
    cd docker-vesselalert && \
    branch="##BRANCH##" && \
    [[ ! "${branch:0:1}" == "#" ]] && git checkout "$branch" || true && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION && \
popd && \
rm -rf /tmp/*


# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh
