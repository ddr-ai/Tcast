# Tcast

Lightweight multi-tab iOS web browser that discovers and casts media to the receivers available on iOS: Chromecast, DLNA/UPnP, and AirPlay.

Designed for sideloading. Best match for the wireless HDMI adapter (AirPlay + Miracast) is AirPlay from this app or system Screen Mirroring.

## Protocol coverage on iOS

| Protocol | Discovery | Casting | Notes |
|----------|-----------|---------|-------|
| **Chromecast / Google Cast** | Yes (Bonjour `_googlecast._tcp`) | Yes (SwiftCast) | Direct media URL preferred |
| **DLNA / UPnP MediaRenderer** | Yes (SSDP) | Yes (UPnPCast) | Requires multicast entitlement for reliable discovery on iOS |
| **AirPlay** | Yes (system) | Yes (AVRoutePickerView + system) | Primary path for wireless HDMI adapters |
| **Miracast** | No public API | No | iOS has no Miracast sender. Adapters that support both use AirPlay |

The app scans for Chromecast and DLNA devices and embeds the system AirPlay picker so you can select any AirPlay receiver (including your adapter) from inside the app.

## Features

- Multiple tabs with create / close
- Smart search/URL bar
- Full webpage video playback (WKWebView)
- Back / forward
- Long-press on links / images / videos → Open in New Tab (and switch)
- Device discovery + cast:
  - Chromecast
  - DLNA / UPnP
  - AirPlay (in-app picker + Control Center)
- Prefers extracted video URL over page URL when casting

## Important notes

- **Miracast**: No public Miracast sender API exists on iOS. Use AirPlay or Control Center → Screen Mirroring for adapters that advertise both.
- **DLNA**: Discovery needs the `com.apple.developer.networking.multicast` entitlement. Free personal accounts often cannot enable it; a paid Apple Developer account is recommended for reliable SSDP.
- Local Network permission is required on first launch.

## Building / Sideloading

GitHub Actions builds an unsigned `.ipa`.

1. Download the IPA artifact from a successful Actions run.
2. Resign and install with Sideloadly, AltStore, SideStore, or Xcode.
3. On device: Settings → Privacy & Security → Local Network → allow Tcast.

## Project generation

Uses [xcodegen](https://github.com/yonaskolb/XcodeGen). `project.yml` is the source of truth.

## Dependencies

- [SwiftCast](https://github.com/CreatureSurvive/SwiftCast) — pure-Swift Chromecast
- [UPnPCast](https://github.com/CreatureSurvive/UPnPCast) — pure-Swift DLNA/UPnP
