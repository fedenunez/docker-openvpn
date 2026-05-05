# OpenVPN for Docker

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

**Why this image?** It's built on the latest Alpine base and updates all
system packages at build time. Every `docker compose build --pull` gives you
the freshest OpenVPN, OpenSSL, and kernel-adjacent libraries without waiting
for a maintainer to cut a release. In a world where CVEs drop on a Friday
night, you control the update cadence — rebuild often, stay ahead of the patch
curve, and keep your VPN stack as hardened as the upstreams allow.

## Quick Start

Choose one of the two methods below to include this repository in your project.

### Option 1: Git Submodule

```bash
cd my-vpn-stack
git submodule add https://github.com/fedenunez/docker-openvpn.git
```

To pull the latest version later:

```bash
git submodule update --remote docker-openvpn
```

### Option 2: Manual Clone

```bash
cd my-vpn-stack
git clone https://github.com/fedenunez/docker-openvpn.git
```

To update later, run `git pull` inside the cloned folder.

---

In either case, your project structure should look like:

    my-vpn-stack/
      compose.yml
      docker-openvpn/

Create `compose.yml`:

```yaml
services:
  openvpn:
    build: ./docker-openvpn
    image: fedenunez/openvpn:local
    container_name: openvpn
    cap_add:
      - NET_ADMIN
    ports:
      - "1194:1194/udp"
    restart: unless-stopped
    volumes:
      - ./openvpn-data/conf:/etc/openvpn
```

### Full Workflow

```bash
# Build the image
docker compose build --pull openvpn

# Initialize configuration (replace with your server's domain or IP)
docker compose run --rm openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM

# Initialize PKI (follow the interactive prompts)
docker compose run --rm -it openvpn ovpn_initpki

# Start the server
docker compose up -d openvpn

# Generate a client certificate (without passphrase)
docker compose run --rm -it openvpn easyrsa build-client-full CLIENTNAME nopass

# Retrieve the client .ovpn profile
docker compose run --rm openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn
```

To rebuild after pulling updates (submodule or clone):

```bash
git submodule update --remote docker-openvpn   # if using submodule
docker compose build --no-cache --pull openvpn
docker compose up -d openvpn
```

### Client Management

```bash
# List all issued certificates with validity status
docker compose run --rm openvpn ovpn_listclients

# Show currently connected clients (live log)
docker compose run --rm openvpn ovpn_status

# Generate profile for a single client
docker compose run --rm openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

# Generate profiles for ALL clients at once
docker compose run --rm openvpn ovpn_getclient_all

# Revoke a client certificate
docker compose run --rm openvpn ovpn_revokeclient CLIENTNAME

# Set up OTP/2FA for a client (requires -2 flag at genconfig)
docker compose run --rm -it openvpn ovpn_otp_user CLIENTNAME
```

## Next Steps

### More Reading

Miscellaneous write-ups for advanced configurations are available in the
[docs](docs) folder.

### Systemd Init Scripts

A `systemd` init script is available to manage the OpenVPN container.  It will
start the container on system boot and restart the container if it exits
unexpectedly.

Please refer to the [systemd documentation](docs/systemd.md) to learn more.

### Docker Compose

If you prefer to use Docker Compose, please refer to the [documentation](docs/docker-compose.md).

### Building Images

Build the image for the current host architecture:

    docker build -t fedenunez/openvpn:local .

Build the release image for both `linux/amd64` and `linux/arm64` with Docker
Buildx. This requires the Docker Buildx plugin to be installed:

    docker buildx bake

Override the image name or Alpine release branch when needed:

    IMAGE_NAME=fedenunez/openvpn ALPINE_VERSION=3.23 docker buildx bake

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker run -v $OVPN_DATA:/etc/openvpn -p 1194:1194/udp --cap-add=NET_ADMIN -e DEBUG=1 fedenunez/openvpn

* Test using a client that has openvpn installed correctly

        $ openvpn --config CLIENTNAME.ovpn

* Run through a barrage of debugging checks on the client if things don't just work

        $ ping 8.8.8.8    # checks connectivity without touching name resolution
        $ dig google.com  # won't use the search directives in resolv.conf
        $ nslookup google.com # will use search

* Consider setting up a [systemd service](/docs/systemd.md) for automatic
  start-up at boot time and restart in the event the OpenVPN daemon or Docker
  crashes.

## How Does It Work?

Initialize the volume container using the `fedenunez/openvpn` image with the
included scripts to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `-v` argument, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `fedenunez/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, `fedenunez/openvpn` comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.

To enable Two Factor Authentication for clients (a.k.a. OTP) see [this document](/docs/otp.md).

## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The UDP server uses`192.168.255.0/24` for dynamic clients by default.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).


## Security Discussion

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image and the script [`ovpn_copy_server_files`](/docs/paranoid.md) to accomplish this).
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to be signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Benefits of Running Inside a Docker Container

### The Entire Daemon and Dependencies are in the Docker Image

This means that it will function correctly (after Docker itself is setup) on
all distributions Linux distributions such as: Ubuntu, Arch, Debian, Fedora,
etc.  Furthermore, an old stable server can run a bleeding edge OpenVPN server
without having to install/muck with library dependencies (i.e. run latest
OpenVPN with latest OpenSSL on Ubuntu 12.04 LTS).

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two images: the ephemeral
run time image (fedenunez/openvpn) and the `$OVPN_DATA` data volume. To remove
it, remove the corresponding containers, `$OVPN_DATA` data volume and Docker
image and it's completely removed.  This also makes it easier to run multiple
servers since each lives in the bubble of the container (of course multiple IPs
or separate ports are needed to communicate with the world).

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

---

Based on [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn), originally derived from [jpetazzo/dockvpn](https://github.com/jpetazzo/dockvpn).

## License
