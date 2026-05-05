# syntax=docker/dockerfile:1

# Original credit: https://github.com/jpetazzo/dockvpn
ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Kyle Manna <kyle@kylemanna.com>" \
      org.opencontainers.image.title="docker-openvpn" \
      org.opencontainers.image.description="OpenVPN server with EasyRSA PKI tooling" \
      org.opencontainers.image.source="https://github.com/kylemanna/docker-openvpn"

RUN apk add --no-cache \
        bash \
        easy-rsa \
        google-authenticator \
        iptables \
        libqrencode \
        openvpn \
        openvpn-auth-pam && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin/easyrsa

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

COPY ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
COPY ./otp/openvpn /etc/pam.d/
