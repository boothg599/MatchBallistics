FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install Flutter dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ARG FLUTTER_VERSION=3.24.5
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} /opt/flutter \
    && /opt/flutter/bin/flutter precache \
    && /opt/flutter/bin/flutter config --no-analytics

# Add Flutter to PATH
ENV PATH="/opt/flutter/bin:${PATH}"

# Set up Flutter for the vscode user
RUN chown -R vscode:vscode /opt/flutter
