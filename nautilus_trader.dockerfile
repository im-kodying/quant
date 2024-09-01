FROM ubuntu:20.04 AS base
RUN yum install -y python3 python3-pip
RUN pip3 install --upgrade pip

FROM python:3.12-slim as python-base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    RUST_TOOLCHAIN="stable" \
    BUILD_MODE="release"
ENV PATH="/root/.cargo/bin:$POETRY_HOME/bin:$PATH"
WORKDIR /nautilus_trader

FROM python-base as builder

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
COPY nautilus_trader/nautilus_core /opt/pysetup/nautilus_core
RUN (cd /opt/pysetup/nautilus_core && cargo build --release --all-features)

COPY nautilus_trader /opt/pysetup/nautilus_trader
COPY README.md /opt/pysetup/
RUN poetry install --only main --all-extras
RUN poetry build -f wheel
RUN python -m pip install /opt/pysetup/dist/*whl --force --no-deps
RUN find /usr/local/lib/python3.12/site-packages -name "*.pyc" -exec rm -f {} \;

# Final application image
FROM python-base as application

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
