#!/usr/bin/env bash
# Points the `/issues/N` links of the given files at `/pull/N` when N is a pull request.
#
# release-please links every `(#N)` of the release notes to `/issues/N`, pull requests included. GitHub
# redirects that URL, but its in-app navigation fails on it ("Unable to load page"). Issues keep their
# links: only the numbers GitHub reports as pull requests are rewritten.
#
# usage: link-pull-requests.sh OWNER/REPO FILE...
set -euo pipefail

repo="$1"
shift

for file in "$@"; do
  numbers="$(grep -oE "github\.com/${repo}/issues/[0-9]+\)" "$file" | sed -E 's%.*/issues/([0-9]+)\)%\1%' | sort -un || true)"

  for number in $numbers; do
    if [ "$(gh api "repos/${repo}/issues/${number}" --jq '.pull_request != null')" = "true" ]; then
      sed -i "s#github\.com/${repo}/issues/${number})#github.com/${repo}/pull/${number})#g" "$file"
    fi
  done
done
