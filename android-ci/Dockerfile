# Based on the excellent mingchen/docker-android-build-box:
# https://github.com/mingchen/docker-android-build-box/blob/master/Dockerfile

FROM ubuntu:impish

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install Java JDK
ENV JAVA_HOME="/usr/lib/jvm/java-18-openjdk-amd64"
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        git wget unzip \
        openjdk-18-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install Android SDK manager
ENV ANDROID_HOME="/opt/android-sdk"
ARG ANDROID_SDK_TOOLS_VERSION=8512546
RUN wget --quiet --output-document=sdk-tools.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip \
    && mkdir --parents "$ANDROID_HOME" \
    && unzip -q sdk-tools.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
    && rm sdk-tools.zip
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Accept SDK licenses and install android platform binaries and build tools.
ARG ANDROID_PLATFORM_VERSION="android-32"
ARG ANDROID_BUILD_TOOLS_VERSION="31.0.0"
RUN mkdir --parents "$ANDROID_HOME/.android" \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "platforms;${ANDROID_PLATFORM_VERSION}" \
    && sdkmanager platform-tools \
    && sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# Install and create an virtual android smartphone.
ENV PATH="$ANDROID_HOME/emulator:$PATH"
RUN emulator-check \
    && sdkmanager "system-images;${ANDROID_BUILD_TOOLS_VERSION};google_apis;x86_64" \
    && echo "no" | avdmanager create avd --force --name ciAVD \
        --abi google_apis/x86_64 \
        --package "system-images;${ANDROID_BUILD_TOOLS_VERSION};google_apis;x86_64"
