FROM nixos/nix

LABEL maintainer="crypto-lab"
LABEL description="Cryptographic automation laboratory - SRE perspective (NixOS)"

# Update channels and install required packages via nix-env
RUN nix-channel --update && \
    nix-env -iA \
        nixpkgs.gnupg \
        nixpkgs.fish \
        nixpkgs.openssl \
        nixpkgs.vim \
        nixpkgs.pinentry-curses \
        nixpkgs.cacert \
        nixpkgs.shadow

# Create non-root user for secure execution
# NixOS containers use shadow from nix-env
RUN useradd -m -s /root/.nix-profile/bin/fish -u 1001 cryptouser || \
    adduser -D -s /root/.nix-profile/bin/fish -u 1001 cryptouser

# Configure GnuPG agent for non-interactive (loopback pinentry) usage
RUN mkdir -p /home/cryptouser/.gnupg && \
    chmod 700 /home/cryptouser/.gnupg && \
    echo "allow-loopback-pinentry" > /home/cryptouser/.gnupg/gpg-agent.conf && \
    echo "default-cache-ttl 0" >> /home/cryptouser/.gnupg/gpg-agent.conf && \
    chown -R cryptouser:cryptouser /home/cryptouser/.gnupg

# Make nix-installed binaries available system-wide
ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

# Set working directory
WORKDIR /workspace

# Copy project files into the image
COPY --chown=cryptouser:cryptouser . /workspace/

# Make scripts executable
RUN chmod +x /workspace/scripts/*.fish /workspace/scripts/*.sh 2>/dev/null || true

# Switch to non-root user
USER cryptouser

# Set GPG_TTY for pinentry and SSL cert bundle path (required in NixOS)
ENV GPG_TTY=/dev/null
ENV GNUPGHOME=/home/cryptouser/.gnupg
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

CMD ["fish"]