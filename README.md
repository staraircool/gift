# GIFTDROP

Neubrutalism-inspired Flutter experience for tracking crypto airdrop campaigns. The app ships with Firebase-ready data services, vivid UI, and sample content for the `Featured`, `Latest`, and `Ended` feeds.

## Highlights

- Tabbed layout for Featured, Latest, and Ended airdrops with snappy neubrutal cards.
- Firebase integration via `firebase_core` and `cloud_firestore`, with graceful fallback to sample data when Firebase is not configured.
- Dedicated detail screen outlining "How to join" steps and deep links for brand-specific landing pages.
- Reusable theming helpers for bold outlines, shadows, and modern buttons consistent with neubrutalism aesthetics.

## Requirements

- Flutter 3.9.2 (or newer compatible stable channel)
- Dart SDK 3.9.2+
- Firebase project capable of Firestore usage

## Setup

1. Install Flutter dependencies:
	```powershell
	flutter pub get
	```
2. Configure Firebase (once per environment):
	- Install the FlutterFire CLI if necessary: `dart pub global activate flutterfire_cli`.
	- Run `flutterfire configure` and select the Firebase project you want to link.
	- Replace the placeholder values inside `lib/firebase_options.dart` with the generated configuration.
3. Update platform identifiers if required:
	- Android `applicationId`: `android/app/build.gradle.kts` is already set to `com.giftdrop.app`.
	- iOS/macOS bundle identifier: `com.giftdrop.app` defined in `ios/Runner.xcodeproj`.
4. Launch the application:
	```powershell
	flutter run
	```

## Firebase Data Model

Create a Cloud Firestore collection named `airdrops` with documents resembling:

```json
{
  "name": "Galaxy Gift Drop",
  "amountUsdt": 1200,
  "category": "featured",
  "joinUrl": "https://example.com/airdrops/galaxy-gift",
  "network": "Arbitrum",
  "deadline": "2025-11-30",
  "description": "Top community members share a 1,200 USDT prize pool.",
  "requirements": [
	 "Hold at least 250 GALX in your wallet.",
	 "Stake GALX in the loyalty vault for 14 days.",
	 "Submit your wallet address via the Galaxy Airdrop portal."
  ],
  "priority": 10
}
```

- `category` must be one of `featured`, `latest`, or `ended` to map to the tabs.
- `priority` (higher = nearer to top) is optional but recommended.
- Dates can be ISO strings (YYYY-MM-DD) or Firestore `Timestamp` values.

If Firestore is unavailable, the app automatically falls back to curated sample data shipped with the repository.

## Development Tips

- Run `flutter analyze` and `dart format lib` before committing changes.
- Use `flutter test` to execute widget tests (`test/widget_test.dart`).
- Customize colors, spacings, and assets in `lib/main.dart` for brand alignment.
- Replace placeholder Firebase keys in `lib/firebase_options.dart` before production release.
