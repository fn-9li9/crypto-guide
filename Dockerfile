FROM nixos/nix

LABEL maintainer="crypto-lab"
LABEL description="Cryptographic automation laboratory - SRE"

RUN nix-channel --update && \
    nix-env -iA \
        nixpkgs.gnupg \
        nixpkgs.fish \
        nixpkgs.openssl \
        nixpkgs.python3

RUN nix-env -iA \
    nixpkgs.pinentry-curses \
    nixpkgs.cacert \
    nixpkgs.expect \
    nixpkgs.gawk \
    nixpkgs.gnused

ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

RUN mkdir -p /root/.gnupg && \
    chmod 700 /root/.gnupg && \
    echo "allow-loopback-pinentry" > /root/.gnupg/gpg-agent.conf && \
    echo "default-cache-ttl 0" >> /root/.gnupg/gpg-agent.conf

WORKDIR /workspace

COPY . /workspace/

RUN chmod +x /workspace/scripts/*.fish /workspace/scripts/*.sh 2>/dev/null || true

ENV GNUPGHOME=/root/.gnupg
ENV GPG_TTY=/dev/null
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt

CMD ["fish"]