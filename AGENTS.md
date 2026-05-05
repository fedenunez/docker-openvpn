# Repository Guidelines

## Project Structure & Module Organization

This repository builds an OpenVPN server Docker image with EasyRSA PKI tooling.
Runtime helper scripts live in `bin/` and are copied into `/usr/local/bin` in
the image. PAM configuration for OTP support is in `otp/`. User and deployment
documentation belongs in `docs/`; keep `README.md` focused on the common quick
start. Init assets are in `init/`, Alpine packaging support is in `alpine/`, and
container tests are under `test/tests/<name>/`.

## Build, Test, and Development Commands

- `docker build -t fedenunez/openvpn:local .`: build the image for the local host
  architecture.
- `docker buildx bake`: build the configured multi-arch image for
  `linux/amd64` and `linux/arm64` using `docker-bake.hcl`.
- `IMAGE_NAME=example/openvpn ALPINE_VERSION=3.23 docker buildx bake`: override
  the output tag or Alpine release branch.
- `test/run.sh fedenunez/openvpn:local`: run the repository test suite against a
  previously built image.
- `test/run.sh -t basic fedenunez/openvpn:local`: run one named test group.

## Coding Style & Naming Conventions

Most code is Bash. Use `#!/bin/bash`, `set -e` where appropriate, arrays for
argument lists, and quote variable expansions unless surrounding code uses a
different established pattern. Match existing indentation in the file you edit;
many scripts use tabs in control-flow blocks. Name helper scripts with the
`ovpn_*` prefix when they are user-facing OpenVPN commands.

## Testing Guidelines

Tests are Docker-based shell scripts. Add new behavior tests under
`test/tests/<feature>/run.sh`, or `container.sh` when the existing helper
pattern fits. Register new test groups in `test/config.sh` so `test/run.sh`
picks them up. For image changes, run a local build first, then the full test
runner against that tag.

## Commit & Pull Request Guidelines

Follow the existing history: small atomic commits with subjects in the form
`<subsystem>: <subject>`, for example `dockerfile: Add multi-arch build config`
or `test: Cover OTP initialization`. Pull requests should explain behavior
changes, include the commands run, link related issues, and update `docs/` for
new user-visible features or configuration changes.

## Security & Configuration Tips

Do not commit generated client profiles, private keys, PKI material, or local
`openvpn-data/` volumes. Keep Docker capability requirements explicit in docs;
the runtime normally needs `--cap-add=NET_ADMIN`.
