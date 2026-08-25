#!/usr/bin/env bash
#
# Patches the template with a tenant's branding before building.
# Required env: APP_NAME PACKAGE_ID API_URL PRIMARY_COLOR VERSION_NAME VERSION_CODE
# Optional env: ICON_URL STORE_ID
#
set -euo pipefail

: "${APP_NAME:?}"; : "${PACKAGE_ID:?}"; : "${API_URL:?}"
: "${PRIMARY_COLOR:=#16a34a}"; : "${VERSION_NAME:=1.0.0}"; : "${VERSION_CODE:=1}"
STORE_ID="${STORE_ID:-}"

echo "→ Preparing build: $APP_NAME ($PACKAGE_ID) v$VERSION_NAME+$VERSION_CODE"

# 1) App config (API URL + name)
cat > lib/config.dart <<EOF
class AppConfig {
  static const String apiBaseUrl = '${API_URL}';
  static const String storeId = '${STORE_ID}';
  static const String appName = '${APP_NAME}';
}
EOF

# 2) Android applicationId + label + version
sed -i "s#applicationId = \"[^\"]*\"#applicationId = \"${PACKAGE_ID}\"#" android/app/build.gradle.kts
sed -i "s#android:label=\"[^\"]*\"#android:label=\"${APP_NAME}\"#" android/app/src/main/AndroidManifest.xml
sed -i "s#^version: .*#version: ${VERSION_NAME}+${VERSION_CODE}#" pubspec.yaml

# 3) Launcher icon (download if provided; else keep default)
mkdir -p assets
if [ -n "${ICON_URL}" ]; then
  echo "→ Downloading icon"
  curl -fsSL "${ICON_URL}" -o assets/icon.png || echo "  (icon download failed, using default)"
fi

cat > flutter_launcher_icons.yaml <<EOF
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"
  adaptive_icon_background: "${PRIMARY_COLOR}"
  adaptive_icon_foreground: "assets/icon.png"
  min_sdk_android: 23
EOF

cat > flutter_native_splash.yaml <<EOF
flutter_native_splash:
  color: "${PRIMARY_COLOR}"
  android: true
  ios: false
  android_12:
    color: "${PRIMARY_COLOR}"
EOF

flutter pub get
if [ -f assets/icon.png ]; then
  dart run flutter_launcher_icons || echo "  (launcher_icons skipped)"
fi
dart run flutter_native_splash:create || echo "  (native_splash skipped)"

echo "→ Prepare done."
