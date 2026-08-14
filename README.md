# MediastreamPlatformSDKiOS — Swift Package

Swift Package Manager distribution for the Mediastream Platform SDK for iOS.

This repository holds only the package manifest. The SDK ships as a precompiled
XCFramework hosted on Mediastream's CDN; the source lives in a private repository.

## Installation

In Xcode: **File → Add Package Dependencies…**, then paste this repository's URL.

Or in a `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/mediastream/MediastreamPlatformSDKiOS-spm.git",
    from: "5.1.0"
  )
]
```

Then:

```swift
import MediastreamPlatformSDKiOS
```

Requires **iOS 12.0** or later and Xcode 15 or later.

## What this package pulls in

| Dependency | Version | Source |
|---|---|---|
| GoogleInteractiveMediaAds | 3.24.0 (exact) | github.com/googleads |
| YouboraAVPlayerAdapter | 6.7.5 (exact) | github.com/NPAW |
| YouboraLib | 6.7.x | bitbucket.org/npaw (transitive) |
| ComScore | 6.17.0+ | github.com/comScore |

`AdSupport` is linked for you. If your app presents the App Tracking Transparency
prompt, link `AppTrackingTransparency` in your own target.

If your build environment restricts outbound git access, allow **bitbucket.org** —
NPAW distributes YouboraLib from there.

## Coming from CocoaPods

`MediastreamPlatformSDKxC` 5.0.1 is the last release published to CocoaPods. New
versions ship through this package only.

1. Remove `pod 'MediastreamPlatformSDKxC'` from your Podfile and run `pod install`.
2. Add this package as shown above.
3. No code changes — the public API and `import MediastreamPlatformSDKiOS` are unchanged.

The Google Cast SDK has no official Swift Package. If your app uses Chromecast, keep
`google-cast-sdk` on CocoaPods (both dependency managers coexist in one project) or add
the Cast `.xcframework` manually.

## Pre-release builds

QA versions (e.g. `5.2.0-qa.01`) need an exact version pin — Swift Package Manager does
not select pre-releases from version ranges.

## Documentation

Integration guides live in the SDK repository, including the
[Cast integration guide](https://github.com/mediastream/MediastreamPlatformSDKiOS/blob/master/CAST_INTEGRATION.md).
