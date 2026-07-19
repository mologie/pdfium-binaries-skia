#!/bin/bash -eu

# Cut a release of this Skia-backed PDFium fork.
#
# Discovers the latest Chromium version (or takes one as $1), then
# dispatches the "Build all" workflow with release publishing on - the
# manual replacement for the removed weekly trigger. Run it after
# rebasing this fork onto upstream and pushing the branch: the workflow
# builds the ref as it exists on GitHub, not your local tree.
#
#   ./release.sh                 # latest Chromium
#   ./release.sh 152.0.7947.0    # a specific version
#
# Env overrides: PDFIUM_RELEASE_REPO, PDFIUM_RELEASE_REF.

REPO=${PDFIUM_RELEASE_REPO:-mologie/pdfium-binaries-skia}
REF=${PDFIUM_RELEASE_REF:-$(git rev-parse --abbrev-ref HEAD)}

VERSION=${1:-}
if [[ -z $VERSION ]]; then
  VERSION=$(git ls-remote --sort version:refname --tags \
    https://chromium.googlesource.com/chromium/src '*.*.*.0' \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.0' | tail -n1)
fi

# the release tags with the pdfium branch, whose number is the third
# component of the Chromium version (152.0.7947.0 -> chromium/7947)
BRANCH="chromium/$(echo "$VERSION" | cut -d. -f3)"

# warn on the common post-rebase footgun: a build off a stale remote ref
if git rev-parse --verify -q '@{u}' >/dev/null \
  && [[ $(git rev-parse HEAD) != $(git rev-parse '@{u}') ]]; then
  echo "warning: local $REF differs from its upstream; push first or the" \
    "workflow builds the old ref." >&2
fi

echo "Releasing PDFium $VERSION ($BRANCH) from $REPO@$REF"
gh workflow run build-all.yml -R "$REPO" --ref "$REF" \
  -f branch="$BRANCH" \
  -f version="$VERSION" \
  -f is_debug=false \
  -f release=true
