#!/bin/sh

set -ex

GNUPGHOME=${1:-"$(cd "$(dirname "$0")"; pwd)/gpg"}
ONLY_ACTIVE_KEYS=${2:-"$GNUPGHOME-only-active-keys"}

if [ -d "$GNUPGHOME" ]; then
  # If folder exists, move it to a temp dir
  # Removing it could be dangerous
  TRASH=$(mktemp -d)
  mv "$GNUPGHOME" "$TRASH"
fi
if [ -d "$ONLY_ACTIVE_KEYS" ]; then
  # If folder exists, move it to a temp dir
  # Removing it could be dangerous
  TRASH=$(mktemp -d)
  mv "$ONLY_ACTIVE_KEYS" "$TRASH"
fi

mkdir -p "$GNUPGHOME"

# You can set this variable in your env to use a local version of the nodejs/node README instead of getting it from the internet.
[ -n "$NODEJS_README_PATH" ] || {
  NODEJS_README_PATH=$(mktemp)
  curl -sSLo "$NODEJS_README_PATH" https://github.com/nodejs/node/raw/HEAD/README.md
}

awk -F'`' '/^### Release keys$/,/^<summary>Other keys used to sign some previous releases<.summary>$/{if($1 == "  ") print $2 }' "$NODEJS_README_PATH" | while read -r KEY_ID; do
  GNUPGHOME="$GNUPGHOME" gpg --import "keys/$KEY_ID.asc"
  GNUPGHOME="$GNUPGHOME" gpg --command-fd 0 --edit-key "$KEY_ID" <<'EOF'
trust
4
save
EOF
done

cp -R "$GNUPGHOME" "$ONLY_ACTIVE_KEYS"

awk -F'`' '/^<summary>Other keys used to sign some previous releases<.summary>$/,/^<.details>$/{if($1 == "  ") print $2 }' "$NODEJS_README_PATH" | while read -r OLD_KEY; do
  GNUPGHOME="$GNUPGHOME" gpg --import "keys/$OLD_KEY.asc"
  GNUPGHOME="$GNUPGHOME" gpg --command-fd 0 --edit-key "$OLD_KEY" <<'EOF'
trust
3
save
EOF
done
