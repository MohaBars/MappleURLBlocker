# MappleURLBlocker

A small Objective-C runtime-hook dylib intended to be injected into Mapple
through LiveContainer's per-app tweak configuration.

## What it does

Hooks these `UIApplication` instance methods:

- `openURL:`
- `openURL:options:completionHandler:`

It rejects `http` and `https` URLs and logs the blocked URL with the
`[MappleURLBlocker]` prefix. Other schemes (for example `mailto:` and `tel:`)
are passed through.

The dylib does not modify Mapple's IPA or its WebView navigation policy.

## Build without Theos

The GitHub Actions workflow builds the arm64 iOS dylib using the Xcode toolchain
already installed on a GitHub-hosted macOS runner.

1. Create a new **private** or public GitHub repository.
2. Upload the contents of this folder to the repository root.
3. Open **Actions** and run **Build MappleURLBlocker** (or push to `main`).
4. Open the completed workflow run.
5. Download the `MappleURLBlocker-ios-arm64` artifact.
6. Extract `MappleURLBlocker.dylib`.

No local Xcode or Theos installation is required.

## Install / test

1. Keep a backup of the original Mapple IPA.
2. In LiveContainer, configure a dedicated tweak folder for Mapple.
3. Import `MappleURLBlocker.dylib` into that folder.
4. Assign that folder to Mapple only, then fully terminate and relaunch Mapple.
5. Test a normal in-app page and then reproduce the ad redirect.

If LiveContainer refuses the dylib because of signing or architecture, click the sign button in LiveContainer.

## Important limitations

- This first version only hooks `UIApplication` URL-opening methods.
- It may not catch redirects opened by a separate WebKit/Safari mechanism,
  `SFSafariViewController`, or a private LaunchServices API.
- It blocks **all external HTTP/HTTPS launches from the injected process**, not
  just ad URLs. Normal navigation inside a `WKWebView` should remain available,
  but links that intentionally leave the app will be blocked too.
- It is injected only into Mapple, so it should not affect other apps.
- This is a first-pass diagnostic build, not a guarantee that Mapple's
  particular redirect path uses these APIs.
