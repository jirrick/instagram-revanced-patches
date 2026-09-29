# Maintaining the patches

Notes for keeping the Instagram patches working on new Instagram releases, plus the
findings of a full code review done on 2026-09-29 (base: Instagram 443.0.0.48.82).

## Review findings

Nothing in the patches or the Instagram extension sends data anywhere. The only network
request the Instagram code makes is the media download itself (plain GET to the Instagram
CDN URL, saved via MediaStore). The shared ReVanced library bundled into the app contains
YouTube/Reddit network code (GmsCore, stream spoofing, Redgifs, /s/ links), but no
Instagram patch calls into it; the only shared code that runs at startup is
`Utils.setContext`.

Fingerprints were read, not tested: matching against a real APK is still needed to prove
each patch applies.

| Patch | Default | Verdict | Notes |
|---|---|---|---|
| Hide ads | on | Works as described, fragile | Neuters every void method containing `Insert push down`, `Insert success` or `onInjectionOpportunity` (broad; could hit non-ad inserts). Also hardcodes the obfuscated `LX/02xg;->FKh` — only valid on this exact build; on another build it silently does nothing or, worse, forces `false` on an unrelated method with the same name. Story-ad part is skipped silently when not found. Unused fingerprints `Is ad pod` / `SponsoredContentController.insertItem` look like the intended replacement for the hardcoded name. |
| Download media | off | Works as described | Adds "Download" to post, carousel, reel and story menus. Reflection-based media lookup, so it survives renames well. Videos take the first `VideoVersion` (normally the best quality). Fixed here: one folder + per-account subfolders ("Download folder" option), and a saved/failed toast for single downloads. |
| Anonymous story viewing | off | Plausible | Kills the method containing `visual_media_seen`. Needs an on-device check that views really disappear from the viewer list and that DM visual messages are unaffected. |
| Disable analytics | on | Partial | Only redirects the `logging_client_events` endpoint(s) to `BOGUS`. Other telemetry still flows; README overstates it. Fingerprint doesn't check the method returns a String. |
| Remove build expired popup | on | Works as described | Anchored on the `lockout_active` preference; durable. |
| Sanitize sharing links | on | Works as described | Strips `igsh` from post/story/profile share URLs. |
| Change link sharing domain | off | Works as described | Also clears all query params. |
| Open links externally | off | Bug | Injected code always returns after the helper, even when the URL has no `u=` parameter, so such links do nothing. Also clobbers `v0`. |
| Remove screenshot restriction | on | Was broken, fixed | Pointed at a non-existent `extensions/instagram/instagram.rve`: the patch failed after its dependency had already rewritten every `Window.addFlags/setFlags` call, which crashes the app unless another selected patch happened to bundle the extension. Now depends on the shared Instagram extension. |
| Prevent screenshot detection | on | Works as described | Removes `register/unregisterScreenCaptureCallback` calls app-wide (Android 14+ API). |
| Hide navigation buttons | off | Works as described | Defaults hide Reels and Create. Would throw if Instagram's button list becomes immutable. |
| Hide explore feed | off | Works as described | Careful, well-commented implementation. |
| Hide suggested content | off | Works as described | Renames seven feed-item JSON keys so the parser skips them. |
| Hide highlights tray | off | Works as described | Breaks the highlights request by renaming its key. |
| Hide Stories from Home | off | Fragile | Pure opcode-pattern fingerprint; removes one `addView`. |
| Limit feed to followed profiles | off | Works as described | Swaps the `pagination_source` header to `following`. |
| Disable Reels scrolling | off | Mostly | `clipsSwipeDirectionControllerResetMethod` matches the first `(Z)V` method in the whole app that calls `setUserInputEnabled`, which may not be the Reels one. |
| Disable Reels auto-scroll | off | Works as described | |
| Disable story auto flipping | off | Works as described | |
| Disable swipe navigation | off | Works as described | |
| Enable location sticker redesign | off | Works as described | Keyed on a MobileConfig constant that changes between builds. |
| Enable developer menu | off | Works as described | |
| Disable signature check | off | Works as described | |

Housekeeping: `misc/privacy/SanitizeSharingLinksPatch.java` duplicates
`misc/share/privacy/SanitizeSharingLinksPatch.java` (the first is unused), and the repo
still carries upstream YouTube/Reddit resources and shared code that Instagram never uses.

## Local toolchain (Mac, containerized)

Everything runs in a Docker container: JDK 17, Android SDK, jadx, ReVanced CLI and
APKEditor. The container sees only this repo folder and one Docker volume
(`ig-revanced-cache`) for caches, so nothing is installed on macOS itself.

One-time setup:

1. Install a Docker runtime: [OrbStack](https://orbstack.dev) (free for personal use, uses
   Rosetta for amd64 automatically) or Colima (`brew install colima docker`, then
   `colima start --vm-type vz --vz-rosetta --memory 8`). Give it at least 8 GB RAM for jadx.
2. Clone the repo and run `./dev/ig tools`. The first run builds the image, the tools
   download into the cache volume.
3. On the phone, turn on Developer options → Wireless debugging, then
   `./dev/ig adb pair IP:PAIRPORT` (enter the pairing code) and `./dev/ig adb connect IP:PORT`.

Everyday commands (put APKs in `work/`, which is gitignored):

| Command | What it does |
|---|---|
| `./dev/ig build` | Builds `patches/build/libs/*.rvp` |
| `./dev/ig merge work/instagram.apkm` | APKMirror bundle → single APK |
| `./dev/ig decompile work/instagram-merged.apk` | jadx sources into `work/jadx/` |
| `./dev/ig patch work/instagram-merged.apk` | Hide ads + Download media + Anonymous story viewing (plus bundle defaults) → `work/instagram-patched.apk`. `ENABLE="A;B"` changes the set, `FORCE=1` skips the version check. |
| `./dev/ig list` | Every patch with its options and supported versions |
| `./dev/ig install` | Installs the last patched APK over Wireless debugging |
| `./dev/ig shell` | Shell inside the container |

`work/instagram.keystore` is created on the first patch. Keep it (back it up): Android only
installs an update over the existing app when it's signed with the same key. Switching from
MyInsta or a Manager-patched build needs one uninstall first, for the same reason.

The first `patch` run is the check that the CLI flags match the current ReVanced CLI
release; if not, `./dev/ig cli patch --help` shows the right ones.

## Porting to a new Instagram version

1. **Get the APK.** Download the newest *stable* `com.instagram.android` from APKMirror,
   arm64-v8a, nodpi. If it's an `.apkm`/bundle, merge it to a single APK first
   (e.g. APKEditor `m` command); ReVanced needs a single APK.
2. **Try the current patches as-is.** Run ReVanced CLI with `--force` (to ignore the version
   check) and every patch enabled. The log names each patch that failed and which
   fingerprint didn't resolve (`firstMethodDeclaratively` / `Match not found`).
3. **Fix each failing fingerprint.** Decompile with jadx, search for the anchor string the
   fingerprint uses, and see what moved: string pooled into a getter, method split,
   parameter order changed, switch compiled differently. Prefer anchors that are semantic
   and unobfuscated (JSON keys, log strings, preference names) over opcode patterns or
   obfuscated names.
4. **Watch for silent skips.** Patches using `...OrNull` fingerprints (Hide ads story part,
   Disable analytics Facebook URL, share-link parsers) "succeed" without doing anything.
   Check the patched app, not just the log.
5. **Bump versions.** Replace `443.0.0.48.82` in every `compatibleWith(...)` (the Pages
   manifest reads the version from there), then push to `main`. CI builds the `.rvp` and
   publishes it to GitHub Pages for ReVanced Manager.
6. **Test on the phone:** feed/reels/story ads, a post + carousel + reel + story download,
   and a story view from a second account to confirm ghost mode.
