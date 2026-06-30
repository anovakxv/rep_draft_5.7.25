# Mac / Xcode Setup — Rep iOS App

How to get the iOS app building on a **fresh Mac** after a `git clone` / `git pull`.

Most of the project comes down with git. The catch: a few files Xcode needs are
**gitignored** (on purpose — secrets, or just things that don't belong in a public repo),
so git can't carry them to a new machine. This doc is the short checklist for those.

> **Workflow reminder:** dev happens on the PC (VS Code) → `git push` from PC →
> `git pull` on the Mac for building, testing, and App Store submission.

---

## Quick checklist (fresh Mac)

1. **Install Xcode** (matching the team's current version) and open it once to accept the license.
2. **Clone / pull the repo.**
3. **Open the project:** `my-ios-app/Swift FrontEnd/Rep/Rep.xcodeproj`
   (open the `.xcodeproj` directly — there is no CocoaPods workspace).
4. **Add `GoogleService-Info.plist`** — the one required file git does NOT carry. See below.
5. **Let Swift Package Manager resolve** (Xcode does this automatically on first open;
   you'll see "Resolving Package Graph"). Dependencies: Kingfisher, firebase-ios-sdk,
   socket.io-client-swift, stripe-ios.
6. **Set your signing team:** target **Rep** → Signing & Capabilities → Team.
7. **Build** (⌘B). If something references a stale missing path, do
   **Product → Clean Build Folder** (⇧⌘K) first.

---

## The one manual file: `GoogleService-Info.plist`

This is the Firebase config (used for push notifications / FCM). It is **gitignored by
design** because the GitHub repo is public — so it must be added by hand on each machine.

**Where to put it:**
```
my-ios-app/Swift FrontEnd/Rep/GoogleService-Info.plist
```
(the folder that contains `Rep.xcodeproj`). The Xcode project already references it there,
so you do **not** need to drag it into Xcode or re-add it — just place the file on disk and
the existing (red/missing) reference resolves.

**Where to get it:** [Firebase Console](https://console.firebase.google.com/) →
⚙️ Project Settings → "Your apps" → the iOS app → download `GoogleService-Info.plist`.

**Confirm it's the correct app** (match these identifiers):

| Field | Value |
|-------|-------|
| PROJECT_ID | `rep-1-704a3` |
| BUNDLE_ID | `NetworkedCapital.Rep` |
| GOOGLE_APP_ID | `1:947037706720:ios:6cf6e14330063f38dcb385` |
| GCM_SENDER_ID | `947037706720` |
| STORAGE_BUCKET | `rep-1-704a3.firebasestorage.app` |

**Naming:** the file must be named exactly `GoogleService-Info.plist` — no `(1)` suffix, no
space. A browser-renamed `GoogleService-Info (1).plist` will fail at runtime
(`FirebaseApp.configure()` looks for the exact name).

---

## Troubleshooting (errors we've actually hit)

**`One of the paths in DEVELOPMENT_ASSET_PATHS does not exist: …/Rep/Preview Content`**
The SwiftUI preview folder is missing. It's now committed to git, so a normal `git pull`
fixes it. (Historically it was wrongly gitignored.) If ever missing again, the folder lives at
`my-ios-app/Swift FrontEnd/Rep/Rep/Preview Content/Preview Assets.xcassets/` and only needs a
standard empty `Contents.json`.

**`Build input file cannot be found: …/GoogleService-Info.plist`**
The Firebase file isn't placed. Add it per the section above, then Clean Build Folder (⇧⌘K).

**`Command Ld failed with a nonzero exit code`**
Usually a *cascade* from one of the missing-file errors above — fix those first. If it persists
on its own, it's typically code signing: set the Team under target → Signing & Capabilities.

---

## Notes

- **`Package.resolved` is committed** (not ignored) so the PC, the Mac, and App Store builds
  all resolve identical dependency versions. Xcode regenerates it on the Mac; if it changes
  after a package update, commit it.
- **What git carries fine** (no action): all `.swift` sources, `Info.plist`, `Rep.entitlements`,
  `Assets.xcassets`, app images, and the SPM package *declarations* (Xcode fetches the actual
  packages from GitHub on build).
- The only thing that ever needs manual placement on a fresh machine is
  **`GoogleService-Info.plist`**.
