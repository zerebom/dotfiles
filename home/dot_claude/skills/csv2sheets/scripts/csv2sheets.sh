#!/bin/bash
set -euo pipefail

# csv2sheets: Upload multiple CSVs to a single Google Spreadsheet using gog CLI
# Usage: csv2sheets.sh [options] file1.csv:SheetName file2.csv:SheetName ...
#   Each argument is csv_path:sheet_name (sheet_name is optional, defaults to filename)
# Options:
#   -t, --title TITLE         Spreadsheet title (default: "CSV Upload YYYY-MM-DD")
#   -a, --account EMAIL       Google account email (default: gog default)
#   -i, --spreadsheet-id ID   Append to existing spreadsheet instead of creating new
#   -f, --folder-id ID        Drive folder ID for new spreadsheet
#   --no-open                 Don't open in browser after upload

TITLE=""
ACCOUNT=""
SPREADSHEET_ID=""
FOLDER_ID=""
OPEN_BROWSER=true
declare -a CSV_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--title) TITLE="$2"; shift 2 ;;
    -a|--account) ACCOUNT="$2"; shift 2 ;;
    -i|--spreadsheet-id) SPREADSHEET_ID="$2"; shift 2 ;;
    -f|--folder-id) FOLDER_ID="$2"; shift 2 ;;
    --no-open) OPEN_BROWSER=false; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) CSV_ARGS+=("$1"); shift ;;
  esac
done

if [[ ${#CSV_ARGS[@]} -eq 0 ]]; then
  echo "Error: No CSV files specified" >&2
  echo "Usage: csv2sheets.sh [options] file1.csv:SheetName file2.csv ..." >&2
  exit 1
fi

# Parse csv_path:sheet_name pairs
declare -a CSV_FILES=()
declare -a SHEET_NAMES=()
for arg in "${CSV_ARGS[@]}"; do
  if [[ "$arg" == *:* ]]; then
    CSV_FILES+=("${arg%%:*}")
    SHEET_NAMES+=("${arg#*:}")
  else
    CSV_FILES+=("$arg")
    # Default sheet name: filename without extension
    basename_no_ext=$(basename "$arg" .csv)
    SHEET_NAMES+=("$basename_no_ext")
  fi
done

# Validate CSV files exist
for csv_file in "${CSV_FILES[@]}"; do
  if [[ ! -f "$csv_file" ]]; then
    echo "Error: File not found: $csv_file" >&2
    exit 1
  fi
done

# Build gog account flag
ACCOUNT_FLAG=""
if [[ -n "$ACCOUNT" ]]; then
  ACCOUNT_FLAG="-a $ACCOUNT"
fi

# CSV to JSON 2D array converter (handles quoting, Japanese chars, etc.)
csv_to_json() {
  python3 -c "
import csv, json, sys
with open(sys.argv[1], encoding='utf-8-sig') as f:
    print(json.dumps(list(csv.reader(f)), ensure_ascii=False))
" "$1"
}

# Create or use existing spreadsheet
if [[ -z "$SPREADSHEET_ID" ]]; then
  # Default title with date
  if [[ -z "$TITLE" ]]; then
    TITLE="CSV Upload $(/bin/date +%Y-%m-%d)"
  fi

  # Build sheet names for --sheets flag
  SHEETS_CSV=$(IFS=,; echo "${SHEET_NAMES[*]}")

  echo "Creating spreadsheet: $TITLE"
  echo "Sheets: $SHEETS_CSV"

  # Create spreadsheet and extract ID
  CREATE_CMD="gog sheets create $ACCOUNT_FLAG --json"
  CREATE_CMD+=" --sheets=\"$SHEETS_CSV\""
  CREATE_CMD+=" \"$TITLE\""

  CREATE_OUTPUT=$(eval "$CREATE_CMD")
  SPREADSHEET_ID=$(echo "$CREATE_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['spreadsheetId'])")

  echo "Created spreadsheet ID: $SPREADSHEET_ID"
else
  EXISTING_SPREADSHEET=true
  echo "Using existing spreadsheet: $SPREADSHEET_ID"
fi

# Add sheets to existing spreadsheet via Sheets API batchUpdate
# Uses gog's stored refresh token to obtain an access token
add_sheets_to_existing() {
  local ssid="$1"
  shift
  local IFS_OLD="$IFS"
  IFS=$'\n'
  local names_joined="$*"
  IFS="$IFS_OLD"
  _ADD_SHEETS_SSID="$ssid" _ADD_SHEETS_NAMES="$names_joined" python3 << 'PYEOF'
import json, subprocess, sys, os, tempfile, urllib.request, urllib.parse

ssid = os.environ['_ADD_SHEETS_SSID']
new_names = os.environ['_ADD_SHEETS_NAMES'].split('\n')

# Get existing sheet names via gog
meta = json.loads(subprocess.check_output(['gog', 'sheets', 'metadata', ssid, '--json']))
existing = [s['properties']['title'] for s in meta.get('sheets', [])]

to_add = [n for n in new_names if n not in existing]
if not to_add:
    sys.exit(0)

# Export refresh token from gog
tmpf = tempfile.NamedTemporaryFile(suffix='.json', delete=False)
tmpf.close()
# Extract email from token key format "token:client:email"
tokens_out = json.loads(subprocess.check_output(['gog', 'auth', 'tokens', 'list', '--json']))
email = tokens_out['keys'][0].split(':')[-1]
subprocess.check_call(
    ['gog', 'auth', 'tokens', 'export', '--out', tmpf.name, '--overwrite', email],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)
with open(tmpf.name) as f:
    token_data = json.load(f)
os.unlink(tmpf.name)

# Read client credentials
config_dir = os.path.expanduser('~/Library/Application Support/gogcli')
with open(os.path.join(config_dir, 'credentials.json')) as f:
    creds = json.load(f)
# credentials.json may be {"installed": {...}} or {"web": {...}}
client_info = creds.get('installed') or creds.get('web') or creds
client_id = client_info['client_id']
client_secret = client_info['client_secret']

# Exchange refresh token for access token
data = urllib.parse.urlencode({
    'client_id': client_id,
    'client_secret': client_secret,
    'refresh_token': token_data['refresh_token'],
    'grant_type': 'refresh_token',
}).encode()
req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
resp = json.loads(urllib.request.urlopen(req).read())
access_token = resp['access_token']

# Add sheets via batchUpdate
requests_body = {
    'requests': [{'addSheet': {'properties': {'title': name}}} for name in to_add]
}
url = f'https://sheets.googleapis.com/v4/spreadsheets/{ssid}:batchUpdate'
req = urllib.request.Request(url,
    data=json.dumps(requests_body).encode(),
    headers={'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'})
urllib.request.urlopen(req)
for name in to_add:
    print(f'  Added sheet: {name}')
PYEOF
}

# If appending to existing spreadsheet, create missing sheets first
if [[ -n "${EXISTING_SPREADSHEET:-}" ]]; then
  echo "Ensuring sheets exist..."
  add_sheets_to_existing "$SPREADSHEET_ID" "${SHEET_NAMES[@]}"
fi

# Large CSV threshold (bytes) — files above this use chunked Python upload
LARGE_CSV_THRESHOLD=1000000  # 1MB

# Chunked upload via Google Sheets API (for large CSVs)
upload_large_csv() {
  local ssid="$1"
  local csv_path="$2"
  local sheet_name="$3"
  _UPLOAD_SSID="$ssid" _UPLOAD_CSV="$csv_path" _UPLOAD_SHEET="$sheet_name" python3 << 'PYEOF'
import csv, os, sys

csv_path = os.environ['_UPLOAD_CSV']
sheet_name = os.environ['_UPLOAD_SHEET']
ssid = os.environ['_UPLOAD_SSID']

# Try google-api-python-client first, fall back to urllib
try:
    from google.auth import default
    from googleapiclient.discovery import build
    creds, _ = default(scopes=['https://www.googleapis.com/auth/spreadsheets'])
    service = build('sheets', 'v4', credentials=creds)
    use_api_client = True
except ImportError:
    use_api_client = False

if not use_api_client:
    # Fallback: use gog token + urllib
    import json, subprocess, tempfile, urllib.request, urllib.parse

    tokens_out = json.loads(subprocess.check_output(['gog', 'auth', 'tokens', 'list', '--json']))
    email = tokens_out['keys'][0].split(':')[-1]
    tmpf = tempfile.NamedTemporaryFile(suffix='.json', delete=False)
    tmpf.close()
    subprocess.check_call(
        ['gog', 'auth', 'tokens', 'export', '--out', tmpf.name, '--overwrite', email],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    with open(tmpf.name) as f:
        token_data = json.load(f)
    os.unlink(tmpf.name)

    config_dir = os.path.expanduser('~/Library/Application Support/gogcli')
    with open(os.path.join(config_dir, 'credentials.json')) as f:
        creds_json = json.load(f)
    client_info = creds_json.get('installed') or creds_json.get('web') or creds_json
    data = urllib.parse.urlencode({
        'client_id': client_info['client_id'],
        'client_secret': client_info['client_secret'],
        'refresh_token': token_data['refresh_token'],
        'grant_type': 'refresh_token',
    }).encode()
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
    resp = json.loads(urllib.request.urlopen(req).read())
    access_token = resp['access_token']

with open(csv_path, 'r', encoding='utf-8-sig') as f:
    all_data = list(csv.reader(f))

total = len(all_data)
chunk_size = 1000

for start in range(0, total, chunk_size):
    chunk = all_data[start:start + chunk_size]
    body = {"values": chunk}

    if use_api_client:
        if start == 0:
            service.spreadsheets().values().update(
                spreadsheetId=ssid, range=f"'{sheet_name}'!A1",
                valueInputOption="RAW", body=body,
            ).execute()
        else:
            service.spreadsheets().values().append(
                spreadsheetId=ssid, range=f"'{sheet_name}'!A1",
                valueInputOption="RAW", insertDataOption="INSERT_ROWS", body=body,
            ).execute()
    else:
        if start == 0:
            url = f"https://sheets.googleapis.com/v4/spreadsheets/{ssid}/values/'{urllib.parse.quote(sheet_name)}'!A1?valueInputOption=RAW"
            req = urllib.request.Request(url, data=json.dumps(body).encode(), method='PUT',
                headers={'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'})
        else:
            url = f"https://sheets.googleapis.com/v4/spreadsheets/{ssid}/values/'{urllib.parse.quote(sheet_name)}'!A1:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS"
            req = urllib.request.Request(url, data=json.dumps(body).encode(), method='POST',
                headers={'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'})
        urllib.request.urlopen(req)

    done = min(start + chunk_size, total)
    print(f"  {done}/{total} rows", flush=True)

print(f"  Done: {total} rows uploaded")
PYEOF
}

# Upload each CSV to its sheet
for i in "${!CSV_FILES[@]}"; do
  csv_file="${CSV_FILES[$i]}"
  sheet_name="${SHEET_NAMES[$i]}"
  file_size=$(wc -c < "$csv_file" | tr -d ' ')

  echo "Uploading $csv_file → sheet '$sheet_name'..."

  if [[ "$file_size" -gt "$LARGE_CSV_THRESHOLD" ]]; then
    # Large file: use chunked Python upload
    upload_large_csv "$SPREADSHEET_ID" "$csv_file" "$sheet_name"
  else
    # Small file: use gog CLI (faster, simpler)
    json_data=$(csv_to_json "$csv_file")
    tmpfile=$(mktemp)
    echo "$json_data" > "$tmpfile"

    gog sheets update $ACCOUNT_FLAG "$SPREADSHEET_ID" "'${sheet_name}'!A1" \
      --values-json="$(cat "$tmpfile")" \
      --input=RAW

    rm -f "$tmpfile"

    row_count=$(echo "$json_data" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
    echo "  Done: $row_count rows uploaded"
  fi
done

# Output URL
SHEET_URL="https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/edit"
echo ""
echo "Spreadsheet URL: $SHEET_URL"

# Open in browser
if [[ "$OPEN_BROWSER" == true ]]; then
  if command -v open &>/dev/null; then
    open "$SHEET_URL"
    echo "Opened in browser."
  fi
fi
