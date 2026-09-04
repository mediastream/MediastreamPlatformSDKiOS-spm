// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MediastreamPlatformSDKiOS",
  platforms: [.iOS(.v13)],
  products: [
    // The product carries the binary AND the wrapper, so consumers get the module plus
    // IMA / Youbora / ComScore / EaseLive / AdSupport in one dependency.
    .library(
      name: "MediastreamPlatformSDKiOS",
      targets: ["MediastreamPlatformSDKiOS", "MediastreamSDKDependencies"]
    )
  ],
  dependencies: [
    // Range, not exact: `exact` on a library's dependency is imposed on the consumer's
    // whole graph, so an app that also uses IMA directly at another version would fail to
    // resolve with no way out. The upper bound is a platform boundary, not a semver
    // guess: 3.24–3.27 declare .iOS(.v11), and from 3.28 the package declares .iOS(.v15),
    // which would break this package's iOS 13 floor.
    .package(
      url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
      "3.24.0"..<"3.28.0"
    ),
    // YouboraLib only — NOT avplayer-adapter-ios. That adapter is distributed as source,
    // so SwiftPM builds it statically; it is already compiled into the XCFramework and
    // declaring it here would duplicate its symbols in the consumer. YouboraLib ships as
    // a binaryTarget, so it stays a dynamic framework that the binary loads at runtime.
    // upToNextMinor from the version the XCFramework was built against: patches carry
    // NPAW's crash fixes and should flow through, while a minor bump has to be validated
    // and shipped in an SDK release — that is where NPAW's behaviour changes have landed
    // historically (bufferUnderrun replacing seek, the new deviceUUID, brand going empty).
    // See docs/spm-migration/LINKAGE.md in the SDK repo.
    .package(
      url: "https://bitbucket.org/npaw/lib-plugin-spm-ios.git",
      .upToNextMinor(from: "6.7.23")
    ),
    .package(
      url: "https://github.com/comScore/Comscore-Swift-Package-Manager.git",
      .upToNextMinor(from: "6.17.0")
    ),
    // PlayAnywhere. Ships as a binaryTarget, so it stays a dynamic framework the SDK loads
    // at runtime and declaring it here is what makes a consumer embed it — the XCFramework
    // records @rpath/EaseLiveSDK.framework/EaseLiveSDK and nothing else would satisfy it.
    // Its manifest is swift-tools-version:6.0, so resolving this graph needs Xcode 16+.
    .package(
      url: "https://github.com/ease-live/ease-live-bridge-ios-spm.git",
      .upToNextMinor(from: "2.29.0")
    )
  ],
  targets: [
    // The name must match MediastreamPlatformSDKiOS.xcframework inside the archive.
    // Both fields are rewritten by the release pipeline on every publish; editing them by
    // hand is how a checksum mismatch reaches a consumer.
    .binaryTarget(
      name: "MediastreamPlatformSDKiOS",
      url: "https://s3.amazonaws.com/mediastream-platform-sdk-ios/sdk/dev/6.1.0-dev.17/MediastreamPlatformSDKiOSxC.zip",
      checksum: "6da2a62b04bcaddbc7902b8f49f7ffcdcb6e2717e44fd5e7c442aa1147538aae"
    ),
    .target(
      name: "MediastreamSDKDependencies",
      dependencies: [
        "MediastreamPlatformSDKiOS",
        .product(
          name: "GoogleInteractiveMediaAds",
          package: "swift-package-manager-google-interactive-media-ads-ios"
        ),
        .product(name: "YouboraLib", package: "lib-plugin-spm-ios"),
        .product(name: "ComScore", package: "Comscore-Swift-Package-Manager"),
        .product(name: "EaseLiveSDK", package: "ease-live-bridge-ios-spm")
      ],
      path: "Sources/MediastreamSDKDependencies",
      // Mirrors s.frameworks = 'AdSupport' from the podspec. Belt and braces: the
      // prebuilt framework already links AdSupport itself (verified with otool -L), so
      // this is not what makes it resolve — it keeps the declaration explicit in case a
      // future build of the XCFramework stops carrying it.
      linkerSettings: [.linkedFramework("AdSupport")]
    )
  ]
)
