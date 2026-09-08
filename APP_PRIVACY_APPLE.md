# Apple App Privacy

Date: 2026-09-06 (supersedes the 2026-04-22 revision)

This document translates the repository audit into Apple App Privacy answers for
App Store Connect.

Supporting technical reference:
[DATA_FLOW.md](./DATA_FLOW.md)

Implementation references:

- `ios/Runner/PrivacyInfo.xcprivacy`
- `macos/Runner/PrivacyInfo.xcprivacy`

## Apple App Privacy Answers

### App Store Connect summary answers

- Data Used to Track You: No
- Data Linked to You: None
- Data Not Linked to You: None
- Does this app collect data: No

### Tracking

- Tracking: No
- Third-party advertising or attribution SDKs: None found
- Device identifier collection for tracking: None found

## Data Not Collected Declaration

Recommended App Privacy label: **Data Not Collected**

Turing Lab currently qualifies for that status because:

- No data is collected by the developer.
- No user data is transmitted to developer-controlled servers.
- No third-party analytics or crash-reporting SDKs were found.
- No user-tracking SDKs or tracking identifiers were found.
- App persistence is local-only: settings, simulation traces, the active editor session and teaching-session data stay in on-device `SharedPreferences`.
- Imports and exports are user-initiated file operations, not backend uploads.

Important nuance:

- The user may choose a cloud-backed Files provider such as iCloud Drive when
  importing or exporting files.
- That is a user-managed file-location choice, not developer-operated data
  collection by the app.

## Data Type Categories

Each Apple App Privacy data type category below is currently **Not Collected**.

### Contact Info

- Name: Not Collected
- Email Address: Not Collected
- Phone Number: Not Collected
- Physical Address: Not Collected
- Other User Contact Info: Not Collected

### Health and Fitness

- Health: Not Collected
- Fitness: Not Collected

### Financial Info

- Payment Info: Not Collected
- Credit Info: Not Collected
- Other Financial Info: Not Collected

### Location

- Precise Location: Not Collected
- Coarse Location: Not Collected

### Sensitive Info

- Sensitive Info: Not Collected

### Contacts

- Contacts: Not Collected

### User Content

- Emails or Text Messages: Not Collected
- Photos or Videos: Not Collected
- Audio Data: Not Collected
- Gameplay Content: Not Collected
- Customer Support: Not Collected
- Other User Content: Not Collected

Note:

- The app can import and export user-selected documents through the system
  file picker for every supported formal system: finite automata, context-free
  and unrestricted grammars, pushdown automata, Turing machines, regular
  expressions, Pumping Lemma problems, Mealy and Moore machines, and
  L-systems. The formats are JFLAP XML (`.jff`/`.cfg`), Turing Lab JSON, SVG
  and PNG; not every system supports every format, and the per-system table
  is in [DATA_FLOW.md](./DATA_FLOW.md).
- Those files are not collected by the developer or transmitted to a backend.

### Browsing History

- Browsing History: Not Collected

### Search History

- Search History: Not Collected

### Identifiers

- User ID: Not Collected
- Device ID: Not Collected
- Purchase ID: Not Collected

### Usage Data

- Product Interaction: Not Collected
- Advertising Data: Not Collected
- Other Usage Data: Not Collected

### Diagnostics

- Crash Data: Not Collected
- Performance Data: Not Collected
- Other Diagnostic Data: Not Collected

Note:

- The codebase contains local `debugPrint` and `print` statements only.
- No log-upload, telemetry, analytics, or crash-reporting pipeline was found.

### Surroundings

- Surroundings: Not Collected

### Body

- Body: Not Collected

### Other Data

- Other Data Types: Not Collected

## Rationale

Turing Lab is currently an offline-only educational app:

- Settings are stored locally in `SharedPreferences`.
- Simulation traces are stored locally in `SharedPreferences`.
- The active editor session (the latest document of each formal system plus
  annotations) is stored locally in `SharedPreferences` while Auto Save is
  enabled and restored on cold start; disabling Auto Save clears it.
- Grammar teaching and manual conversion sessions are stored locally in
  `SharedPreferences`.
- Bundled examples are loaded from app assets.
- File import/export happens only through user-initiated system picker flows.
- No repository code sends content, identifiers, or diagnostics to a network service.

That architecture supports a defensible `Data Not Collected` declaration for
Apple review.

## Evidence Summary

- `pubspec.yaml` contains local-storage and file-picker packages, but no analytics/crash SDKs.
- `lib/` contains `SharedPreferences` usage for settings, traces, the active editor session and teaching sessions only; there is no other storage backend.
- `lib/` contains file-picker-based import/export flows for `.jff`, `.cfg`, `.json`, `.svg`, and `.png` across all registered formal systems.
- `ios/Runner/Info.plist` contains no privacy-sensitive usage-description keys.
- `ios/Runner/PrivacyInfo.xcprivacy` and `macos/Runner/PrivacyInfo.xcprivacy`
  declare app-level `UserDefaults` and file-metadata usage for local-only
  storage and document flows.
- `ios/Podfile` disables `file_picker` media/audio support because Turing Lab
  ships document import/export only on iOS.

## Suggested Reviewer Note

Suggested App Review note:

> Turing Lab is an offline educational automata tool. It stores settings, simulation traces, the current editor session and in-progress teaching exercises (grammar normalization, parse-table and manual-conversion sessions) locally on-device, loads bundled examples from app assets, and supports user-initiated import/export through the system file picker. It does not use analytics, crash reporting, accounts, ads, tracking, or developer-operated network services.

Current Apple submission note update:

> The iOS build disables unused media and audio picker support from `file_picker`. Turing Lab ships document import/export only, with local preferences storage and no camera, microphone, or photo-library workflow exposed to users.

## Maintenance Trigger

Update this document and App Store Connect answers before submission if any of
the following are added:

- Analytics or crash reporting
- Account creation or sign-in
- Cloud sync or backend storage
- Direct networking for telemetry, content fetches, or uploads
- Advertising, attribution, or tracking SDKs
- Device identifier reads
- Sharing features that hand data to third-party services in a way Apple treats as collection
