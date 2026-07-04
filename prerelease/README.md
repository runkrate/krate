# Pre-release testing checklist

For **stable** releases, nothing is published from this folder.

For **pre-release** builds (`KRATE_RELEASE_CHANNEL=pre-release`), CI copies
[`TESTING.md`](TESTING.md) to the GitHub release as asset `TESTING.md` only when
the file contains non-whitespace content. An empty or missing file is skipped.

HarmonyUI (admin update page) can fetch and display this file when a beta or rc
update is available. The UI layout is still evolving; the release contract is
fixed markdown in `TESTING.md`.

## Maintainer workflow

1. Update `TESTING.md` on `develop` with what testers should verify for the
   upcoming beta or rc.
2. Run **Build KRATE Deb** with channel `pre-release`.
3. Testers open **Settings → System updates** after `zen pull --check` shows an
   update, or read `TESTING.md` directly on the GitHub release page.
