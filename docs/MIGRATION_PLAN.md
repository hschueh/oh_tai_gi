# Flutter 升級計劃（Flutter 1.x → Flutter 3.47 / Dart 3.13）

> 目標：把「熊愛學臺語 (O̍h Tâi Gí)」從 Flutter 1.12~1.22 時代升級到目前最新 stable
> **Flutter 3.47.9 / Dart 3.13.7**，並且：
> 1. 現有使用者升級後 **學習紀錄（learnt）不會遺失**。
> 2. Google Play 版本（含 Firebase / AdMob）與 F-Droid 版本（無非自由元件）都能建置。
> 3. 每一個階段都是一個獨立 commit，可以單獨 review／回滾。

## 進度總覽（2026-11-03）

| Stage | 狀態 | 驗證 |
|---|---|---|
| 0 準備 | ✅ | – |
| 1 Android 結構 | ✅ | ⚠️ 雲端環境無 Android SDK；改由 GitHub Actions（`.github/workflows/ci.yml`）build Play / FOSS 兩個 flavor |
| 2 iOS 結構 | ✅ | ⚠️ 需在 Mac 上 build |
| 3 pubspec | ✅ | `flutter pub get` ✅ |
| 4 null safety | ✅ | `flutter analyze`：No issues found ✅ |
| 5 套件 API / 資料相容 | ✅ | DB migration 測試 5/5 ✅ |
| 6 Framework API | ✅ | `flutter analyze` ✅ |
| 7 驗證 | 🟡 | `flutter test` 20/20 ✅；APK build 交給 CI；實機測試待做 |
| 8 F-Droid | 🟡 | FOSS flavor：analyze ✅ test ✅；待打 tag 提交 |

---

## 0. 現況盤點

| 項目 | 現況 | 問題 |
|---|---|---|
| Flutter | `.metadata` revision `cc949a8`（約 1.12），F-Droid 用 1.22.6 | Dart 3 強制 sound null safety，舊程式碼完全無法編譯 |
| Dart SDK constraint | `>=2.2.2 <3.0.0` | 需改為 `^3.x` |
| Android embedding | `io.flutter.app.FlutterActivity`（v1） | v1 embedding 已在 Flutter 3.x **移除** |
| Gradle / AGP / Kotlin | Gradle 5.4.1 / AGP 3.4.2 / Kotlin 1.3.10 | 需 Gradle 8.x / AGP 8.x / Kotlin 2.x、`plugins {}` DSL、`namespace` |
| Repositories | `jcenter()`、`maven.fabric.io` | jcenter 已關閉、Fabric 已停止服務 |
| compile/target SDK | 28 / 28，minSdk 16 | Play 現在要求 target 35+；Flutter 最低 minSdk 已提高 |
| iOS | Podfile 舊格式、無 platform | 需重新產生（Linux 環境無法實際 build iOS，只做結構升級） |
| 測試 | `test/db_test.dart`（純 model 測試）、空的 widget test | 補 DB 相容性測試 |
| 後端 | `http://ohtaigi.ddns.net:3000` | **DNS 已無法解析**；目前程式在 `http.get` 丟 exception 後連本地備援都不會走到 |

### 套件對照表

| 舊套件 | 新做法 | 主要 API 變化 |
|---|---|---|
| `admob_flutter ^0.3.1`、`firebase_admob ^0.9` | `google_mobile_ads ^9` | `BannerAd` + `AdWidget`、`MobileAds.instance.initialize()` |
| `firebase_analytics ^5` | `firebase_core ^5` + `firebase_analytics ^13` | 需 `Firebase.initializeApp()`；`FirebaseAnalytics.instance`；observer import 路徑改變 |
| `firebase_crashlytics ^0.1`（Fabric） | `firebase_crashlytics ^6` | `FirebaseCrashlytics.instance.recordFlutterFatalError`、`PlatformDispatcher.onError` |
| `audioplayers ^0.13` | `audioplayers ^6` | `UrlSource` / `AssetSource`、`onPlayerComplete`、`AudioCache` 併入 |
| `connectivity ^0.4` | `connectivity_plus ^7` | `checkConnectivity()` 回傳 `List<ConnectivityResult>` |
| `device_info ^0.4` | **移除**（程式中沒用到） | – |
| `flip_card ^0.4` | **自己實作 `FlipCard` widget**（約 80 行） | flip_card 最後版本 0.7.0 限制 `sdk <3.0.0`，Dart 3 無法使用 |
| `feature_discovery ^0.6` | `feature_discovery ^0.14` | `FeatureDiscovery.discoverFeatures` 參數小改 |
| `http ^0.12` | `http ^1` | `http.get(Uri.parse(...))` |
| `sqflite ^1` | `sqflite ^2` + 明確宣告 `path` | 型別更嚴格（`List<Map<String, Object?>>`） |
| `shared_preferences ^0.5` | `shared_preferences ^2` | API 相容 |
| `youtube_player_flutter ^6` | `youtube_player_flutter ^10` | `YoutubePlayerController(initialVideoId:, flags:)` 基本相同 |
| `cupertino_icons ^0.1` | `^1` 或移除 | 程式未使用 Cupertino icons，直接移除 |
| – | `flutter_lints`、`sqflite_common_ffi`（dev） | lint + 在電腦上跑 DB 測試 |

### Flutter framework API 變化（會碰到的）

- `textTheme.title/subtitle/subhead/body1/body2/headline/display1/display2`
  → `titleLarge/titleSmall/titleMedium/bodyMedium/bodyLarge/headlineSmall/headlineMedium/displaySmall`
- `FlatButton` → `TextButton`／`FilledButton`
- `BottomNavigationBarItem(title:)` → `label:`
- `SelectableText(toolbarOptions:)` → 預設 context menu（直接移除即可）
- `SystemChrome.setEnabledSystemUIOverlays([])` → `setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`
- `withOpacity` → `withValues(alpha:)`
- Material 3 預設開啟 → 先設 `useMaterial3: false` 保持原本外觀，之後再視需要改版
- `context.dependOnInheritedWidgetOfExactType(aspect: OTGConfig)`（OTGConfig 根本不是 InheritedWidget）→ 刪掉

---

## ⚠️ 資料相容性的關鍵風險：`String.hashCode` 被存進資料庫

`vocabulary` 和 `vocabulary_list` 兩張表都有 `hashCode` 欄位，存的是 `title.hashCode`，
而且查詢單字表內容時是用 `getVocabularyWithTitleHash(title.hashCode)`。

Dart **不保證** `String.hashCode` 在不同 SDK 版本間一致。如果新 Dart 算出的 hash 不同：
- 「主題詞彙」裡的單字全部查不到
- 舊使用者會看到空白列表

**對策**（Stage 5）：
1. 查詢改用 `title` 欄位（本來就有存），不再依賴 hash；`hashCode` 欄位保留但只當作寫入時的輔助資料。
2. DB version 2 → 3：在 `onUpgrade` 為 `title` 建 index（查詢速度不輸 hash）。
3. 用 `sqflite_common_ffi` 寫測試：建一個 **v2 格式、hash 是亂數** 的舊 DB，確認升級後學習紀錄還在、用 title 查得到。

---

## 執行階段

每個 Stage 結束都要：`flutter analyze` 沒有 error →（能跑的話）`flutter test` → commit。

### Stage 0 – 準備工作
- [x] 安裝 Flutter 3.47.9 stable（雲端環境用）
- [x] 新增 `lib/utils/secret.dart.example`（`secret.dart` 被 gitignore，沒有它無法編譯）
- [x] 更新 `.gitignore`（新版 Flutter 產生的檔案）
- [x] 本文件

### Stage 1 – Android 專案結構升級
- [x] 用 `flutter create` 產生新版 android 範本做參考
- [x] `settings.gradle`：改用 `dev.flutter.flutter-plugin-loader` + `pluginManagement`
- [x] `build.gradle`（root / app）：`plugins {}` DSL、AGP 8.x、Kotlin 2.x、Gradle wrapper 8.x、Java 17
- [x] `namespace "com.gonnaggstudio.oh_tai_gi"`，移除 manifest 中的 `package=`
- [x] 移除 Fabric、jcenter；Crashlytics 改用 `com.google.firebase.crashlytics` gradle plugin
- [x] compileSdk/targetSdk 跟隨 `flutter.compileSdkVersion` / `flutter.targetSdkVersion`，minSdk 用 `flutter.minSdkVersion`
  - ⚠️ **minSdk 從 16 變成 24**（Flutter 3.47 與 google_mobile_ads 9 的最低需求）：Android 7.0 以下的使用者會停留在 1.0.21，release notes 要寫
- [x] Release signing：`key.properties` 不存在時 release 不簽章（F-Droid 自己簽；避免誤把 debug key 簽的 AAB 上傳到 Play）
- [x] `MainActivity.kt` 改用 v2 embedding（`configureFlutterEngine`），保留 `PROCESS_TEXT`「揣臺語」功能，並補上 `onNewIntent`（`singleTop` 時第二次選字也能用）
- [x] Manifest：移除 `io.flutter.app.FlutterApplication`、加 `flutterEmbedding=2`、`android:exported="true"`、`<queries>` for PROCESS_TEXT

### Stage 2 – iOS 專案結構升級
- [x] 以新範本重建 Xcode 專案（Swift Package Manager、UIScene、iOS 15）、`AppFrameworkInfo.plist`、xcconfig
- [x] 保留 `GoogleService-Info.plist`、App icon、`Info.plist` 的顯示名稱與 AdMob `GADApplicationIdentifier`
- [x] 刪除過時的 `Podfile`、`Flutter.podspec`、`Podfile.lock`（Flutter 需要 CocoaPods 時會自動產生）
- [ ] Crashlytics dSYM 上傳：舊的 Fabric run script 已移除，需要在 Mac 上跑 `flutterfire configure` 補上 upload-symbols build phase，否則 iOS 當機報告沒有符號
- [ ] ⚠️ 這個雲端環境是 Linux，無法實際 build iOS；需要在 Mac 上 `flutter build ios` 驗證（專案已改用 Swift Package Manager，Flutter 會在需要時自動產生 Podfile）

### Stage 3 – pubspec 與相依套件
- [x] `environment: sdk: ^3.10.0`
- [x] 依上方對照表更新/替換套件
- [x] 加入 `analysis_options.yaml`（`flutter_lints`）

### Stage 4 – Dart 3 null safety 遷移（最大的一塊）
- [x] models：`Vocabulary` / `Heteronym` / `Definition` / `VocabularyList` 欄位型別化、`fromJson` 容錯
- [x] providers：`Database?` → `late final`、回傳 `Future<Vocabulary?>`
- [x] 所有 widget：`{Key key}` → `{super.key}`、`required`、`late`
- [x] `Function` 型別改為明確的 typedef
- [x] 舊 widget 測試 / unused_page 清理

### Stage 5 – 套件 API 遷移 & 資料相容
- [x] `AudioPlayerHolder` 改寫成 audioplayers 6（等待 `onPlayerStateChanged` 離開 playing，取代 busy-wait loop）；音訊設成 `mixWithOthers`，不搶背景音樂的 audio focus（與舊版行為相同）
- [x] `getConnectivityResult()` 改用 connectivity_plus 的 List 回傳
- [x] `fetchVocabularyLists`：`Uri.parse`、加 timeout、try/catch → 伺服器掛掉時能走本地 `dict-list.json` 備援
- [x] 廣告：抽成 `lib/services/ads.dart`（`google_mobile_ads` BannerAd + AdWidget）
- [x] 統計/當機回報：抽成 `lib/services/telemetry.dart`（firebase_core + analytics + crashlytics）
- [x] FlipCard 自己實作 `lib/ui/component/flip_card.dart`
- [x] DB：title 查詢、DB v3 index、`hashCode` 相容性處理
- [x] 新增 DB migration 測試

### Stage 6 – Flutter framework API 遷移
- [x] textTheme、按鈕、BottomNavigationBar、SystemChrome、SelectableText…（見上方列表）
- [x] `ThemeData(useMaterial3: false, fontFamily: 'huninn')`
- [x] `flutter analyze` 0 error、盡量 0 warning

### Stage 7 – 驗證
- [x] `flutter test`（model + DB migration + widget smoke test）
- [ ] `flutter build apk --debug`：⚠️ 雲端環境的網路政策擋住 `dl.google.com`（Android SDK 與 Google Maven），無法在這裡驗證，需在本機執行
- [ ] 手動驗證清單（需要實機）：
  - 從舊版 1.0.21 覆蓋安裝 → 學習歷程還在、主題詞彙列表內容正常
  - 隨機學習左右滑、自動播放語音
  - 翻牌遊戲音效 + 翻牌動畫
  - 在其他 App 選字 →「揣臺語」→ 開啟搜尋頁並帶入關鍵字
  - 主題詞彙 YouTube 影片播放
  - 廣告 banner 顯示

### Stage 8 – F-Droid 與發佈
- [x] 目前 F-Droid 是用一串 `sed` 把 firebase/admob 砍掉後再 build；程式碼結構改變後那串 sed 一定會壞
- [x] 讓 F-Droid recipe 變簡單：Firebase/AdMob 的程式碼都集中在 `lib/services/`，
  另外提供 `lib/services/*_foss.dart` 無操作版本 + 一支 `scripts/make_foss.sh`，
  F-Droid 的 prebuild 只要跑這支腳本即可
- [x] 版本號升到 `1.1.0+23`
- [x] 新 recipe 草稿：`docs/fdroid-build-recipe.yml`
- [ ] 打 tag `v1.1.0` 後提交到 fdroiddata

---

## 💡 額外建議（不在這次範圍，但值得考慮）

1. ~~**後端已失聯**~~：已移除 `server/`，「主題詞彙」改為透過 HTTPS 讀取 GitHub 上的
   `assets/dict/dict-list.json`，不用維護伺服器、社群也能透過 PR 新增主題。
2. **語音改 HTTPS**：`http://t.moedict.tw` 是明文；確認 `https://` 可用後就能拿掉 `usesCleartextTraffic`。
3. ~~**GitHub Actions CI**~~：已加入 `.github/workflows/ci.yml`。
4. **Material 3 改版**：遷移完成後可以開 `useMaterial3: true`，用 `ColorScheme.fromSeed` 搭配各分頁原本的主題色，外觀會現代很多。
5. **間隔重複（Spaced Repetition）**：`learnt` 現在只是次數；可以加一個「下次複習時間」欄位，做成 SM-2 之類的演算法，學習效果會好很多。
6. **深色模式**、**Web 版**（sqflite → drift 或 sqflite_common_ffi_web）也都是低成本就能加的功能。
