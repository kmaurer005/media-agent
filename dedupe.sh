#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  dedupe.sh <inbox_dir> <archive_dir> [duplicates_dir] [--apply]

Notes:
  - Default mode is dry-run.
  - Use --apply to move duplicates from inbox to duplicates_dir.
  - duplicates_dir defaults to <inbox_dir>/_duplicates.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

INBOX_DIR="$1"
ARCHIVE_DIR="$2"
shift 2

DUP_DIR="${INBOX_DIR}/_duplicates"
APPLY="false"

for arg in "$@"; do
  case "$arg" in
    --apply)
      APPLY="true"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "$DUP_DIR" == "${INBOX_DIR}/_duplicates" ]]; then
        DUP_DIR="$arg"
      else
        echo "Unexpected argument: $arg"
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ ! -d "$INBOX_DIR" ]]; then
  echo "Inbox directory not found: $INBOX_DIR"
  exit 1
fi

if [[ ! -d "$ARCHIVE_DIR" ]]; then
  echo "Archive directory not found: $ARCHIVE_DIR"
  exit 1
fi

if command -v shasum >/dev/null 2>&1; then
  HASH_BIN=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
  HASH_BIN=(sha256sum)
else
  echo "No SHA-256 tool found (need shasum or sha256sum)."
  exit 1
fi

get_size() {
  local f="$1"
  if stat -f %z "$f" >/dev/null 2>&1; then
    stat -f %z "$f"
  else
    stat -c %s "$f"
  fi
}

hash_file() {
  local f="$1"
  "${HASH_BIN[@]}" "$f" | awk '{print $1}'
}

declare -A KEY_FIRST_PATH

declare -i checked=0
declare -i duplicates=0

dupe_manifest="$INBOX_DIR/duplicate-report.csv"
: > "$dupe_manifest"
echo "status,key,original,duplicate" >> "$dupe_manifest"

echo "Indexing archive (kept as canonical)..."
while IFS= read -r -d '' file; do
  size="$(get_size "$file")"
  hash="$(hash_file "$file")"
  key="$size:$hash"
  if [[ -z "${KEY_FIRST_PATH[$key]-}" ]]; then
    KEY_FIRST_PATH[$key]="$file"
  fi
done < <(find "$ARCHIVE_DIR" -type f -print0)

echo "Scanning inbox for duplicates..."
while IFS= read -r -d '' file; do
  if [[ "$file" == "$dupe_manifest" ]]; then
    continue
  fi
  if [[ "$file" == "$DUP_DIR"/* ]]; then
    continue
  fi

  checked+=1
  size="$(get_size "$file")"
  hash="$(hash_file "$file")"
  key="$size:$hash"

  if [[ -n "${KEY_FIRST_PATH[$key]-}" ]]; then
    original="${KEY_FIRST_PATH[$key]}"
    duplicates+=1
    echo "duplicate,\"$key\",\"$original\",\"$file\"" >> "$dupe_manifest"

    if [[ "$APPLY" == "true" ]]; then
      mkdir -p "$DUP_DIR"
      base="$(basename "$file")"
      target="$DUP_DIR/$base"
      if [[ -e "$target" ]]; then
        target="$DUP_DIR/${hash}_$base"
      fi
      mv "$file" "$target"
      echo "MOVED duplicate -> $target"
    else
      echo "DRY RUN duplicate -> $file (matches $original)"
    fi
  else
    KEY_FIRST_PATH[$key]="$file"
    echo "unique,\"$key\",\"$file\",\"\"" >> "$dupe_manifest"
  fi
done < <(find "$INBOX_DIR" -type f -print0)

echo ""
echo "Files checked in inbox: $checked"
echo "Duplicates found: $duplicates"
echo "Report: $dupe_manifest"

if [[ "$APPLY" == "true" ]]; then
  echo "Duplicate files were moved to: $DUP_DIR"
else
  echo "Dry run only. Re-run with --apply to move duplicates."
fi
