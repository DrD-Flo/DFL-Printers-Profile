#!/usr/bin/env bash
#
# Publish a new DFL-Printers config version.
#
# Guarantees the git tag and the .ini config_version match. SuperSlicer's auto-update reads the
# version from the TAG name (<config_version>=<min_slicer_version>) but, after downloading, the
# *installed* version comes from config_version INSIDE the .ini. If they differ the updater keeps
# offering an upgrade that never "sticks" (looks stuck / not updating). This script sets both from
# one argument so they can't drift.
#
# Usage:
#   ./publish.sh <config_version> [changelog message...] [--slicer <min_slicer_version>] [--no-push]
#
#   ./publish.sh 2.4.9 "fix Voron seam tuning"
#   ./publish.sh 2.5.0 "new ASA profile" --slicer 2.7.61.0
#   ./publish.sh 2.4.9 --no-push          # commit + tag locally, don't push
#
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

INI="profiles/DFL-Printers.ini"
IDX="profiles/DFL-Printers.idx"
SLICER_VERSION="2.7.63.0"   # min slicer version = right side of the tag (matches .idx min_slic3r_version)
PUSH=1
VERSION=""
MESSAGE=""

cur_version() { awk -F= '/^config_version/{gsub(/ /,"");print $2;exit}' "$INI" 2>/dev/null; }

usage() {
  cat >&2 <<EOF
Usage: ./publish.sh <config_version> [changelog message...] [--slicer <min_slicer_version>] [--no-push]

  Current .ini config_version: $(cur_version)
  Latest tag:                  $(git tag --sort=-v:refname | head -1)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slicer) SLICER_VERSION="${2:?--slicer needs a value}"; shift 2;;
    --no-push) PUSH=0; shift;;
    -h|--help) usage; exit 0;;
    -*) echo "Unknown option: $1" >&2; usage; exit 1;;
    *) if [[ -z "$VERSION" ]]; then VERSION="$1"; else MESSAGE="${MESSAGE:+$MESSAGE }$1"; fi; shift;;
  esac
done

[[ -z "$VERSION" ]] && { usage; exit 1; }
[[ "$VERSION"        =~ ^[0-9]+(\.[0-9]+)+$ ]] || { echo "ERROR: config_version '$VERSION' must be numeric dotted (e.g. 2.4.9)" >&2; exit 1; }
[[ "$SLICER_VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]] || { echo "ERROR: slicer version '$SLICER_VERSION' must be numeric dotted (e.g. 2.7.61.0)" >&2; exit 1; }
[[ -f "$INI" && -f "$IDX" ]] || { echo "ERROR: run from the repo root; missing $INI or $IDX" >&2; exit 1; }
grep -qE '^config_version *=' "$INI" || { echo "ERROR: no 'config_version =' line in $INI" >&2; exit 1; }

TAG="${VERSION}=${SLICER_VERSION}"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && { echo "ERROR: tag '$TAG' already exists; bump the version" >&2; exit 1; }
[[ -z "$MESSAGE" ]] && MESSAGE="release $VERSION"

echo "Publishing $VERSION  (config_version $(cur_version) -> $VERSION, tag $TAG)"

# 1) config_version in the .ini
tmp="$(mktemp)"; awk -v v="$VERSION" '/^config_version *=/{print "config_version = " v; next} {print}' "$INI" > "$tmp" && mv "$tmp" "$INI"
[[ "$(cur_version)" == "$VERSION" ]] || { echo "ERROR: failed to set config_version" >&2; exit 1; }

# 2) changelog line at the top of the .idx (just under min_slic3r_version)
tmp="$(mktemp)"; awk -v line="$VERSION $MESSAGE" 'NR==1{print; print line; next} {print}' "$IDX" > "$tmp" && mv "$tmp" "$IDX"

# 3) commit, 4) tag (left side == config_version, in sync by construction)
git add "$INI" "$IDX"
git commit -q -m "DFL-Printers $VERSION: $MESSAGE"
git tag "$TAG"

# 5) push
if [[ "$PUSH" == "1" ]]; then
  git push -q origin HEAD
  git push -q origin "$TAG"
  echo "Pushed commit + tag $TAG."
else
  echo "Committed + tagged locally ($TAG). Re-run without --no-push, or: git push origin HEAD '$TAG'"
fi
echo "Done: config_version=$VERSION  tag=$TAG  (guaranteed in sync)."
