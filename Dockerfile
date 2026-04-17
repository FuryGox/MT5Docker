FROM ubuntu:jammy

ADD https://dl.winehq.org/wine-builds/winehq.key /winehq.key

# Disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Use a stable Ubuntu mirror and retry downloads to reduce hash mismatch failures.
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    /etc/apt/sources.list

# Install Wine
RUN dpkg --add-architecture i386 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update -o Acquire::Retries=5 && \
    apt-get install -y --fix-missing gnupg apt-utils ca-certificates && \
    gpg --batch --yes --dearmor --output /usr/share/keyrings/winehq-archive.key /winehq.key && \
    rm /winehq.key && \
    echo "deb [signed-by=/usr/share/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" >> /etc/apt/sources.list.d/winehq.list && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update -o Acquire::Retries=5 && \
    apt-get install -y -q --fix-missing --install-recommends winehq-devel && \
    apt-get install -y --fix-missing xvfb imagemagick && \
    rm -rf /var/lib/apt/lists/*

# Add a non-root wine user
# NOTE: Change UID/GID if the host MetaTrader directory requires different ownership.
RUN groupadd -g 1000 wine \
    && useradd -g wine -u 1000 wine \
    && mkdir -p /home/wine/.wine && chown -R wine:wine /home/wine

# This image bundles terminal64.exe, so the default Wine prefix must be 64-bit.
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine
ENV DISPLAY=:99

WORKDIR /app

COPY ./mt5_source /app/mt5
COPY ./templates /app/templates
COPY entrypoint.sh /app/entrypoint.sh

RUN chown -R wine:wine /app && chmod +x /app/entrypoint.sh

# Allow non-root user to start Xvfb
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Run MetaTrader as non privileged user.
USER wine

ENTRYPOINT ["/app/entrypoint.sh"]