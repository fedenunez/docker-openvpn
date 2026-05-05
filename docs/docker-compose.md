# Quick Start with Docker Compose

Use this repository as a folder in the project that owns your Compose stack:

```text
vpn-stack/
  compose.yml
  docker-openvpn/
```

Add the OpenVPN service in `compose.yml`. If the repository folder has a
different name, update `build.context` to match.

```yaml
services:
  openvpn:
    build:
      context: ./docker-openvpn
    image: fedenunez/openvpn:local
    cap_add:
     - NET_ADMIN
    container_name: openvpn
    ports:
     - "1194:1194/udp"
    restart: unless-stopped
    volumes:
     - ./openvpn-data/conf:/etc/openvpn
```


* Build the local image

```bash
docker compose build openvpn
```

* Initialize the configuration files and certificates

```bash
docker compose run --rm openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
docker compose run --rm openvpn ovpn_initpki
```

* Fix ownership (depending on how to handle your backups, this may not be needed)

```bash
sudo chown -R $(whoami): ./openvpn-data
```

* Start OpenVPN server process

```bash
docker compose up -d openvpn
```

* You can access the container logs with

```bash
docker compose logs -f
```

* Generate a client certificate

```bash
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

* Retrieve the client configuration with embedded certificates

```bash
docker compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

* Revoke a client certificate

```bash
# Keep the corresponding crt, key and req files.
docker compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```bash
docker compose run -e DEBUG=1 -p 1194:1194/udp openvpn
```
