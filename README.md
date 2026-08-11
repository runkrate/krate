<!-- KRATE-README-HEADER:START -->
<p align="center">
  <a href="https://github.com/runkrate">
    <img src="https://raw.githubusercontent.com/runkrate/.github/main/assets/logo/logo.png" alt="KRATE" width="128" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/runkrate/krate/stargazers"><img src="https://img.shields.io/github/stars/runkrate/krate?style=flat-square&logo=github" alt="GitHub stars" /></a>
  <a href="https://github.com/runkrate/hub/issues"><img src="https://img.shields.io/github/issues-search/runkrate/hub?query=is%3Aopen&style=flat-square&label=issues%2FPRs" alt="Open issues and pull requests" /></a>
  <a href="https://github.com/runkrate/krate/releases"><img src="https://img.shields.io/github/v/release/runkrate/krate?style=flat-square&label=version" alt="Current version" /></a>
  <a href="https://github.com/runkrate/krate/blob/main/LICENSE"><img src="https://img.shields.io/github/license/runkrate/krate?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://runkrate.com"><img src="https://img.shields.io/badge/Website-runkrate.com-0A66C2?style=flat-square" alt="Website" /></a>
  <a href="https://runkrate.com/docs"><img src="https://img.shields.io/badge/Docs-runkrate.com%2Fdocs-111827?style=flat-square" alt="Docs" /></a>
  <a href="https://ko-fi.com/krate"><img src="https://img.shields.io/badge/Ko--fi-Support-FF5E5B?style=flat-square&logo=ko-fi&logoColor=white" alt="Ko-fi" /></a>
  <a href="https://buymeacoffee.com/krate"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee" /></a>
</p>
<!-- KRATE-README-HEADER:END -->

# KRATE

Self-hosted media and automation for Linux servers.

**This repository is where you download KRATE.** Releases here are the only builds meant for end users. Source for each component lives in other repositories; those are not alternate installers.

**License:** [BSD-3-Clause](LICENSE)

## Install

**Requirements:** Debian 13 (trixie), **amd64** only for now. Support for other OS / architectures will be added later.

### Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/runkrate/krate/main/bootstrap.sh | sudo bash
```

The script detects your OS, downloads the matching `.deb` from this repo’s releases, verifies its checksum, and installs it with `apt-get`.

### Manual install

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

See the [documentation](https://runkrate.com/docs) for `krate.conf` fields and post-install steps.

| Channel     | Tag pattern                     | Use when   |
| ----------- | ------------------------------- | ---------- |
| Stable      | `v1.2.3`                        | Production |
| Pre-release | `v1.2.3-beta.N` / `v1.2.3-rc.N` | Testing    |

## Update

On an installed host:

```bash
zen pull --check    # check only
zen pull            # download and install
```

## What is in the package

The `.deb` bundles **console** (`zen` / `zenfw`), **setup**, **HarmonyUI**, and the **official** and **community** application catalogs.

Optional add-ons for individual apps are published separately in [`krate-apps/extensions`](https://github.com/krate-apps/extensions) — they are not required for a normal install.

## Useful links

- [Documentation](https://runkrate.com/docs)
- [Report a bug or suggest a feature](https://github.com/runkrate/hub/issues)
- [Release changelogs](https://github.com/runkrate/docs/tree/main/docs/changelogs)

## Contributing

Source for the components shipped in this package lives in sibling repositories (`console`, `setup`, `web`, app catalogs, …). See the [contributing guide](https://github.com/runkrate/docs/blob/main/CONTRIBUTING.md) for how to report issues and open pull requests.
