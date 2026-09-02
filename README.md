# MediastreamPlatformSDKiOS — Swift Package

Swift Package Manager distribution for the Mediastream Platform SDK for iOS.

This repository holds only the package manifest. The SDK ships as a precompiled
XCFramework hosted on Mediastream's CDN; the source lives in a private repository.

Requires **iOS 13.0** or later and **Xcode 16** or later. Both floors come from the EaseLive
dependency that powers PlayAnywhere: its package declares `.iOS(.v13)`, and its manifest is
`swift-tools-version:6.0`, which Xcode 15 cannot read — on an older toolchain the whole
dependency graph fails to resolve, not just the EaseLive part. Up to `5.2.0` the floors were
iOS 12.0 and Xcode 15.

## Xcode

**File → Add Package Dependencies…**, paste:

```
https://github.com/mediastream/MediastreamPlatformSDKiOS-spm.git
```

Choose **Up to Next Major Version** from `6.0.0` and add the `MediastreamPlatformSDKiOS`
product to your app target.

## Package.swift

```swift
dependencies: [
  .package(
    url: "https://github.com/mediastream/MediastreamPlatformSDKiOS-spm.git",
    from: "6.0.0"
  )
]
```

Then:

```swift
import MediastreamPlatformSDKiOS
```

## Migrating from CocoaPods

`MediastreamPlatformSDKxC` **5.0.1 is the last version published to CocoaPods.** New
versions ship through the Swift package only. Versions already on trunk stay installable
forever, but they will not receive fixes.

1. Remove `pod 'MediastreamPlatformSDKxC'` from your Podfile and run `pod install`.
2. Add the package as shown above.
3. **No code changes.** The public API and `import MediastreamPlatformSDKiOS` are unchanged.

Both dependency managers can coexist in the same project, which matters if you use
Chromecast — see below.

## What the package pulls in

| Dependency | You get | Notes |
|---|---|---|
| GoogleInteractiveMediaAds | `3.24.0` up to but not including `3.28.0` | The upper bound is a platform boundary, not a preference: from 3.28 the package requires iOS 15 |
| YouboraLib | `6.7.x` from `6.7.23` | Distributed by NPAW from **bitbucket.org** |
| ComScore | `6.17.x` | |
| EaseLiveSDK | `2.29.x` from `2.29.0` | Powers PlayAnywhere. Downloaded from **sdk.easelive.tv**; sets the iOS 13 and Xcode 16 floors |

`AdSupport` is linked for you. If your app shows the App Tracking Transparency prompt,
link `AppTrackingTransparency` in your own target — the SDK does not do it for you.

**If your build environment restricts outbound access, allow `bitbucket.org`,
`github.com/ease-live` and `sdk.easelive.tv`.** NPAW distributes YouboraLib from Bitbucket and
EaseLive ships its binary from its own CDN; both are transitive dependencies you cannot avoid.

### Why the versions you resolve may differ from the ones we built against

The SDK is compiled against the **lowest** version of each range and runs against whatever
your project resolves, which is usually the highest. That direction is deliberate: building
against the lowest guarantees we never call an API missing from a version you might
resolve, while running against a newer one is safe because these SDKs add rather than
remove. See the compatibility table below for the exact versions per release.

## Chromecast

The Google Cast SDK **has no official Swift Package.** If your app uses Chromecast:

- keep `google-cast-sdk` on CocoaPods — it coexists with SPM in the same project; or
- add the Cast `.xcframework` manually.

Integration details: [`CAST_INTEGRATION.md`](CAST_INTEGRATION.md).

## Pre-release channels

Two channels exist besides production. **A version range never resolves them** — a
dependency declared as `from: "6.0.0"` will never pick up a `-dev` or `-rc` build, so they
cannot reach you by accident. They have to be requested by name:

```swift
// a specific release candidate, for validating before it ships
.package(url: "…-spm.git", exact: "5.2.0-rc.3")

// the newest development build, for internal apps only
.package(url: "…-spm.git", branch: "develop")
```

`-rc` builds are candidates that passed QA. `-dev` builds are throwaway and carry no
guarantee at all.

## Reporting a problem

Include your **`Package.resolved`**. It records exactly which versions of the SDK and of
its dependencies your app resolved, which is the first thing needed to tell a real bug
apart from a combination outside the tested set.

Find it at:

```
YourApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

## Compatibility per release

Versions each release was **built against**, and the ranges a consumer may resolve.

| SDK | iOS | IMA (built / allowed) | YouboraLib (built / allowed) | ComScore (built / allowed) | EaseLiveSDK (built / allowed) |
|---|---|---|---|---|---|
| 5.1.0 | 12.0+ | 3.24.0 / `3.24.0 ..< 3.28.0` | 6.7.23 / `6.7.x` | 6.17.0 / `6.17.x` | — |
| 6.0.0 | 13.0+ | 3.24.0 / `3.24.0 ..< 3.28.0` | 6.7.23 / `6.7.x` | 6.17.0 / `6.17.x` | 2.29.0 / `2.29.x` |

Anything outside these ranges is untested. A minor bump of a dependency is validated and
shipped in an SDK release rather than flowing through automatically, because that is where
behaviour changes have historically landed.
