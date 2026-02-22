FROM debian:stable-slim

LABEL maintainer="crypto-lab"
LABEL description="Cryptographic automation laboratory - SRE perspective"

# Install required packages in a single layer to minimize image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg \
    fish \
    openssl \
    vim \
    pinentry-curses \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for secure execution
RUN useradd -m -s /usr/bin/fish -u 1001 cryptouser

# Configure GnuPG agent for non-interactive (loopback pinentry) usage
RUN mkdir -p /home/cryptouser/.gnupg && \
    chmod 700 /home/cryptouser/.gnupg && \
    echo "allow-loopback-pinentry" > /home/cryptouser/.gnupg/gpg-agent.conf && \
    echo "default-cache-ttl 0" >> /home/cryptouser/.gnupg/gpg-agent.conf && \
    chown -R cryptouser:cryptouser /home/cryptouser/.gnupg

# Set working directory
WORKDIR /workspace

# Copy project files into the image
COPY --chown=cryptouser:cryptouser . /workspace/

# Make scripts executable
RUN chmod +x /workspace/scripts/*.fish /workspace/scripts/*.sh 2>/dev/null || true

# Switch to non-root user
USER cryptouser

# Set GPG_TTY for pinentry
ENV GPG_TTY=/dev/null
ENV GNUPGHOME=/home/cryptouser/.gnupg

CMD ["fish"]