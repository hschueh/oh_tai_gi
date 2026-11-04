#!/usr/bin/env bash
# Turns the source tree into the F-Droid (FOSS) flavor: no Firebase
# Analytics/Crashlytics and no AdMob.
#
# It relies on markers instead of guessing with sed, so it keeps working when
# the code around them changes:
#   pubspec.yaml               lines ending with `# NONFREE`
#   android/*.gradle.kts       lines ending with `// FIREBASE`
#   AndroidManifest.xml        the block between ADMOB_START and ADMOB_END
#   lib/services/X.dart        replaced by lib/services/X_foss.dart
#
# Usage (from the repository root, before `flutter pub get`):
#   scripts/make_foss.sh
set -euo pipefail

cd "$(dirname "$0")/.."

sed -i -e '/# NONFREE$/d' pubspec.yaml
sed -i -e '/\/\/ FIREBASE$/d' android/settings.gradle.kts android/app/build.gradle.kts
sed -i -e '/ADMOB_START/,/ADMOB_END/d' android/app/src/main/AndroidManifest.xml

# Guarded so that running the script twice is harmless.
for service in lib/services/*_foss.dart; do
  [ -e "$service" ] || continue
  mv "$service" "${service%_foss.dart}.dart"
done

rm -f android/app/google-services.json ios/Runner/GoogleService-Info.plist

# Fail loudly if anything non-free is still referenced.
if grep -rnE 'firebase|google_mobile_ads|gms' pubspec.yaml lib android/settings.gradle.kts \
    android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml; then
  echo "make_foss.sh: non-free references left (see above)" >&2
  exit 1
fi
echo "FOSS flavor ready. Run: flutter pub get && flutter build apk --release"
