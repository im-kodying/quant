# hadolint global ignore=DL3008
FROM ubuntu:24.04 AS setup

ENV IB_GATEWAY_VERSION=$VERSION
ENV IB_GATEWAY_RELEASE_CHANNEL=$CHANNEL
ENV IBC_VERSION=3.20.0

WORKDIR /tmp/setup

# Prepare system
RUN apt-get update -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
  curl \
  ca-certificates \
  unzip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
# Install IB Gateway
# Use this instead of "RUN curl .." to install a local file:
#COPY ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh .
  curl -sSOL https://github.com/gnzsnz/ib-gateway-docker/releases/download/ibgateway-${IB_GATEWAY_RELEASE_CHANNEL}%40${IB_GATEWAY_VERSION}/ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh && \
  curl -sSOL https://github.com/gnzsnz/ib-gateway-docker/releases/download/ibgateway-${IB_GATEWAY_RELEASE_CHANNEL}%40${IB_GATEWAY_VERSION}/ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 && \
  sha256sum --check ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh.sha256 && \
  chmod a+x ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh && \
  ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh -q -dir /root/Jts/ibgateway/${IB_GATEWAY_VERSION} &&\
  # Install IBC
  curl -sSOL https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip && \
  mkdir /root/ibc && \
  unzip ./IBCLinux-${IBC_VERSION}.zip -d /root/ibc && \
  chmod -R u+x /root/ibc/*.sh && \
  chmod -R u+x /root/ibc/scripts/*.sh

COPY ./docker-ibkr/latest/config/ibgateway/jts.ini.tmpl /root/Jts/jts.ini.tmpl
COPY ./docker-ibkr/latest/config/ibc/config.ini.tmpl /root/ibc/config.ini.tmpl

# Copy scripts
COPY ./docker-ibkr/latest/scripts /root/scripts

##############################################################################
# Build Stage: build production image
##############################################################################

FROM ubuntu:24.04 as gateway

ENV IB_GATEWAY_VERSION=$VERSION
# IB Gateway user constants
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
# IBC env vars
ENV HOME=/home/ibgateway
ENV TWS_MAJOR_VRSN=${IB_GATEWAY_VERSION}
ENV TWS_PATH=${HOME}/Jts
ENV TWS_INI=jts.ini
ENV TWS_INI_TMPL=${TWS_INI}.tmpl
ENV IBC_PATH=${HOME}/ibc
ENV IBC_INI=${HOME}/ibc/config.ini
ENV IBC_INI_TMPL=${IBC_INI}.tmpl
ENV SCRIPT_PATH=${HOME}/scripts
ENV GATEWAY_OR_TWS=gateway
# Copy files
COPY --from=setup /usr/local/i4j_jres/ /usr/local/i4j_jres
COPY --chown=${USER_ID}:${USER_GID} --from=setup /root/ ${HOME}

# Prepare system
RUN apt-get update -y && \
  apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
  gettext-base socat xvfb x11vnc sshpass openssh-client && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  if id ubuntu; then \
    userdel -rf ubuntu \
  ;fi && \
  groupadd --gid ${USER_GID} ibgateway && \
  useradd -ms /bin/bash --uid ${USER_ID} --gid ${USER_GID} ibgateway && \
  chmod a+x ${SCRIPT_PATH}/*.sh

USER ${USER_ID}:${USER_GID}
WORKDIR ${HOME}

# Start run script
RUN /home/ibgateway/scripts/run.sh

LABEL org.opencontainers.image.source=https://github.com/gnzsnz/ib-gateway-docker
LABEL org.opencontainers.image.url=https://github.com/gnzsnz/ib-gateway-docker/pkgs/container/ib-gateway
LABEL org.opencontainers.image.description="Docker image with IB Gateway and IBC "
LABEL org.opencontainers.image.licenses="Apache License Version 2.0"
LABEL org.opencontainers.image.version=${IB_GATEWAY_VERSION}-${IB_GATEWAY_RELEASE_CHANNEL}

FROM python:3.12-slim AS base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    PYO3_PYTHON="/usr/local/bin/python3" \
    POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    RUST_TOOLCHAIN="stable" \
    BUILD_MODE="release" \
    CC="clang"
ENV PATH="/root/.cargo/bin:$POETRY_HOME/bin:$PATH"
WORKDIR $PYSETUP_PATH

FROM base AS builder

# Install build deps
RUN apt-get update && \
    apt-get install -y curl clang git libssl-dev make pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install package requirements (split step and with --no-root to enable caching)
COPY nautilus_trader/poetry.lock nautilus_trader/pyproject.toml nautilus_trader/build.py ./
RUN poetry install --no-root --only main

# Build nautilus_trader
COPY nautilus_trader/nautilus_core ./nautilus_core
RUN (cd nautilus_core && cargo build --release --all-features)

COPY nautilus_trader/nautilus_trader ./nautilus_trader
COPY nautilus_trader/README.md ./
RUN poetry install --only main --all-extras
RUN poetry build -f wheel
RUN python -m pip install ./dist/*whl --force --no-deps
RUN find /usr/local/lib/python3.12/site-packages -name "*.pyc" -exec rm -f {} \;

##############################################################################
# Setup Stage: install apps
#
# This is a dedicated stage so that donwload archives don't end up on
# production image and consume unnecessary space.
##############################################################################

# Final application image
FROM base AS application

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

COPY --from=gateway . /gateway

COPY main.py .

CMD ["python", "main.py"]
