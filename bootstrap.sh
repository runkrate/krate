#!/usr/bin/env bash
# Install KRATE from the latest GitHub release (.deb).
# Usage:
#   sudo ./bootstrap.sh           # latest stable release
#   sudo ./bootstrap.sh --beta    # latest pre-release (temporary flag)
set -euo pipefail

KRATE_RELEASES_REPO="${KRATE_RELEASES_REPO:-runkrate/krate}"
CHANNEL="stable"
WORK_DIR=""

usage() {
	cat <<'EOF'
Usage: bootstrap.sh [--beta]

Detect the host OS, download the matching krate .deb from the latest GitHub
release, verify its SHA256 checksum, and install it with apt.

  (default)   Latest stable release
  --beta      Latest pre-release (flag will be removed in a future version)

Requires: root, curl, python3, sha256sum, apt-get
EOF
}

cleanup() {
	if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
		rm -rf "${WORK_DIR}"
	fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
	case "$1" in
	--beta)
		CHANNEL="pre-release"
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "ERROR: unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
done

if [[ "${EUID}" -ne 0 ]]; then
	echo "ERROR: run as root (e.g. sudo $0)" >&2
	exit 1
fi

for cmd in curl python3 sha256sum apt-get; do
	if ! command -v "${cmd}" >/dev/null 2>&1; then
		echo "ERROR: required command not found: ${cmd}" >&2
		exit 1
	fi
done

WORK_DIR="$(mktemp -d /tmp/krate-bootstrap.XXXXXX)"
clear
echo "==> Detecting host OS"
mapfile -t _os < <(python3 - <<'PY'
import os
import re
import subprocess
import sys


def read_os_release():
    data = {}
    try:
        with open("/etc/os-release", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                data[key] = value.strip().strip('"')
    except OSError:
        pass
    return data


def version_parts(value: str):
    parts = []
    for chunk in re.split(r"[.~+-]", value):
        if chunk.isdigit():
            parts.append(int(chunk))
        elif chunk:
            parts.append(chunk)
    return parts


def version_ge(left: str, right: str) -> bool:
    a = version_parts(left)
    b = version_parts(right)
    for i in range(max(len(a), len(b))):
        av = a[i] if i < len(a) else 0
        bv = b[i] if i < len(b) else 0
        if isinstance(av, int) and isinstance(bv, int):
            if av != bv:
                return av > bv
            continue
        if str(av) != str(bv):
            return str(av) > str(bv)
    return True


rel = read_os_release()
os_id = rel.get("ID", "").lower()
version = rel.get("VERSION_ID", "")
codename = rel.get("VERSION_CODENAME", "") or rel.get("DEBIAN_CODENAME", "")
if not codename:
    try:
        codename = subprocess.check_output(["lsb_release", "-cs"], text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        codename = ""

pretty = rel.get("PRETTY_NAME", "").lower()
if os_id == "debian" and codename == "forky" and (version == "13" or "trixie" in pretty):
    codename = "trixie"


def normalize_arch(machine: str) -> str:
    return {"x86_64": "amd64", "aarch64": "arm64"}.get(machine, machine)


def krate_platform_key(os_id: str, os_version: str) -> str:
    if os_id == "debian":
        major = re.split(r"[.~+-]", os_version, maxsplit=1)[0]
        if major.isdigit() and int(major) >= 13:
            return "debian13-amd64"
    if os_id == "ubuntu" and os_version == "24.04":
        return "ubuntu24-amd64"
    return ""


arch = normalize_arch(os.uname().machine)
platform_key = krate_platform_key(os_id, version)
print(os_id)
print(version)
print(codename)
print(arch)
print(platform_key)
PY
)
OS_ID="${_os[0]:-}"
OS_VERSION="${_os[1]:-}"
OS_CODENAME="${_os[2]:-}"
OS_ARCH="${_os[3]:-}"
PLATFORM_KEY="${_os[4]:-}"

if [[ -z "${OS_ID}" || -z "${OS_ARCH}" ]]; then
	echo "ERROR: could not detect OS (missing /etc/os-release?)" >&2
	exit 1
fi

echo "    ${OS_ID} ${OS_VERSION} (${OS_CODENAME:-unknown}) ${OS_ARCH}"

echo "==> Resolving latest ${CHANNEL} release"
RELEASE_JSON="${WORK_DIR}/releases.json"
curl -fsSL \
	-H "Accept: application/vnd.github+json" \
	-H "X-GitHub-Api-Version: 2022-11-28" \
	"https://api.github.com/repos/${KRATE_RELEASES_REPO}/releases?per_page=30" \
	-o "${RELEASE_JSON}"

mapfile -t _pick < <(python3 - "${CHANNEL}" "${RELEASE_JSON}" <<'PY'
import json
import sys

channel = sys.argv[1]
want_prerelease = channel == "pre-release"
with open(sys.argv[2], encoding="utf-8") as handle:
    releases = json.load(handle)

for release in releases:
    if release.get("draft"):
        continue
    if bool(release.get("prerelease")) != want_prerelease:
        continue
    tag = release.get("tag_name", "")
    manifest_url = ""
    for asset in release.get("assets", []):
        if asset.get("name") == "krate-release.json":
            manifest_url = asset.get("browser_download_url", "")
            break
    if not tag or not manifest_url:
        continue
    print(tag)
    print(manifest_url)
    sys.exit(0)

print(f"ERROR: no {channel} release found on GitHub", file=sys.stderr)
sys.exit(1)
PY
)
if [[ ${#_pick[@]} -lt 2 ]]; then
	exit 1
fi
RELEASE_TAG="${_pick[0]}"
MANIFEST_URL="${_pick[1]}"

echo "    release ${RELEASE_TAG}"

MANIFEST_PATH="${WORK_DIR}/krate-release.json"
curl -fsSL "${MANIFEST_URL}" -o "${MANIFEST_PATH}"

mapfile -t _asset < <(python3 - \
	"${MANIFEST_PATH}" "${RELEASE_JSON}" "${RELEASE_TAG}" \
	"${OS_ID}" "${OS_VERSION}" "${OS_CODENAME}" "${OS_ARCH}" "${PLATFORM_KEY}" <<'PY'
import json
import re
import sys


def version_parts(value: str):
    parts = []
    for chunk in re.split(r"[.~+-]", value):
        if chunk.isdigit():
            parts.append(int(chunk))
        elif chunk:
            parts.append(chunk)
    return parts


def version_ge(left: str, right: str) -> bool:
    a = version_parts(left)
    b = version_parts(right)
    for i in range(max(len(a), len(b))):
        av = a[i] if i < len(a) else 0
        bv = b[i] if i < len(b) else 0
        if isinstance(av, int) and isinstance(bv, int):
            if av != bv:
                return av > bv
            continue
        if str(av) != str(bv):
            return str(av) > str(bv)
    return True


manifest_path, releases_path, release_tag, os_id, os_version, os_codename, arch, platform_key = sys.argv[1:9]
with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)
with open(releases_path, encoding="utf-8") as handle:
    releases = json.load(handle)

release = next((item for item in releases if item.get("tag_name") == release_tag), None)
if release is None:
    print(f"ERROR: release {release_tag} not found in GitHub API response", file=sys.stderr)
    sys.exit(1)

supported = False
for entry in manifest.get("supported_os", []):
    if entry.get("id", "").lower() != os_id.lower():
        continue
    min_version = entry.get("min_version", "")
    if not min_version or version_ge(os_version, min_version):
        supported = True
        break

if not supported:
    expected = manifest.get("supported_os", [])
    hint = ", ".join(
        f"{e.get('id')}>={e.get('min_version')}" for e in expected if isinstance(e, dict)
    ) or "see krate-release.json"
    print(
        f"ERROR: host {os_id} {os_version} is not supported (expected: {hint})",
        file=sys.stderr,
    )
    sys.exit(1)

platforms = manifest.get("platforms", {})
match = None

if platform_key and platform_key in platforms:
    candidate = platforms[platform_key]
    if isinstance(candidate, dict) and candidate.get("arch", "amd64") == arch:
        match = (platform_key, candidate)

if match is None:
    for key, candidate in platforms.items():
        if not isinstance(candidate, dict):
            continue
        if candidate.get("codename", "").lower() != os_codename.lower():
            continue
        if candidate.get("arch", "amd64") != arch:
            continue
        match = (key, candidate)
        break

if match is None:
    keys = ", ".join(sorted(platforms))
    print(
        f"ERROR: no .deb for platform={platform_key or '?'} "
        f"codename={os_codename} arch={arch} "
        f"(manifest platforms: {keys or 'none'})",
        file=sys.stderr,
    )
    sys.exit(1)

_, entry = match
manifest_filename = entry.get("filename", "")
sha256 = entry.get("sha256", "")
if not manifest_filename or not sha256:
    print("ERROR: manifest platform entry missing filename or sha256", file=sys.stderr)
    sys.exit(1)

assets = release.get("assets", [])
download_url = ""
asset_filename = manifest_filename

for asset in assets:
    if asset.get("name") == manifest_filename:
        download_url = asset.get("browser_download_url", "")
        asset_filename = manifest_filename
        break

if not download_url:
    pattern = re.compile(
        rf"^krate_.+-{re.escape(os_codename)}_{re.escape(arch)}\.deb$"
    )
    for asset in assets:
        name = asset.get("name", "")
        if pattern.match(name):
            download_url = asset.get("browser_download_url", "")
            asset_filename = name
            break

if not download_url:
    names = ", ".join(asset.get("name", "") for asset in assets if asset.get("name", "").endswith(".deb"))
    print(
        f"ERROR: no GitHub asset for {manifest_filename} "
        f"(release .deb assets: {names or 'none'})",
        file=sys.stderr,
    )
    sys.exit(1)

print(asset_filename)
print(download_url)
print(sha256)
print(manifest.get("version", ""))
if asset_filename != manifest_filename:
    print(
        f"NOTE: using GitHub asset {asset_filename} (manifest lists {manifest_filename})",
        file=sys.stderr,
    )
PY
)
if [[ ${#_asset[@]} -lt 4 ]]; then
	exit 1
fi
DEB_NAME="${_asset[0]}"
DOWNLOAD_URL="${_asset[1]}"
DEB_SHA="${_asset[2]}"
PACKAGE_VERSION="${_asset[3]}"

echo "    package krate ${PACKAGE_VERSION} → ${DEB_NAME}"

DEB_PATH="${WORK_DIR}/${DEB_NAME}"

echo "==> Downloading ${DEB_NAME}"
curl -fsSL "${DOWNLOAD_URL}" -o "${DEB_PATH}"

echo "==> Verifying SHA256"
actual="$(sha256sum "${DEB_PATH}" | awk '{print $1}')"
if [[ "${actual}" != "${DEB_SHA}" ]]; then
	echo "ERROR: checksum mismatch for ${DEB_NAME}" >&2
	echo "  expected: ${DEB_SHA}" >&2
	echo "  actual:   ${actual}" >&2
	exit 1
fi

echo "==> Updating packages"
DEBIAN_FRONTEND=noninteractive apt-get update -y

echo "==> Installing ${DEB_NAME}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "${DEB_PATH}"

echo "==> Done. KRATE ${PACKAGE_VERSION} (${RELEASE_TAG}) is installed."
echo "    Next: configure /root/krate.conf and run setup"
echo "    nano /root/krate.conf && ./setup"
