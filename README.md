# media-agent

Lightweight media ingest and archive organization toolkit using ExifTool and shell scripts.

## Scripts

- `preview.sh` - show a non-recursive preview of date-based destination folders.
- `organize.sh` - move files in the current directory into `%Y-%m-%d` folders using `CreateDate`.
- `preview_recursive.sh` - recursively preview moves into a `%Y/%Y-%m-%d` structure.
- `organize_recursive.sh` - recursively move files into a `%Y/%Y-%m-%d` structure.
- `inspect.sh` - inspect `CreateDate` and filename metadata.
- `cleanup_empty.sh` - remove empty directories under the current path.
- `dedupe.sh` - detect exact byte-level duplicates using size and SHA-256, comparing inbox against archive and within inbox.

## Duplicate Workflow

Run a dry run first:

```bash
./dedupe.sh /path/to/Inbox /path/to/Archive
```

Apply mode moves duplicates from the inbox into an inbox quarantine folder:

```bash
./dedupe.sh /path/to/Inbox /path/to/Archive /path/to/Inbox/_duplicates --apply
```

Behavior:

- Archive files are treated as canonical originals.
- Inbox files matching archive hashes are marked as duplicates.
- Duplicates inside the inbox are also detected.
- `duplicate-report.csv` is written to the inbox for audit and review.

## External Drive Example

Dry run:

```bash
./dedupe.sh "/Volumes/WD MyPassport for Mac/Inbox" "/Volumes/WD MyPassport for Mac/Archive"
```

Apply mode:

```bash
./dedupe.sh "/Volumes/WD MyPassport for Mac/Inbox" "/Volumes/WD MyPassport for Mac/Archive" "/Volumes/WD MyPassport for Mac/_duplicates" --apply
```
