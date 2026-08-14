# Google Cast Integration Guide

> **Swift Package Manager:** the Google Cast SDK has no official Swift Package.
> Apps consuming Mediastream through SPM must keep `google-cast-sdk` on CocoaPods —
> both managers coexist in one project — or add the Cast `.xcframework` manually.
> See the [README](README.md).

This document describes how to integrate **Google Cast** (Chromecast) with the Mediastream Platform SDK for iOS. The SDK does **not** include the Cast SDK; your app must add the Google Cast dependency and implement session handling. The SDK provides a **casting mode** and **events** so that playback controls (play, pause, seek, forward, backward, volume) can be forwarded to the Cast device.

---

## Table of contents

1. [Overview](#overview)
2. [What the SDK provides](#what-the-sdk-provides)
3. [What your app must implement](#what-your-app-must-implement)
4. [Integration steps](#integration-steps)
5. [Casting mode API](#casting-mode-api)
6. [Events in casting mode](#events-in-casting-mode)
7. [Timeline and UI sync](#timeline-and-ui-sync)
8. [Checklist](#checklist)

---

## Overview

- **SDK role:** The SDK plays media locally and exposes a **casting mode**. When casting mode is enabled, user actions (play, pause, seek, forward, backward, volume) **only emit events** and do not control the local AVPlayer. Your app listens to these events and forwards the corresponding commands to the Cast device.
- **App role:** Your app integrates the **Google Cast SDK**, manages the Cast session (connect, disconnect, load media), and forwards the SDK events to Cast. You also sync the local player UI with the Cast state (e.g. play/pause icon, timeline position) when needed.

---

## What the SDK provides

| Feature | Description |
|--------|-------------|
| **Cast URL** | `castUrl` — URL for the current media (e.g. MP4) suitable for loading on the Cast device. Available after media is loaded. |
| **Cast button** | `showCastButton` and `useCustomCastButton` in `MediastreamPlayerConfig` — show the SDK’s default Cast button or inject your own. |
| **Casting mode** | `isCastingModeEnabled` and `setCastingModeEnabled(_:)` — when enabled, play/pause only emit events and the local player stays paused. |
| **Events** | In casting mode, the SDK emits: `play`, `pause`, `seek`, `forward`, `backward`, `volume`. Your app forwards these to the Cast session. |
| **Timeline** | `seekTo(_:)` is **not** disabled in casting mode. You can call it to sync the local timeline with the Cast `streamPosition` (e.g. from `GCKMediaStatus.streamPosition`). |

The SDK does **not** depend on or include the Google Cast framework. You add it to your app (e.g. via CocoaPods) and implement all Cast session and media logic.

---

## What your app must implement

1. **Add Google Cast SDK**
   Add the Cast SDK to your project (e.g. `pod 'GoogleCast'` or the appropriate Cast pod).

2. **Initialize Cast context**
   Configure and start the Cast context (e.g. `GCKCastContext.sharedInstance()`).

3. **Cast button**
   Use `showCastButton = true` and optionally `useCustomCastButton` to show a Cast button. Handle the tap (e.g. present device picker or load media when a session is started).

4. **Session lifecycle**
   - When a Cast **session starts**: call `sdk.setCastingModeEnabled(true)`, load media with `sdk.castUrl` if available, and register for `GCKRemoteMediaClient` updates.
   - When the session **ends** or **suspends**: call `sdk.setCastingModeEnabled(false)`, optionally restore playback position with `sdk.seekTo(position)`, then `sdk.play()`.

5. **Event forwarding**
   Subscribe to SDK events (`play`, `pause`, `seek`, `forward`, `backward`, `volume`) and map them to Cast API calls (see [Events in casting mode](#events-in-casting-mode)).

6. **UI sync with Cast**
   - **Play/Pause:** When you receive `GCKMediaStatus` updates, sync the play/pause icon (e.g. call `sdk.play()` or `sdk.pause()` only to update UI; use a flag so you don’t re-forward these to Cast).
   - **Timeline:** Periodically (e.g. in `remoteMediaClient(_:didUpdate:mediaStatus:)`) set `sdk.seekTo(mediaStatus.streamPosition)` so the local scrubber matches Cast position.
   - **Volume:** Optionally sync Cast device volume back to the SDK if needed (the SDK emits `volume` when the user changes the in-app volume slider).

---

## Integration steps

### 1. Player configuration

```swift
let config = MediastreamPlayerConfig()
config.id = "your-content-id"
config.type = .VOD
config.showCastButton = true
config.useCustomCastButton = myCastButton  // optional: use your own button

let sdk = MediastreamPlatformSDK()
sdk.setup(config)
```

### 2. When the user taps Cast and a session starts

- Show your “casting” UI (e.g. banner “Casting to [device name]”).
- Call `sdk.setCastingModeEnabled(true)`.
- Load media on the Cast device using `sdk.castUrl` (e.g. `GCKMediaInformationBuilder(contentURL: URL(string: sdk.castUrl)!)` and `session.remoteMediaClient?.loadMedia(_:with:)`).
- Add your view controller as listener of `session.remoteMediaClient` to receive `didUpdate mediaStatus`.

### 3. When the Cast session ends

- Call `sdk.setCastingModeEnabled(false)`.
- Optionally: read final position from `mediaStatus.streamPosition`, then `sdk.seekTo(position)` and `sdk.play()` to resume locally.

### 4. Subscribe to SDK events and forward to Cast

Register once (e.g. after creating the SDK):

```swift
sdk.events.listenTo(eventName: "play") { _ in
    guard let session = currentCastSession else { return }
    session.remoteMediaClient?.play()
}

sdk.events.listenTo(eventName: "pause") { _ in
    guard let session = currentCastSession else { return }
    session.remoteMediaClient?.pause()
}

sdk.events.listenTo(eventName: "seek") { info in
    guard let session = currentCastSession,
          let dict = info as? [String: Any],
          let pos = dict["position"] as? Double else { return }
    let options = GCKMediaSeekOptions()
    options.interval = pos
    options.relative = false
    session.remoteMediaClient?.seek(with: options)
}

sdk.events.listenTo(eventName: "forward") { info in
    guard let session = currentCastSession,
          let dict = info as? [String: Any],
          let interval = dict["interval"] as? Double else { return }
    let targetPos = currentCastPosition + interval
    let options = GCKMediaSeekOptions()
    options.interval = targetPos
    options.relative = false
    session.remoteMediaClient?.seek(with: options)
}

sdk.events.listenTo(eventName: "backward") { info in
    guard let session = currentCastSession,
          let dict = info as? [String: Any],
          let interval = dict["interval"] as? Double else { return }
    let targetPos = max(0, currentCastPosition - interval)
    let options = GCKMediaSeekOptions()
    options.interval = targetPos
    options.relative = false
    session.remoteMediaClient?.seek(with: options)
}

sdk.events.listenTo(eventName: "volume") { info in
    guard currentCastSession != nil,
          let dict = info as? [String: Any],
          let vol = dict["volume"] as? Int else { return }
    let volNorm = Float(max(0, min(100, vol))) / 100.0
    GCKUIDeviceVolumeController().setVolume(volNorm)
}
```

Keep `currentCastPosition` in sync with `GCKMediaStatus.streamPosition` in your `remoteMediaClient(_:didUpdate:mediaStatus:)` callback.

---

## Casting mode API

| API | Description |
|-----|-------------|
| `isCastingModeEnabled: Bool` | Indicates whether casting mode is on. Read-only from the SDK’s public API. |
| `setCastingModeEnabled(_ enabled: Bool)` | Turns casting mode on or off. When you pass `true`, the SDK pauses the local player (and ad playback if active) so that only Cast controls playback. |

**When to call:**

- **Enable:** When a Cast session has started (or when the user enters a screen that already has an active session).
- **Disable:** When the Cast session ends or is suspended.

Casting mode is reset to `false` when the player is released (`releasePlayer()`).

---

## Events in casting mode

When `isCastingModeEnabled` is `true`, the following user actions **only emit events** (and update local UI state where applicable); they do **not** change local AVPlayer playback.

| Event | When it fires | Payload | App action |
|-------|----------------|---------|------------|
| `play` | User taps play | — | `remoteMediaClient?.play()` |
| `pause` | User taps pause | — | `remoteMediaClient?.pause()` |
| `seek` | User drags timeline slider | `["position": Double]` (seconds) | Seek Cast to `position` (absolute). |
| `forward` | User taps forward (e.g. +10 s) | `["interval": Double]` (seconds) | Seek Cast to `currentPosition + interval`. |
| `backward` | User taps backward (e.g. -10 s) | `["interval": Double]` (seconds) | Seek Cast to `max(0, currentPosition - interval)`. |
| `volume` | User changes volume slider | `["volume": Int]` (0–100) | `GCKUIDeviceVolumeController().setVolume(volume / 100.0)`. |

- **Timeline:** The SDK still performs the local seek when the user drags the slider (so the scrubber moves immediately). Your app uses the `seek` event to seek on Cast.
- **Forward/Backward:** The SDK still seeks locally; the app uses the event to seek on Cast using the same interval (e.g. 10 seconds).
- **Volume:** The SDK still updates local volume and UI; the app uses the event to set the Cast device volume.

---

## Timeline and UI sync

- **Position:** In `GCKRemoteMediaClientListener.remoteMediaClient(_:didUpdate:mediaStatus:)`, read `mediaStatus.streamPosition` and call `sdk.seekTo(streamPosition)` (possibly throttled) so the SDK’s timeline and scrubber match the Cast playback position.
- **Play/Pause icon:** When you receive a media status update, you can call `sdk.play()` or `sdk.pause()` **only to update the SDK’s play/pause button**. Use a flag (e.g. “syncing from Cast”) so your event listeners do **not** forward these programmatic play/pause calls to Cast, to avoid duplicate or conflicting commands.

---

## Checklist

- [ ] Add Google Cast SDK to the app.
- [ ] Initialize Cast context and show Cast button (SDK config: `showCastButton`, optional `useCustomCastButton`).
- [ ] On Cast session start: `setCastingModeEnabled(true)`, load media with `castUrl`, register for `remoteMediaClient` updates.
- [ ] On Cast session end/suspend: `setCastingModeEnabled(false)`, restore position with `seekTo` + `play()` if desired.
- [ ] Subscribe to SDK events: `play`, `pause`, `seek`, `forward`, `backward`, `volume` and forward to Cast as described above.
- [ ] In `didUpdate mediaStatus`: sync timeline with `seekTo(streamPosition)` and optionally sync play/pause UI (without re-forwarding to Cast).
- [ ] Handle “ready” if needed: when the SDK emits `ready` and a Cast session is already active, enable casting mode and optionally pause locally (e.g. in a deferred block so it runs after any autoplay).
