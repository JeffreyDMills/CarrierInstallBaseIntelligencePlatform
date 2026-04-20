#!/usr/bin/env python3
"""Deploy carrier-ibi to Vercel via REST API. No Node required."""
import sys, os, json, base64, hashlib, urllib.request, urllib.error

TOKEN = os.environ.get("VERCEL_TOKEN") or (len(sys.argv) > 1 and sys.argv[1]) or ""
if not TOKEN:
    print("Usage: VERCEL_TOKEN=vcp_xxx python3 deploy.py    (or pass token as first arg)")
    sys.exit(1)

html_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")
with open(html_path, "rb") as f:
    html = f.read()

vercel_json = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vercel.json")
vj_bytes = open(vercel_json, "rb").read() if os.path.exists(vercel_json) else None

body = {
    "name": "carrier-ibi",
    "target": "production",
    "files": [
        {"file": "index.html", "data": base64.b64encode(html).decode(), "encoding": "base64"},
    ],
    "projectSettings": {"framework": None},
}
if vj_bytes:
    body["files"].append({"file": "vercel.json", "data": base64.b64encode(vj_bytes).decode(), "encoding": "base64"})

data = json.dumps(body).encode()
req = urllib.request.Request(
    "https://api.vercel.com/v13/deployments?forceNew=1",
    data=data,
    headers={
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
    },
    method="POST",
)
print("Uploading to Vercel...")
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        out = json.loads(resp.read().decode())
except urllib.error.HTTPError as e:
    print(f"HTTP {e.code}: {e.read().decode()}")
    sys.exit(1)

url = out.get("url") or out.get("alias", [None])[0]
print(f"\nDeployed: https://{url}")
if out.get("alias"):
    for a in out["alias"]:
        print(f"Alias:    https://{a}")
