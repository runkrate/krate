# KRATE

Official downloads for [KRATE](https://krate.github.io/docs/) on Debian: installable `.deb` packages, checksums, release manifest, and changelogs.

**License:** [BSD-3-Clause](LICENSE)

This repository is the **entry point** for installing and updating KRATE on your server. Source code for each component lives in separate repositories; this repo only publishes built packages.

## Role in the stack

| Layer                                                                                                                                 | Responsibility                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **`krate`** (this repo)                                                                                                               | Package downloads, release tags, `krate-release.json` manifest |
| [`console`](https://github.com/runkrate/console)                                                                                  | `zen` / `zenfw` — host operations and self-update              |
| [`setup`](https://github.com/runkrate/setup)                                                                                      | First-install wizard                                           |
| [`web`](https://github.com/runkrate/web)                                                                                          | HarmonyUI dashboard                                            |
| [`core`](https://github.com/krate-apps/core) / [`community`](https://github.com/krate-apps/community) | Application catalogs shipped inside the package                |

## Install

### Quick install (recommended)

On a supported Debian host, download and install the latest release in one step:

```bash
curl -fsSL https://raw.githubusercontent.com/runkrate/krate/main/bootstrap.sh | sudo bash
```

Pre-release (testing):

```bash
curl -fsSL https://raw.githubusercontent.com/runkrate/krate/main/bootstrap.sh | sudo bash -s -- --beta
```

The script detects your OS, fetches `krate-release.json` from GitHub, downloads the matching `.deb`, verifies its SHA256 checksum, and installs it with `apt-get`.

### Manual install

Pick a build from [GitHub Releases](https://github.com/runkrate/krate/releases):

| Channel         | Tag pattern      | Use when                 |
| --------------- | ---------------- | ------------------------ |
| **stable**      | `v1.2.3`         | Production servers       |
| **pre-release** | `v1.2.3-alpha.N` | Testing upcoming changes |

Each release ships one `.deb` per enabled platform (filename includes the OS codename, e.g. `krate_1.2.3-trixie_amd64.deb`), a `SHA256SUMS` file, and `krate-release.json`. Pre-release tags may also include `TESTING.md` (maintained in [`prerelease/TESTING.md`](prerelease/TESTING.md)) when it contains a manual testing checklist for beta testers.

```bash
wget https://github.com/runkrate/krate/releases/download/<tag>/krate_<version>-trixie_amd64.deb
sha256sum -c SHA256SUMS
sudo dpkg -i krate_<version>-trixie_amd64.deb
```

Then configure `/root/krate.conf` and run [`setup`](https://github.com/runkrate/setup).

## Update

On an installed host, `zen pull` reads `krate-release.json`, verifies the checksum, and installs the matching `.deb` for your platform:

```bash
zen pull --check    # report available update without installing
zen pull            # download and install
```

Set `update_channel` in `/etc/krate/environment.d/zenfw.conf.local` (written by setup from `branch=` in `krate.conf`) to choose **main** (stable) or **beta** (pre-release) updates.

## What is in the package

The `krate` `.deb` bundles zen, zenfw, setup, HarmonyUI, and official and community application catalogs.

| Component             | Repository                                                       |
| --------------------- | ---------------------------------------------------------------- |
| Console (zen / zenfw) | [console](https://github.com/runkrate/console)               |
| First-install wizard  | [setup](https://github.com/runkrate/setup)                   |
| Web interface         | [web](https://github.com/runkrate/web)                       |
| Official apps         | [core](https://github.com/krate-apps/core)                   |
| Community apps        | [community](https://github.com/krate-apps/community)         |

Optional add-ons and plugins for individual apps live in [`extensions`](https://github.com/krate-apps/extensions) — not bundled in the core package.

Release changelogs are also published to [`docs`](https://github.com/runkrate/docs) under `docs/changelogs/`.

## Documentation

- [KRATE documentation](https://krate.github.io/docs/)
- [Versioning rules](https://github.com/krate-tools/scripts/blob/main/VERSIONING.md) (maintainers)
