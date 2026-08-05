#!/bin/sh
set -e

echo "[Tronbyt App] Starting up..."

# ---------------------------------------------------------------
# Read Home Assistant app options from /data/options.json
# ---------------------------------------------------------------
OPTIONS_FILE="/data/options.json"

# Defaults
PRODUCTION=true
ENABLE_USER_REGISTRATION=false
SINGLE_USER_AUTO_LOGIN=false
GITHUB_TOKEN=""
SYSTEM_APPS_REPO=""
CUSTOM_SERVER_REPO=""
CUSTOM_SERVER_REF=""

if [ -f "$OPTIONS_FILE" ]; then
  echo "[Tronbyt App] Reading configuration from options.json"

  PRODUCTION=$(jq -r '.production // true' "$OPTIONS_FILE")
  ENABLE_USER_REGISTRATION=$(jq -r '.enable_user_registration // false' "$OPTIONS_FILE")
  SINGLE_USER_AUTO_LOGIN=$(jq -r '.single_user_auto_login // false' "$OPTIONS_FILE")
  GITHUB_TOKEN=$(jq -r '.github_token // ""' "$OPTIONS_FILE")
  SYSTEM_APPS_REPO=$(jq -r '.system_apps_repo // ""' "$OPTIONS_FILE")
  CUSTOM_SERVER_REPO=$(jq -r '.custom_server_repo // ""' "$OPTIONS_FILE")
  CUSTOM_SERVER_REF=$(jq -r '.custom_server_ref // ""' "$OPTIONS_FILE")
fi

# ---------------------------------------------------------------
# Map boolean values to what the tronbyt server expects (1 / 0)
# ---------------------------------------------------------------
bool_to_int() {
  case "$1" in
    true|True|TRUE|1) echo "1" ;;
    *) echo "0" ;;
  esac
}

export PRODUCTION=$(bool_to_int "$PRODUCTION")
export ENABLE_USER_REGISTRATION=$(bool_to_int "$ENABLE_USER_REGISTRATION")
export SINGLE_USER_AUTO_LOGIN=$(bool_to_int "$SINGLE_USER_AUTO_LOGIN")

if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "null" ]; then
  export GITHUB_TOKEN
fi

if [ -n "$SYSTEM_APPS_REPO" ] && [ "$SYSTEM_APPS_REPO" != "null" ]; then
  export SYSTEM_APPS_REPO
fi

# Hide credentials if a URL includes userinfo.
redact_url_credentials() {
  echo "$1" | sed -E 's#(https?://)[^/@]+@#\1***@#'
}

# ---------------------------------------------------------------
# Optional: build a custom tronbyt-server fork from source.
#
# When `custom_server_repo` is set, resolve the requested ref to a
# commit and look for a cached binary in /data/tronbyt-build/cache.
# On a cache miss, install build deps, clone, and `go build` with the
# same flags as the upstream Dockerfile. The compiled binary then
# replaces /app/tronbyt-server.
# ---------------------------------------------------------------
resolve_remote_commit() {
  repo="$1"
  ref="$2"

  # If ref looks like a commit SHA, use it directly.
  if printf '%s' "$ref" | grep -Eq '^[0-9a-f]{7,40}$'; then
    echo "$ref"
    return 0
  fi

  if [ -z "$ref" ]; then
    git ls-remote --exit-code "$repo" HEAD 2>/dev/null | head -n1 | awk '{print $1}'
    return $?
  fi

  # Try the ref as given, then as a branch, then as a tag.
  out=$(git ls-remote --exit-code "$repo" "$ref" 2>/dev/null | head -n1 | awk '{print $1}') || out=""
  if [ -z "$out" ]; then
    out=$(git ls-remote --exit-code "$repo" "refs/heads/$ref" 2>/dev/null | head -n1 | awk '{print $1}') || out=""
  fi
  if [ -z "$out" ]; then
    out=$(git ls-remote --exit-code "$repo" "refs/tags/$ref" 2>/dev/null | head -n1 | awk '{print $1}') || out=""
  fi
  echo "$out"
}

build_custom_server() {
  repo="$1"
  ref="$2"
  build_root="/data/tronbyt-build"
  cache_root="$build_root/cache"
  src_dir="$build_root/src"

  mkdir -p "$cache_root"

  target_commit=$(resolve_remote_commit "$repo" "$ref")
  if [ -z "$target_commit" ]; then
    echo "[Tronbyt App] ERROR: could not resolve ref '${ref:-HEAD}' in $(redact_url_credentials "$repo")" >&2
    return 1
  fi
  echo "[Tronbyt App] Custom fork target commit: $target_commit"

  cached_binary="$cache_root/$target_commit/tronbyt-server"

  if [ -x "$cached_binary" ]; then
    echo "[Tronbyt App] Using cached build for $target_commit"
  else
    echo "[Tronbyt App] No cached build for $target_commit; building from source..."
    echo "[Tronbyt App] (This may take several minutes on first run.)"

    # Build deps mirror the upstream Dockerfile (CGo + libwebp).
    apk add --no-cache build-base clang go libwebp-dev libwebp-static >/dev/null

    if [ -d "$src_dir/.git" ]; then
      git -C "$src_dir" remote set-url origin "$repo"
    else
      rm -rf "$src_dir"
      mkdir -p "$src_dir"
      git -C "$src_dir" init -q
      git -C "$src_dir" remote add origin "$repo"
    fi

    # Try a shallow fetch of the exact commit first; fall back to ref name,
    # then a full fetch if the remote doesn't allow fetching by SHA.
    if ! git -C "$src_dir" fetch --depth=1 origin "$target_commit" 2>/dev/null; then
      if [ -n "$ref" ] && git -C "$src_dir" fetch --depth=1 origin "$ref" 2>/dev/null; then
        :
      else
        git -C "$src_dir" fetch origin
      fi
    fi

    git -C "$src_dir" checkout -q "$target_commit"

    mkdir -p "$cache_root/$target_commit"
    (
      cd "$src_dir"
      # GOTOOLCHAIN=auto lets the system Go bootstrap the version pinned in go.mod.
      export GOTOOLCHAIN=auto
      export CGO_ENABLED=1
      go build \
        -ldflags="-w -s -extldflags '-static'" \
        -tags gzip_fonts \
        -o "$cached_binary" \
        ./cmd/server
    )

    chmod +x "$cached_binary"
    echo "[Tronbyt App] Build complete: $cached_binary"
  fi

  cp "$cached_binary" /app/tronbyt-server
  chmod +x /app/tronbyt-server

  # Keep only the three newest cached builds so /data doesn't grow unbounded.
  ls -1t "$cache_root" 2>/dev/null | tail -n +4 | while read -r old; do
    [ -n "$old" ] && rm -rf "$cache_root/$old"
  done
}

if [ -n "$CUSTOM_SERVER_REPO" ] && [ "$CUSTOM_SERVER_REPO" != "null" ]; then
  echo "[Tronbyt App] Custom server fork enabled: $(redact_url_credentials "$CUSTOM_SERVER_REPO") (ref: ${CUSTOM_SERVER_REF:-HEAD})"
  build_custom_server "$CUSTOM_SERVER_REPO" "$CUSTOM_SERVER_REF"
fi

# ---------------------------------------------------------------
# Set up persistent data storage
# ---------------------------------------------------------------
# HA apps persist /data across restarts.
# Tronbyt server stores its data in /app/data.
# Therefore, ensure /app/data points to a persistent location.
PERSISTENT_DIR="/data/tronbyt"
mkdir -p "$PERSISTENT_DIR"

# If /app/data exists and is not a symlink, migrate its contents
if [ -d "/app/data" ] && [ ! -L "/app/data" ]; then
  echo "[Tronbyt App] Migrating existing data to persistent storage..."
  cp -a /app/data/. "$PERSISTENT_DIR/"
  rm -rf /app/data
fi

# Create symlink so tronbyt writes to persistent storage
ln -sfn "$PERSISTENT_DIR" /app/data

echo "[Tronbyt App] Configuration:"
echo "  PRODUCTION=$PRODUCTION"
echo "  ENABLE_USER_REGISTRATION=$ENABLE_USER_REGISTRATION"
echo "  SINGLE_USER_AUTO_LOGIN=$SINGLE_USER_AUTO_LOGIN"
if [ -n "$SYSTEM_APPS_REPO" ] && [ "$SYSTEM_APPS_REPO" != "null" ]; then
  echo "  SYSTEM_APPS_REPO=$(redact_url_credentials "$SYSTEM_APPS_REPO")"
else
  echo "  SYSTEM_APPS_REPO=<default>"
fi
if [ -n "$CUSTOM_SERVER_REPO" ] && [ "$CUSTOM_SERVER_REPO" != "null" ]; then
  echo "  CUSTOM_SERVER_REPO=$(redact_url_credentials "$CUSTOM_SERVER_REPO")"
  echo "  CUSTOM_SERVER_REF=${CUSTOM_SERVER_REF:-HEAD}"
else
  echo "  CUSTOM_SERVER_REPO=<bundled>"
fi
echo "  Data directory: $PERSISTENT_DIR"
echo ""

# ---------------------------------------------------------------
# Start the Tronbyt server
# ---------------------------------------------------------------
echo "[Tronbyt App] Starting Tronbyt Server on port 8000..."
cd /app
exec /app/tronbyt-server
