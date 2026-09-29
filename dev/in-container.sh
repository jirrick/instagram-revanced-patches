#!/usr/bin/env bash
# Commands that run inside the dev container. Call through ./dev/ig on the host.
set -euo pipefail

REPO=/repo
WORK=$REPO/work                     # APKs, decompiled sources, patched output (gitignored)
TOOLS_DIR=${TOOLS_DIR:-/cache/tools}
KEYSTORE=$WORK/instagram.keystore   # keep this file: same key = updates install over the old app
mkdir -p "$WORK" "$TOOLS_DIR"

# Persistent Android SDK on the cache volume, seeded from the image.
if [ ! -d /cache/android-sdk ]; then cp -a /opt/android-sdk /cache/android-sdk; fi
export ANDROID_HOME=/cache/android-sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Patches applied by `patch` on top of the bundle's defaults. Override with ENABLE="A;B;C".
DEFAULT_ENABLE="Hide ads;Download media;Anonymous story viewing"

die() { echo "error: $*" >&2; exit 1; }

# Download the latest release asset of a GitHub repo whose name matches a regex.
fetch_latest() { # repo regex outfile
    local url
    url=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | jq -r '.assets[].browser_download_url' | grep -E "$2" | head -1)
    [ -n "$url" ] || die "no release asset matching $2 in $1"
    echo "  $(basename "$url")"
    curl -fsSL "$url" -o "$3"
}

tools() {
    echo "Downloading latest tools into $TOOLS_DIR"
    fetch_latest ReVanced/revanced-cli '-all\.jar$' "$TOOLS_DIR/revanced-cli.jar"
    fetch_latest REAndroid/APKEditor '\.jar$' "$TOOLS_DIR/APKEditor.jar"
    fetch_latest skylot/jadx '/jadx-[0-9.]+\.zip$' /tmp/jadx.zip
    rm -rf "$TOOLS_DIR/jadx" && unzip -q /tmp/jadx.zip -d "$TOOLS_DIR/jadx" && rm /tmp/jadx.zip
}

need_tools() { [ -f "$TOOLS_DIR/revanced-cli.jar" ] || tools; }

# Resolve a path given relative to the repo root on the host (e.g. work/ig.apk).
resolve() { local p=$1; [[ $p = /* ]] || p=$REPO/$p; [ -f "$p" ] || die "file not found: $1"; echo "$p"; }

latest_rvp() { ls -t "$REPO"/patches/build/libs/*.rvp 2>/dev/null | head -1; }

cmd=${1:-shell}; shift || true
case "$cmd" in
    shell)
        exec bash ;;

    tools)
        tools ;;

    build)
        cd "$REPO" && ./gradlew :patches:buildAndroid --no-daemon "$@"
        echo "Built: $(latest_rvp)" ;;

    merge) # Turn an .apkm/.xapk/.apks bundle into one installable APK.
        need_tools
        in=$(resolve "${1:?usage: merge <bundle>}")
        out="${in%.*}-merged.apk"
        java -jar "$TOOLS_DIR/APKEditor.jar" m -i "$in" -o "$out"
        echo "Merged: ${out#$REPO/}" ;;

    decompile) # Java sources for finding fingerprints; lands in work/jadx/<apk name>/
        need_tools
        in=$(resolve "${1:?usage: decompile <apk>}")
        out="$WORK/jadx/$(basename "${in%.*}")"
        JAVA_OPTS="-Xmx6g" "$TOOLS_DIR/jadx/bin/jadx" --no-res --show-bad-code -d "$out" "$in" || true
        echo "Decompiled into: ${out#$REPO/}" ;;

    patch) # patch <apk> [extra revanced-cli args]; FORCE=1 ignores the version check.
        need_tools
        in=$(resolve "${1:?usage: patch <apk> [cli args]}"); shift
        rvp=$(latest_rvp); [ -n "$rvp" ] || die "no .rvp built yet; run: ./dev/ig build"
        args=(patch --patches "$rvp" --out "$WORK/instagram-patched.apk" --keystore "$KEYSTORE")
        IFS=';' read -ra names <<< "${ENABLE:-$DEFAULT_ENABLE}"
        for n in "${names[@]}"; do args+=(--enable "$n"); done
        [ "${FORCE:-0}" = 1 ] && args+=(--force)
        java -jar "$TOOLS_DIR/revanced-cli.jar" "${args[@]}" "$@" "$in"
        echo "Patched: work/instagram-patched.apk" ;;

    list) # Show every patch in the built bundle with its options and versions.
        need_tools
        rvp=$(latest_rvp); [ -n "$rvp" ] || die "no .rvp built yet; run: ./dev/ig build"
        java -jar "$TOOLS_DIR/revanced-cli.jar" list-patches --with-packages --with-versions --with-options "$rvp" ;;

    cli) # Raw revanced-cli, e.g. `./dev/ig cli patch --help`
        need_tools
        java -jar "$TOOLS_DIR/revanced-cli.jar" "$@" ;;

    adb) # Phone over Wireless debugging, e.g. `./dev/ig adb pair 192.168.1.20:37000`
        exec adb "$@" ;;

    install) # install [apk] — defaults to the last patched APK
        in=$(resolve "${1:-work/instagram-patched.apk}")
        adb install -r "$in" ;;

    *)
        die "unknown command '$cmd' (shell, tools, build, merge, decompile, patch, list, cli, adb, install)" ;;
esac
