#!/usr/bin/env bash

set -euo pipefail

FLUTTER_DIR="${HOME}/flutter"

required_variables=(
  API_BASE_URL
  FIREBASE_API_KEY
  FIREBASE_APP_ID
  FIREBASE_MESSAGING_SENDER_ID
  FIREBASE_PROJECT_ID
  FIREBASE_AUTH_DOMAIN
  FIREBASE_STORAGE_BUCKET
  FIREBASE_WEB_VAPID_KEY
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Variável obrigatória ausente: ${variable_name}" >&2
    exit 1
  fi
done

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  rm -rf "${FLUTTER_DIR}"
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

cp web/firebase-messaging-sw.js.example web/firebase-messaging-sw.js
sed -i \
  -e "s|SUA_API_KEY|${FIREBASE_API_KEY}|g" \
  -e "s|SEU_AUTH_DOMAIN|${FIREBASE_AUTH_DOMAIN}|g" \
  -e "s|SEU_PROJECT_ID|${FIREBASE_PROJECT_ID}|g" \
  -e "s|SEU_STORAGE_BUCKET|${FIREBASE_STORAGE_BUCKET}|g" \
  -e "s|SEU_MESSAGING_SENDER_ID|${FIREBASE_MESSAGING_SENDER_ID}|g" \
  -e "s|SEU_APP_ID|${FIREBASE_APP_ID}|g" \
  web/firebase-messaging-sw.js

flutter config --enable-web
flutter precache --web
flutter pub get
flutter build web --release \
  --dart-define=USE_BACKEND=true \
  --dart-define="API_BASE_URL=${API_BASE_URL}" \
  --dart-define="FIREBASE_API_KEY=${FIREBASE_API_KEY}" \
  --dart-define="FIREBASE_APP_ID=${FIREBASE_APP_ID}" \
  --dart-define="FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}" \
  --dart-define="FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}" \
  --dart-define="FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}" \
  --dart-define="FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}" \
  --dart-define="FIREBASE_WEB_VAPID_KEY=${FIREBASE_WEB_VAPID_KEY}"
