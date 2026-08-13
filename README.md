<!-- KRATE-README-HEADER:START -->
<p align="center">
  <a href="https://github.com/runkrate">
    <img src="https://raw.githubusercontent.com/runkrate/.github/main/assets/logo/logo.png" alt="KRATE" width="128" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/runkrate/krate/stargazers"><img src="https://img.shields.io/github/stars/runkrate/krate?style=flat-square&logo=github" alt="GitHub stars" /></a>
  <a href="https://github.com/runkrate/krate/releases"><img src="https://img.shields.io/github/v/release/runkrate/krate?style=flat-square&label=version" alt="Current version" /></a>
  <a href="https://github.com/runkrate/krate/blob/main/LICENSE"><img src="https://img.shields.io/github/license/runkrate/krate?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://runkrate.com"><img src="https://img.shields.io/badge/Website-runkrate.com-0A66C2?style=flat-square" alt="Website" /></a>
  <a href="https://runkrate.com/docs"><img src="https://img.shields.io/badge/Docs-runkrate.com%2Fdocs-111827?style=flat-square" alt="Docs" /></a>
  <a href="https://github.com/runkrate/hub/issues"><img src="https://img.shields.io/github/issues-search/runkrate/hub?query=is%3Aopen&style=flat-square&label=issues%2FPRs" alt="Open issues and pull requests" /></a>
</p>
<!-- KRATE-README-HEADER:END -->

# KRATE

**Your server. Your apps. One simple platform.**

KRATE turns a fresh Debian server into a managed home for your media and automation stack.

**This is the official KRATE distribution repository.** Releases published here are the official builds intended for end users.

## What is KRATE?

KRATE is a self-hosted platform for managing media and automation applications on your own Linux server.

It provides:

- **zen** — CLI for installation, updates, and server administration
- **HarmonyUI** — web interface for managing your stack
- **Application catalogs** — official and community applications
- **Built-in updates** — safely download, verify, and install releases
- **Bare-metal deployment** — no Docker required

## Requirements

| Requirement | Support |
| --- | --- |
| **OS** | Debian 13 (trixie) |
| **Architecture** | amd64 |
| **Installation** | Bare metal |
| **Docker** | Not required |

Additional operating systems and architectures are planned.

## Installation

### Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/runkrate/krate/main/bootstrap.sh | sudo bash
```

The bootstrap script does not install arbitrary software from third-party repositories. It downloads the official KRATE package from [GitHub Releases](https://github.com/runkrate/krate/releases), verifies its checksum, and installs it through APT.

> **Security:** KRATE releases are published through GitHub Releases and verified before installation.

After install, edit `/root/krate.conf` and run `setup`. See the [documentation](https://runkrate.com/docs) for details.

<details>
<summary><strong>Manual installation</strong></summary>

Prefer the bootstrap above when you can. For a fully manual install, open a root shell first (`sudo -i` or `sudo -s`) and run every step as root — do not mix an unprivileged download with a later `sudo` install.

Pick a release tag from [GitHub Releases](https://github.com/runkrate/krate/releases), then set the variables to match your host and the asset names on that release:

```bash
sudo -i

# Example values — replace with the tag/version and platform you want
VERSION=1.2.3          # package version (no leading "v")
TAG=v${VERSION}        # GitHub release tag
CODENAME=trixie        # Debian codename in the .deb filename
ARCH=amd64

BASE="https://github.com/runkrate/krate/releases/download/${TAG}"
DEB="krate_${VERSION}-${CODENAME}_${ARCH}.deb"

# Download package + checksums (curl or wget)
curl -fLO "${BASE}/${DEB}"
curl -fLO "${BASE}/SHA256SUMS"
# wget -q "${BASE}/${DEB}" "${BASE}/SHA256SUMS"

# Verify SHA256 (checks only the files you downloaded)
sha256sum -c --ignore-missing SHA256SUMS

# Install the .deb
apt-get update
apt-get install -y "./${DEB}"
# alternative: dpkg -i "./${DEB}" && apt-get install -f -y
```

Then configure the host and finish first-time setup (still as root):

```bash
nano /root/krate.conf
/opt/Krate/bin/setup
```

| Channel | Tag pattern | Use when |
| --- | --- | --- |
| Stable | `v1.2.3` | Production |
| Pre-release | `v1.2.3-beta.N` / `v1.2.3-rc.N` | Testing |

</details>

## Updates

KRATE manages its own updates through `zen`.

```bash
zen pull --check    # report available update without installing
zen pull            # download, verify, and install
```

`zen pull` checks for a newer KRATE release, downloads the matching package for your platform, verifies it, and installs the update.

## What's included

Every KRATE `.deb` package includes:

- **zen** — KRATE administration CLI
- **zenfw** — framework / runtime components
- **setup** — first-time host configuration
- **HarmonyUI** — web administration interface
- **Official application catalog**
- **Community application catalog**

Application-specific extensions are distributed separately in [`krate-apps/extensions`](https://github.com/krate-apps/extensions) and are not required for a normal install.

## Architecture

| Component | Purpose |
| --- | --- |
| **zen** | CLI and day-to-day host operations |
| **HarmonyUI** | Web administration interface |
| **App catalogs** | Application definitions and integrations |

### Repository structure

This repository contains the official KRATE **distribution** packages.

KRATE itself is composed of several open-source components maintained in separate repositories. Those repositories contain **source code**, not alternative KRATE distributions.

**If you want to install KRATE, use this repository’s releases.**

```text
runkrate/
├── krate      ← official distribution / releases  (this repo)
├── console    ← zen / zenfw source
├── setup      ← first-install wizard source
├── web        ← HarmonyUI source
└── docs       ← documentation sources
```

Application catalogs live under [`krate-apps`](https://github.com/krate-apps) (`core`, `community`, `extensions`).

## Project status

KRATE is actively developed.

The current release supports:

- Debian 13 (trixie)
- amd64
- bare-metal installations

Additional operating systems and architectures are planned.

## Useful links

- [Documentation](https://runkrate.com/docs)
- [Report a bug or suggest a feature](https://github.com/runkrate/hub/issues)
- [Release changelogs](https://github.com/runkrate/docs/tree/main/docs/changelogs)

## Supporting KRATE

KRATE is primarily funded through its paid licenses. If you’d like to support the project beyond that, you can make a one-time contribution on [Ko-fi](https://ko-fi.com/krate).

More details: [`FUNDING.md`](https://github.com/runkrate/.github/blob/main/FUNDING.md)

## Contributing

Source for the components shipped in this package lives in sibling repositories. See the [contributing guide](https://github.com/runkrate/docs/blob/main/CONTRIBUTING.md) for how to report issues and open pull requests. Bug reports and feature ideas go to [hub](https://github.com/runkrate/hub).

## License

KRATE distribution packages in this repository are licensed under the [BSD 3-Clause License](LICENSE).
