#!/bin/bash -eu

LATEST_TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
CURRENT_VERSION="$(git describe --tags)"

if [[ "${LATEST_TAG}" != "${CURRENT_VERSION}" ]]; then
  echo "${CURRENT_VERSION} is not tag - not deploying release"
  exit 0
else
  echo "${CURRENT_VERSION} is a tag - deploying to store!"
fi

cat > app/creds.b64 <<EOF
${SERVICEACCOUNTJSON}
EOF

base64 --ignore-garbage --decode app/creds.b64 > app/creds.json

cat > keystore.b64 <<EOF
${KEYSTORE}
EOF

base64 --ignore-garbage --decode keystore.b64 > keystore

cat >> gradle.properties <<EOF
STORE_FILE=$(pwd)/keystore
STORE_PASSWORD=${KEYSTOREPASSWORD}
KEY_ALIAS=${KEYALIAS}
KEY_PASSWORD=${KEYPASSWORD}
EOF

VERSION_CODE="$(cat app/build.gradle | grep "versionCode" | sed "s|\s*versionCode\s*\([0-9]\+\)|\\1|")"
readonly VERSION_CODE

FASTLANE_CL="fastlane/metadata/android/en-US/changelogs/${VERSION_CODE}.txt"
readonly FASTLANE_CL

mkdir -p app/src/main/play/release-notes/en-GB/

# Play store (and thus plugin) has a limit of 500 characters
head --bytes=500 "${FASTLANE_CL}" > app/src/main/play/release-notes/en-GB/default.txt

./gradlew publishPlayBundle
