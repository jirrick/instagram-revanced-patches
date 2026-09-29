# Build/patch/decompile toolchain for the Instagram ReVanced patches.
# Runs as linux/amd64 (Rosetta on Apple Silicon): Google's Android build tools
# only ship x86_64 Linux binaries.
FROM --platform=linux/amd64 eclipse-temurin:17-jdk-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip curl jq python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Android SDK seed. On first run it's copied to the /cache volume, so SDK parts that
# Gradle downloads later (build-tools versions etc.) persist between runs.
ENV ANDROID_HOME=/opt/android-sdk
ARG CMDLINE_TOOLS=13114758
RUN mkdir -p "$ANDROID_HOME/cmdline-tools" \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS}_latest.zip" -o /tmp/cmdline.zip \
    && unzip -q /tmp/cmdline.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
    && rm /tmp/cmdline.zip
ENV PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

# Caches live on a named volume mounted at /cache (Gradle deps, jadx/CLI/APKEditor jars, adb keys).
ENV GRADLE_USER_HOME=/cache/gradle \
    TOOLS_DIR=/cache/tools \
    ANDROID_USER_HOME=/cache/android

WORKDIR /repo
ENTRYPOINT ["bash", "/repo/dev/in-container.sh"]
CMD ["shell"]
