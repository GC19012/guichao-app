<div align="center">

<a href="https://apps.apple.com/app/id6759786349">
  <img width="100" height="100" alt="GUICHAO" src="docs/assets/app-icon.png" />
</a>

# GUICHAO

**Secure & Private Network Acceleration for Global Users**

Built for students and travelers abroad who need a stable, low-latency
connection back to the services they rely on at home. Sign in, pick a
profile, tap connect. That's it.

<a href="https://apps.apple.com/app/id6759786349">
  <img src="https://img.shields.io/badge/Download_on_the-App_Store-black?style=for-the-badge&logo=apple&logoColor=white" alt="Download on the App Store" />
</a>
<a href="https://play.google.com/store/apps/details?id=com.guichaovpn.app">
  <img src="https://img.shields.io/badge/Get_it_on-Google_Play-black?style=for-the-badge&logo=googleplay&logoColor=white" alt="Get it on Google Play" />
</a>

[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg?style=flat-square)](#download)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.24.0-02569B.svg?style=flat-square&logo=flutter&logoColor=white)](pubspec.yaml)

</div>

---

## Why GUICHAO?

Most networking apps make you fight with configuration files and technical
jargon before you can get online. GUICHAO strips that away: it's a native
iOS app built with Flutter, backed by a system-level Network Extension and
a lightweight account/subscription backend, so the whole experience is one
tap to connect and one tap to disconnect.

The tunneling core is powered by [**sing-box**](https://github.com/SagerNet/sing-box),
the open-source, GPL-3.0-licensed universal proxy platform. This client — and its
open-source release — exists in large part to satisfy sing-box's copyleft
license: since GUICHAO links against sing-box, GUICHAO's own source is made
available here under the same GPL-3.0 terms. See [Acknowledgements](#acknowledgements)
below and the [LICENSE](LICENSE) file for details.

## Features

| | |
|---|---|
| 🔌 **One-tap connect** | Home screen shows connection status at a glance — connect or disconnect instantly. |
| 🛡️ **sing-box powered tunneling** | System-level tunneling via Apple's `NetworkExtension` framework, backed by the [sing-box](https://github.com/SagerNet/sing-box) core. No jailbreak required. |
| 🗂️ **Node/profile management** | Subscribe to and switch between multiple server profiles. |
| 👤 **Account system** | Registration/login backed by Supabase Auth, with optional SMS/email verification. |
| 💳 **In-app subscription** | App Store In-App Purchase integration for paid plans. |
| 🌐 **Bilingual UI** | Chinese/English support out of the box. |

## Getting Started

### Prerequisites

- Flutter SDK `>=3.24.0` (Dart `>=3.3.0`)
- Xcode with CocoaPods installed
- A physical iOS device or simulator running a supported iOS version

### Build from Source

```bash
git clone https://github.com/GC19012/guichao-app.git
cd guichao-app

# Fetch Flutter dependencies
flutter pub get

# Install iOS native dependencies
cd ios
pod install
cd ..

# Open the workspace in Xcode
open ios/Runner.xcworkspace
```

From Xcode, select the `Runner` scheme and a target device, then build and run.

> **Note:** This is the open-source snapshot of the app's client code. Backend
> endpoints, captcha keys, and Apple Developer identifiers referenced in the
> source have been replaced with placeholders (e.g. `api.example.com`,
> `YOUR_TEAM_ID`) — you'll need your own backend and Apple Developer account
> configuration for a fully working build.

## Project Structure

The app follows a feature-module layout under `lib/`:

```
lib/
├── gch_base/        # Core infrastructure: storage (Drift/SQLite), networking, auth, global config
├── gch_mod/         # Feature modules: account, settings, node/profile management, IAP, support
└── gch_bootstrap.dart  # App startup/bootstrap sequence

ios/                 # Native iOS project, Network Extension target, CocoaPods configuration
```

## Acknowledgements

GUICHAO stands on the shoulders of the projects that do the real networking
work:

- [**sing-box**](https://github.com/SagerNet/sing-box) — the core proxy/tunneling engine used under the hood.
- [sing-geoip](https://github.com/SagerNet/sing-geoip) / [sing-geosite](https://github.com/SagerNet/sing-geosite) — geo routing data.

Huge thanks to the SagerNet team and everyone who maintains them.

## Contributing

Issues and pull requests are welcome. Please keep changes focused and avoid
introducing hardcoded secrets or endpoints — follow the existing placeholder
configuration pattern in `lib/gch_base/gch_core/gch_nucleus.dart`.

## License

This project is licensed under the **GNU General Public License v3.0** — see
[LICENSE](LICENSE) for details.

## Download

- **iOS**: [App Store](https://apps.apple.com/app/id6759786349)
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=com.guichaovpn.app)

> This repository contains the **iOS client source only** (see [Getting Started](#getting-started)
> above). The Android app shares the same product but is built from a
> separate codebase not included here.

---

<div align="center">

If you find this project useful, consider giving it a ⭐️

</div>
