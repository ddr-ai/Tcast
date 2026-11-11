# Tcast

Lightweight multi-tab iOS web browser with media casting to Chromecast, DLNA/UPnP, and AirPlay devices.

Designed for sideloading with a personal developer certificate. The purchased wireless HDMI adapter (AirPlay/Miracast) is best used via AirPlay from this app or system Screen Mirroring.

## Features

- Multiple tabs with create / close
- Smart search/URL bar (any input)
- Full webpage video playback (WKWebView)
- Back / forward navigation
- Long-press context menu on links / images / videos → Open in New Tab (and switch immediately)
- Device discovery + cast for:
  - Chromecast / Google Cast (SwiftCast)
  - DLNA / UPnP MediaRenderers (UPnPCast)
  - AirPlay (native AVRoutePicker)
- Video URL extraction for direct media casting

## Important notes on casting

- **Miracast**: iOS does not provide a public Miracast sender API. The hardware adapter supports both AirPlay and Miracast; use AirPlay or system Screen Mirroring. Pure Miracast discovery/casting from third-party iOS apps is not practical with public APIs.
- **DLNA discovery** requires the `com.apple.developer.networking.multicast` entitlement. Free personal developer accounts often cannot enable this; a paid Apple Developer account is recommended for reliable SSDP.
- Local Network permission must be granted on first launch.

## Building / Sideloading

GitHub Actions produces an unsigned `.ipa` artifact.

1. Download the IPA from the successful Actions run.
2. Resign and install with Sideloadly, AltStore, SideStore, or Xcode (your personal certificate).
3. On device: Settings → Privacy & Security → Local Network → allow Tcast.

## Project generation

Uses [xcodegen](https://github.com/yonaskolb/XcodeGen). `project.yml` is the source of truth.

## Dependencies

- [SwiftCast](https://github.com/CreatureSurvive/SwiftCast) — pure-Swift Chromecast
- [UPnPCast](https://github.com/CreatureSurvive/UPnPCast) — pure-Swift DLNA/UPnP
