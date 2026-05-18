# 📍 Location Tracker

A Flutter locator  tracking app using [`flutter_background_geolocation`](https://pub.dev/packages/flutter_background_geolocation) by Transistor Software.

---

## Setup

### Prerequisites — Flutter Version Manager (FVM)

This project targets **Flutter 3.27.4**. Use [FVM](https://fvm.app) to pin the correct version:

```bash
fvm use 3.27.4          # pin Flutter 3.27.4 for this project
```

### 1. Install dependencies

```bash
fvm flutter clean       # clear any stale build artefacts
fvm flutter pub get     # install dependencies
```

### 2. Android — apply the plugin's Gradle script

`android/app/build.gradle` already contains the required lines:

```groovy
Project background_geolocation = project(':flutter_background_geolocation')
apply from: "${background_geolocation.projectDir}/background_geolocation.gradle"
```

This script injects all permissions and service declarations into the merged manifest automatically. **Do not add location permissions manually.**

`shrinkResources false` is set in the release build type — this is **required** by the plugin.

### 3. iOS — Xcode capability

In Xcode, select the Runner target → **Signing & Capabilities** → **+ Capability** → **Background Modes** → tick **Location updates**.

This must match `UIBackgroundModes: location` in `Info.plist` (already set).

### 4. Android release builds (optional)

Debug builds work without a license. For release builds, need to purchase a license at [transistorsoft.com](https://www.transistorsoft.com/shop/products/flutter-background-geolocation).

---

## Running

```bash
fvm flutter run               # debug — no license needed
fvm flutter build apk --debug # debug APK
```

---


## Why `flutter_background_geolocation`?

Most Flutter location plugins (`geolocator`, `background_locator_2`) rely on a raw Dart isolate for background work. That isolate **is not restarted by the OS** after the user terminates the app. The only reliable way to survive termination on both platforms is to hand off to a **native background service / CoreLocation monitor** — which is exactly what this plugin does.

| Scenario | `background_locator_2` | **`flutter_background_geolocation`** |
|---|---|---|
| Foreground | ✅ | ✅ |
| Background (minimised) | ✅ | ✅ |
| Terminated — Android | ⚠️ Unreliable on OEM devices | ✅ Native foreground service + boot receiver |
| Terminated — iOS (OS-killed) | ⚠️ Cell-tower only ~500 m | ✅ CoreLocation significant-change + visit monitoring |
| Terminated — iOS (user-killed) | ❌ | ❌ *(iOS platform limit — no app can survive this)* |
| Battery optimisation | ❌ None | ✅ Motion-detection stops GPS when stationary |
| OEM battery whitelist workaround | ❌ | ✅ Guidance built-in |

---

## Architecture

```
lib/
├── main.dart                              # Entry point — init prefs, provide cubits, run app
├── core/
│   ├── headless_task.dart                 # @pragma('vm:entry-point') Android terminated callback
│   ├── constants/app_constants.dart       # All magic values
│   ├── services/location_service.dart     # Plugin lifecycle + event → domain mapping
│   └── utils/app_theme.dart
└── features/location/
    ├── domain/location_entry.dart         # Immutable value object + JSON serialisation
    ├── data/location_log_repository.dart  # SharedPreferences persistence
    └── presentation/
        ├── cubit/
        │   ├── location_log_cubit.dart    # Log list — loads repo, subscribes to LocationService
        │   ├── location_log_state.dart
        │   ├── tracking_cubit.dart        # Start/stop tracking, isMoving reflection
        │   ├── tracking_state.dart
        │   ├── readiness_cubit.dart       # Permission + provider check (TrackingReadiness enum)
        │   └── readiness_state.dart
        ├── screens/home_screen.dart
        └── widgets/
            ├── current_location_card.dart
            ├── tracking_control_card.dart
            └── location_log_list.dart
```

### Key design decisions

- **`flutter_bloc` Cubits** for all state — three cubits provided via `MultiBlocProvider` in `main()`: `LocationLogCubit`, `TrackingCubit`, and `ReadinessCubit`. All states use `sealed class` + `Equatable`.
- **`LocationService`** is a pure Dart class with no Flutter dependency, making it independently testable.
- **Two persistence paths** intentionally coexist:
  - The plugin's internal SQLite database (full history, queryable via `bg.BackgroundGeolocation.locations`)
  - Our `SharedPreferences` log (lightweight, for UI display, pruned to 500 entries)
- **Headless task** (`headless_task.dart`) runs in a separate Dart isolate on Android when the app is terminated. It calls `SharedPreferences.getInstance()` fresh (no shared memory across isolates).

---



## How Terminated-State Tracking Works

### Android

1. `enableHeadless: true` in the plugin config registers `backgroundGeolocationHeadlessTask` (in `headless_task.dart`) as the callback for a separate Dart isolate.
2. `stopOnTerminate: false` tells the plugin's native Android foreground service to **keep running** after the Flutter engine is torn down.
3. `startOnBoot: true` registers a `BootBroadcastReceiver` (injected by the gradle script) that restarts the service after a device reboot.
4. The native service delivers location events to the headless Dart isolate, which writes them to `SharedPreferences`. When the app is reopened, the log is loaded and displayed.

### iOS

1. `UIBackgroundModes: location` + the Xcode capability allow CoreLocation to keep the location manager active.
2. `stopOnTerminate: false` configures the plugin to use **Significant Location Change** monitoring after the app is terminated. This wakes the app process when the device moves ~500 m.
3. If the OS (not the user) killed the app due to memory pressure, CoreLocation will relaunch the app silently in the background. `main()` runs again, the plugin reinitialises, and the fix is recorded.
4. **If the user force-quits the app** (swipe up in the app switcher), iOS suspends all background activity for that app. This is an Apple platform policy — no SDK can work around it. Document this clearly to the user.

---

## Testing Background Tracking

1. Grant **"Always"** location permission when prompted.
2. Toggle **Background Tracking** ON.
3. **Background test:** press Home → lock the screen → walk around. The persistent notification should update.
4. **Terminated test (Android):** swipe the app from recents. Wait ~1 minute. Reopen — new entries should appear tagged "Background".
5. **Terminated test (iOS):** press Home (don't swipe up). Walk 500+ metres. Reopen the app — the OS will have relaunched it and entries will appear.
6. **Reboot test:** reboot the device. After boot, open the app — tracking should have resumed automatically (`startOnBoot: true`).

---

## iOS Limitation Disclosure

> **User-terminated apps on iOS cannot be tracked.** If the user explicitly force-quits the app (swipe up in the multitasking view), iOS will not relaunch it for any reason. This is an Apple-enforced platform constraint, not a plugin or code limitation. The correct UX is to inform users of this during onboarding and advise them not to force-quit the app while tracking is needed.
