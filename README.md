Still in development.

# O̍h Tâi Gí
A Taiwanese (tâi-gí) learning app inspired by [moedict](https://github.com/g0v/moedict-webkit) & [quizlet](https://zh.wikipedia.org/wiki/Quizlet).

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/com.gonnaggstudio.oh_tai_gi/)
[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get it on Google Play"
     height="80">](https://play.google.com/store/apps/details?id=com.gonnaggstudio.oh_tai_gi)

## Development

Requires Flutter 3.47 or newer (Dart 3.10+).

```sh
cp lib/utils/secret.dart.example lib/utils/secret.dart   # AdMob unit ids (test ids by default)
flutter pub get
flutter analyze
flutter test
flutter run
```

### Flavors

* **Google Play** (default): Firebase Analytics, Crashlytics and AdMob.
* **F-Droid / FOSS**: run `scripts/make_foss.sh` first. It removes every
  non-free dependency (lines marked `# NONFREE` / `// FIREBASE`) and swaps
  `lib/services/*.dart` for the no-op `*_foss.dart` versions. `secret.dart`
  is not needed. See `docs/fdroid-build-recipe.yml`.

Release signing reads `android/key.properties`; without it release builds
are left unsigned (as F-Droid expects).

See [docs/MIGRATION_PLAN.md](docs/MIGRATION_PLAN.md) for the Flutter 3 migration notes.
